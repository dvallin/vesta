import Combine
import Foundation
import SwiftData
import os

enum SyncError: Error {
    case apiError(Error)
    case networkError(Error)
    case unknown
    case notAuthenticated
}

/// Service responsible for synchronizing entities marked as dirty to the backend
class SyncService: ObservableObject {
    private var modelContext: ModelContext
    private var users: UserService
    private var auth: UserAuthService
    private var meals: MealService
    private var todoItems: TodoItemService
    private var todoItemCategories: TodoItemCategoryService
    private var recipes: RecipeService
    private var shoppingItems: ShoppingListItemService

    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?
    private var isSyncing = false
    private var realTimeSubscription: AnyCancellable?

    @Published private(set) var lastSyncTime: Date?
    @Published private(set) var isSyncEnabled: Bool = false

    private let logger = Logger(subsystem: "com.app.Vesta", category: "Synchronization")
    private let pushInterval: TimeInterval = 60  // seconds - push local changes every minute
    private let initialPullDelay: TimeInterval = 2  // seconds - delay before initial pull

    // API client is now typed with the SyncAPIClient protocol
    private let apiClient: SyncAPIClient

    public init(
        apiClient: SyncAPIClient = FirebaseAPIClient(),
        auth: UserAuthService, users: UserService,
        todoItemCategories: TodoItemCategoryService, meals: MealService, todoItems: TodoItemService,
        recipes: RecipeService, shoppingItems: ShoppingListItemService,
        modelContext: ModelContext
    ) {
        self.apiClient = apiClient
        self.modelContext = modelContext
        self.auth = auth
        self.users = users
        self.todoItemCategories = todoItemCategories
        self.meals = meals
        self.todoItems = todoItems
        self.recipes = recipes
        self.shoppingItems = shoppingItems
    }

    /// Start sync operations: initial pull + subscribe to changes + periodic push
    func startSync() {
        stopSync()

        guard let currentUser = auth.currentUser, currentUser.uid != nil else {
            logger.error("Cannot start sync: User not authenticated")
            return
        }

        logger.info("Starting sync service")
        isSyncEnabled = true

        // Perform initial pull after a short delay to allow the app to finish loading
        DispatchQueue.main.asyncAfter(deadline: .now() + initialPullDelay) { [weak self] in
            guard let self = self else { return }

            // Step 1: Perform initial pull from Firebase
            self.logger.info("Performing initial pull from Firebase")
            self.pullChangesFromFirebase().sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        self.logger.error("Initial pull failed: \(error)")
                    }

                    // Step 2: Set up real-time subscription (even if initial pull failed)
                    self.setupRealTimeSubscription()
                },
                receiveValue: { _ in
                    self.logger.info("Initial pull completed successfully")
                    self.lastSyncTime = Date()
                }
            )
            .store(in: &self.cancellables)

            // Step 3: Schedule periodic push for local changes
            self.schedulePeriodicalPush()
        }
    }

    /// Set up real-time subscription to Firebase updates
    private func setupRealTimeSubscription() {
        guard let currentUser = auth.currentUser, let userId = currentUser.uid else {
            logger.error("Cannot subscribe to updates: User not authenticated")
            return
        }

        logger.info("Setting up real-time subscription for user: \(userId)")

        realTimeSubscription = apiClient.subscribeToEntityUpdates(for: userId) {
            [weak self] entityData in
            guard let self = self else { return }

            self.logger.info(
                "Received real-time update with \(entityData.values.map { $0.count }.reduce(0, +)) entities"
            )

            // Process the received entities
            self.processReceivedEntities(entityData, currentUser: currentUser)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            self.logger.error("Error processing real-time update: \(error)")
                        }
                    },
                    receiveValue: { _ in
                        self.logger.debug("Real-time update processed successfully")
                        self.lastSyncTime = Date()
                    }
                )
                .store(in: &self.cancellables)
        }
    }

    /// Schedule periodic push of local changes
    private func schedulePeriodicalPush() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: pushInterval, repeats: true) {
            [weak self] _ in
            guard let self = self else { return }
            self.logger.info("Performing scheduled push of local changes")

            // Only push local changes if we're not already syncing
            guard !self.isSyncing else {
                self.logger.info("Skipping scheduled push because sync is already in progress")
                return
            }

            // Push local changes to the server
            self.pushLocalChanges()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            self.logger.error("Scheduled push failed: \(error)")
                        }
                    },
                    receiveValue: { _ in
                        self.logger.info("Scheduled push completed successfully")
                    }
                )
                .store(in: &self.cancellables)
        }
    }

    /// Stop all sync operations
    func stopSync() {
        logger.info("Stopping sync service")

        // Cancel scheduled timer
        syncTimer?.invalidate()
        syncTimer = nil

        // Cancel real-time subscription
        realTimeSubscription?.cancel()
        realTimeSubscription = nil

        isSyncEnabled = false
    }

    /// Manually sync a specific entity immediately
    /// - Parameters:
    ///   - entity: The entity to sync
    ///   - currentUser: The current user making the change
    /// - Returns: A publisher that completes when the sync is finished
    func syncEntityImmediately<T: PersistentModel & SyncableEntity>(_ entity: T)
        -> AnyPublisher<Void, SyncError>
    {
        // Mark as dirty first
        entity.markAsDirty()

        do {
            try modelContext.save()
        } catch {
            logger.error(
                "Failed to save entity before immediate sync: \(error.localizedDescription)")
            return Fail(error: SyncError.unknown).eraseToAnyPublisher()
        }

        // Create a batch with just this entity
        return syncBatch([entity]).eraseToAnyPublisher()
    }

    // MARK: - Private methods

    /// Force a manual sync - pushes local changes to Firebase and then pulls any changes
    func performManualSync() -> AnyPublisher<Void, SyncError> {
        guard !isSyncing else {
            return Just(())
                .setFailureType(to: SyncError.self)
                .eraseToAnyPublisher()
        }

        guard let currentUser = auth.currentUser, currentUser.uid != nil else {
            return Fail(error: SyncError.notAuthenticated).eraseToAnyPublisher()
        }

        logger.info("Starting manual sync")
        isSyncing = true

        return pushLocalChanges()
            .flatMap { [weak self] _ -> AnyPublisher<Void, SyncError> in
                guard let self = self else {
                    return Fail(error: SyncError.unknown).eraseToAnyPublisher()
                }
                return self.pullChangesFromFirebase()
            }
            .handleEvents(receiveCompletion: { [weak self] completion in
                self?.isSyncing = false

                if case .finished = completion {
                    self?.logger.info("Manual sync completed successfully")
                    self?.lastSyncTime = Date()
                } else if case .failure(let error) = completion {
                    self?.logger.error("Manual sync failed: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }

    /// Push local changes to the server
    private func pushLocalChanges() -> AnyPublisher<Void, SyncError> {
        logger.info("Pushing local changes to Firebase")

        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }

            let pushOperations = [
                self.syncEntities(of: User.self),
                self.syncEntities(of: TodoItem.self),
                self.syncEntities(of: Recipe.self),
                self.syncEntities(of: Meal.self),
                self.syncEntities(of: ShoppingListItem.self),
            ]

            // Execute each operation in sequence
            let publisher = pushOperations.publisher
                .flatMap(maxPublishers: .max(1)) { $0 }
                .collect()
                .map { _ in () }  // Convert successful result to Void
                .mapError { $0 }
                .eraseToAnyPublisher()

            publisher.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        self.logger.info("Successfully pushed local changes")
                        promise(.success(()))
                    case .failure(let error):
                        self.logger.error("Error pushing local changes: \(error)")
                        promise(.failure(error))
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }

    private func syncEntities<T: PersistentModel & SyncableEntity>(of type: T.Type) -> Future<
        Void, SyncError
    > {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }

            // Fetch dirty entities of this type
            let descriptor = FetchDescriptor<T>(predicate: #Predicate<T> { $0.dirty == true })

            do {
                let dirtyEntities = try modelContext.fetch(descriptor)

                guard !dirtyEntities.isEmpty else {
                    // No dirty entities to sync
                    promise(.success(()))
                    return
                }

                print("Found \(dirtyEntities.count) dirty \(String(describing: T.self))s to sync")

                // Process entities in batches for better performance
                let batches = stride(from: 0, to: dirtyEntities.count, by: 25).map {
                    Array(dirtyEntities[$0..<min($0 + 25, dirtyEntities.count)])
                }

                // Create a publisher chain to process batches sequentially
                var batchPublisher = Just(()).setFailureType(to: SyncError.self)
                    .eraseToAnyPublisher()

                for batch in batches {
                    batchPublisher = batchPublisher.flatMap {
                        [weak self] _ -> AnyPublisher<Void, SyncError> in
                        guard let self = self else {
                            return Fail(error: SyncError.unknown).eraseToAnyPublisher()
                        }
                        return self.syncBatch(batch)
                    }.eraseToAnyPublisher()
                }

                batchPublisher
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                promise(.success(()))
                            case .failure(let error):
                                promise(.failure(error))
                            }
                        }, receiveValue: { _ in }
                    )
                    .store(in: &self.cancellables)

            } catch {
                print("Error fetching dirty \(String(describing: T.self))s: \(error)")
                promise(.failure(.unknown))
            }
        }
    }

    private func syncBatch<T: PersistentModel & SyncableEntity>(
        _ entities: [T]
    ) -> AnyPublisher<Void, SyncError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }

            // Convert entities to DTOs for API
            let dtos = entities.map { $0.toDTO() }

            // Call appropriate API endpoint based on entity type
            let entityName = String(describing: T.self).lowercased()

            self.apiClient.syncEntities(dtos: dtos)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            // Dispatch to main actor to update entities
                            Task { @MainActor in
                                // Mark entities as synced
                                entities.forEach { entity in
                                    entity.markAsSynced()
                                }

                                // Save context
                                do {
                                    try self.modelContext.save()
                                    promise(.success(()))
                                } catch {
                                    print("Error saving context after sync: \(error)")
                                    promise(.failure(.unknown))
                                }
                            }

                        case .failure(let error):
                            print("Error syncing \(entityName): \(error)")
                            promise(.failure(.apiError(error)))
                        }
                    }, receiveValue: { _ in }
                )
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }

    /// Pull down changes from Firebase and update the local database
    func pullChangesFromFirebase() -> AnyPublisher<Void, SyncError> {
        logger.info("Pulling changes from Firebase")

        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }

            // Check if user is authenticated
            guard let currentUser = self.auth.currentUser,
                let userId = currentUser.uid
            else {
                self.logger.error("Cannot pull changes: User not authenticated")
                promise(.failure(.notAuthenticated))
                return
            }

            self.apiClient.fetchUpdatedEntities(userId: userId)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            // Completion is handled in the receiveValue handler
                            break
                        case .failure(let error):
                            self.logger.error(
                                "Error pulling changes: \(error.localizedDescription)")
                            promise(.failure(.apiError(error)))
                        }
                    },
                    receiveValue: { [weak self] entityData in
                        guard let self = self else {
                            promise(.failure(.unknown))
                            return
                        }

                        let entityCount = entityData.values.map { $0.count }.reduce(0, +)
                        if entityCount > 0 {
                            self.logger.info(
                                "Received \(entityCount) updated entities from Firebase")
                        } else {
                            self.logger.info("No new updates from Firebase")
                            promise(.success(()))
                            return
                        }

                        self.processReceivedEntities(entityData, currentUser: currentUser)
                            .sink(
                                receiveCompletion: { completion in
                                    switch completion {
                                    case .finished:
                                        self.logger.info("Successfully processed pulled entities")
                                        promise(.success(()))
                                    case .failure(let error):
                                        self.logger.error(
                                            "Error processing pulled entities: \(error)")
                                        promise(.failure(error))
                                    }
                                },
                                receiveValue: { _ in }
                            )
                            .store(in: &self.cancellables)
                    }
                )
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }

    private func processReceivedEntities(_ entityData: [String: [[String: Any]]], currentUser: User)
        -> Future<Void, SyncError>
    {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }

            // Create a task context for processing entities
            Task {
                do {
                    // Process each entity type on the MainActor
                    await MainActor.run {
                        Task {
                            do {
                                // Process each entity type
                                for (entityType, entities) in entityData {
                                    switch entityType {
                                    case "User":
                                        try await self.processUserEntities(
                                            entities, currentUser: currentUser)
                                    case "TodoItem":
                                        try await self.processTodoItemEntities(
                                            entities, currentUser: currentUser)
                                    case "Recipe":
                                        try await self.processRecipeEntities(
                                            entities, currentUser: currentUser)
                                    case "Meal":
                                        try await self.processMealEntities(
                                            entities, currentUser: currentUser)
                                    case "ShoppingListItem":
                                        try await self.processShoppingListItemEntities(
                                            entities, currentUser: currentUser)
                                    default:
                                        print("Unknown entity type: \(entityType)")
                                    }
                                }

                                // Save all changes
                                try self.modelContext.save()

                                // Complete successfully
                                promise(.success(()))
                            } catch {
                                print("Error processing entities: \(error)")
                                promise(.failure(.unknown))
                            }
                        }
                    }
                } catch {
                    print("Error in MainActor scheduling: \(error)")
                    await MainActor.run {
                        promise(.failure(.unknown))
                    }
                }
            }
        }
    }

    @MainActor
    private func processUserEntities(_ entities: [[String: Any]], currentUser: User) async throws {
        for data in entities {
            guard let uid = data["uid"] as? String else { continue }

            // Check if entity exists or create a new one
            let user: User
            if let existingUser = try users.fetchUnique(withUID: uid) {
                user = existingUser
            } else {
                guard let name = data["name"] as? String else { continue }
                user = User(uid: uid)
                modelContext.insert(user)
            }

            // Update properties and members
            user.update(from: data)

            if let ownerId = data["ownerId"] as? String {
                if ownerId != user.owner?.uid {
                    if ownerId == uid {
                        user.owner = user
                    } else if let owner = try? users.fetchUnique(withUID: ownerId) {
                        user.owner = owner
                    }
                }
            } else if user.owner != nil {
                user.owner = nil
            }

            user.markAsSynced()
        }
    }

    @MainActor
    private func processTodoItemEntities(_ entities: [[String: Any]], currentUser: User)
        async throws
    {
        for data in entities {
            guard let uid = data["uid"] as? String else { continue }

            // Check if entity exists or create a new one
            let todoItem: TodoItem
            if let existingTodoItem = try todoItems.fetchUnique(withUID: uid) {
                todoItem = existingTodoItem
            } else {
                guard let title = data["title"] as? String,
                    let details = data["details"] as? String
                else { continue }

                todoItem = TodoItem(title: title, details: details, owner: nil)
                todoItem.uid = uid
                modelContext.insert(todoItem)
            }

            // Update properties
            todoItem.update(from: data)

            // Update owner if available
            if let ownerId = data["ownerId"] as? String {
                if ownerId != todoItem.owner?.uid {
                    if let owner = try? users.fetchUnique(withUID: ownerId) {
                        todoItem.owner = owner
                    }
                }
            } else if todoItem.owner != nil {
                todoItem.owner = nil
            }
            // Process meal reference if available
            if let mealUID = data["mealId"] as? String {
                if mealUID != todoItem.meal?.uid {
                    if let meal = try? meals.fetchUnique(withUID: mealUID) {
                        todoItem.meal = meal
                    }
                }
            } else if todoItem.meal != nil {
                todoItem.meal = nil
            }

            // Process shopping list item reference if available
            if let shoppingListItemUID = data["shoppingListItemId"] as? String {
                if shoppingListItemUID != todoItem.shoppingListItem?.uid {
                    if let shoppingListItem = try? shoppingItems.fetchUnique(
                        withUID: shoppingListItemUID)
                    {
                        todoItem.shoppingListItem = shoppingListItem
                    }
                }
            } else if todoItem.shoppingListItem != nil {
                todoItem.shoppingListItem = nil
            }

            // Process category if available
            if let categoryName = data["categoryName"] as? String {
                if categoryName != todoItem.category?.name {
                    todoItem.category = todoItemCategories.fetchOrCreate(named: categoryName)
                }
            } else if todoItem.category != nil {
                todoItem.category = nil
            }

            todoItem.markAsSynced()
        }
    }

    @MainActor
    private func processRecipeEntities(_ entities: [[String: Any]], currentUser: User) async throws
    {
        for data in entities {
            guard let uid = data["uid"] as? String else { continue }

            // Check if entity exists or create a new one
            let recipe: Recipe
            if let existingRecipe = try recipes.fetchUnique(withUID: uid) {
                recipe = existingRecipe
            } else {
                guard let title = data["title"] as? String,
                    let details = data["details"] as? String
                else { continue }

                recipe = Recipe(
                    title: title,
                    details: details,
                    owner: nil  // Will be updated based on references
                )
                recipe.uid = uid
                recipe.dirty = false  // Fresh from server
                modelContext.insert(recipe)
            }

            // Update properties using the Recipe's update method
            recipe.update(from: data)

            // Update owner if available
            if let ownerId = data["ownerId"] as? String {
                if ownerId != recipe.owner?.uid {
                    if let owner = try? users.fetchUnique(withUID: ownerId) {
                        recipe.owner = owner
                    }
                }
            } else if recipe.owner != nil {
                recipe.owner = nil
            }

            // Process meal references
            if let mealIds = data["mealIds"] as? [String], !mealIds.isEmpty {
                let currentMealIds = Set(recipe.meals.compactMap { $0.uid })
                let newMealIds = Set(mealIds).subtracting(currentMealIds)

                if !newMealIds.isEmpty {
                    if let newMeals = try? meals.fetchMany(withUIDs: Array(newMealIds)) {
                        recipe.meals.append(contentsOf: newMeals)
                    }
                }

                recipe.meals.removeAll { meal in
                    guard let mealUid = meal.uid else { return false }
                    return !mealIds.contains(mealUid)
                }
            }

            recipe.markAsSynced()
        }
    }

    @MainActor
    private func processMealEntities(_ entities: [[String: Any]], currentUser: User) async throws {
        for data in entities {
            guard let uid = data["uid"] as? String else { continue }

            // Check if entity exists or create a new one
            let meal: Meal
            if let existingMeal = try meals.fetchUnique(withUID: uid) {
                meal = existingMeal
            } else {
                guard let scalingFactor = data["scalingFactor"] as? Double,
                    let mealTypeRaw = data["mealType"] as? String,
                    let mealType = MealType(rawValue: mealTypeRaw)
                else { continue }

                meal = Meal(
                    scalingFactor: scalingFactor,
                    todoItem: nil,  // Will be updated later based on references
                    recipe: nil,  // Will be updated later based on references
                    mealType: mealType,
                    owner: nil  // Will be updated later based on references
                )
                meal.uid = uid
                modelContext.insert(meal)
            }

            // Update properties
            meal.update(from: data)

            // Update owner if available
            if let ownerId = data["ownerId"] as? String {
                if ownerId != meal.owner?.uid {
                    if let owner = try? users.fetchUnique(withUID: ownerId) {
                        meal.owner = owner
                    }
                }
            } else if meal.owner != nil {
                meal.owner = nil
            }

            // Process recipe reference if available
            if let recipeUID = data["recipeId"] as? String {
                if recipeUID != meal.recipe?.uid {
                    if let recipe = try? recipes.fetchUnique(withUID: recipeUID) {
                        meal.recipe = recipe
                    }
                }
            } else if meal.recipe != nil {
                meal.recipe = nil
            }

            // Process todoItem reference if available
            if let todoItemUID = data["todoItemId"] as? String {
                if todoItemUID != meal.todoItem?.uid {
                    if let todoItem = try? todoItems.fetchUnique(withUID: todoItemUID) {
                        meal.todoItem = todoItem
                    }
                }
            } else if meal.todoItem != nil {
                meal.todoItem = nil
            }

            // Process shopping list items
            if let shoppingItemIds = data["shoppingListItemIds"] as? [String],
                !shoppingItemIds.isEmpty
            {
                let currentItemIds = Set(meal.shoppingListItems.compactMap { $0.uid })
                let newItemIds = Set(shoppingItemIds).subtracting(currentItemIds)

                if !newItemIds.isEmpty {
                    if let newItems = try? shoppingItems.fetchMany(
                        withUIDs: Array(newItemIds)
                    ) {
                        meal.shoppingListItems.append(contentsOf: newItems)
                    }
                }

                meal.shoppingListItems.removeAll { item in
                    guard let itemUid = item.uid else { return false }
                    return !shoppingItemIds.contains(itemUid)
                }
            }
        }
    }

    @MainActor
    private func processShoppingListItemEntities(_ entities: [[String: Any]], currentUser: User)
        async throws
    {
        for data in entities {
            guard let uid = data["uid"] as? String else { continue }

            // Check if entity exists or create a new one
            let shoppingListItem: ShoppingListItem
            if let existingItem = try shoppingItems.fetchUnique(withUID: uid) {
                shoppingListItem = existingItem
            } else {
                guard let name = data["name"] as? String else { continue }

                shoppingListItem = ShoppingListItem(
                    name: name,
                    quantity: nil,  // Will be updated from data
                    unit: nil,  // Will be updated from data
                    todoItem: nil,  // Will be updated based on references
                    owner: nil  // Will be updated based on references
                )
                shoppingListItem.uid = uid
                modelContext.insert(shoppingListItem)
            }

            // Update properties
            shoppingListItem.update(from: data)

            // Update owner if available
            if let ownerId = data["ownerId"] as? String {
                if ownerId != shoppingListItem.owner?.uid {
                    if let owner = try? users.fetchUnique(withUID: ownerId) {
                        shoppingListItem.owner = owner
                    }
                }
            } else if shoppingListItem.owner != nil {
                shoppingListItem.owner = nil
            }

            // Process todoItem reference if available
            if let todoItemUID = data["todoItemId"] as? String {
                if todoItemUID != shoppingListItem.todoItem?.uid {
                    if let todoItem = try? todoItems.fetchUnique(withUID: todoItemUID) {
                        shoppingListItem.todoItem = todoItem
                    }
                }
            } else if shoppingListItem.todoItem != nil {
                shoppingListItem.todoItem = nil
            }

            // Process meal references
            if let mealIds = data["mealIds"] as? [String], !mealIds.isEmpty {
                let currentMealIds = Set(shoppingListItem.meals.compactMap { $0.uid })
                let newMealIds = Set(mealIds).subtracting(currentMealIds)

                if !newMealIds.isEmpty {
                    if let newMeals = try? meals.fetchMany(withUIDs: Array(newMealIds)) {
                        shoppingListItem.meals.append(contentsOf: newMeals)
                    }
                }

                shoppingListItem.meals.removeAll { meal in
                    guard let mealUid = meal.uid else { return false }
                    return !mealIds.contains(mealUid)
                }
            }

            shoppingListItem.markAsSynced()
        }
    }
}


