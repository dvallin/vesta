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
            self.logger.error("Cannot start sync: User not authenticated")
            return
        }

        self.logger.info("Starting sync service")
        isSyncEnabled = true

        // Perform initial pull after a short delay to allow the app to finish loading
        DispatchQueue.main.asyncAfter(deadline: .now() + initialPullDelay) { [weak self] in
            guard let self = self else { return }

            // Step 1: Perform initial pull from Firebase
            self.self.logger.info("Performing initial pull from Firebase")
            self.pullChangesFromFirebase().sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        self.self.logger.error("Initial pull failed: \(error)")
                    }

                    // Step 2: Set up real-time subscription (even if initial pull failed)
                    self.setupRealTimeSubscription()
                },
                receiveValue: { _ in
                    self.self.logger.info("Initial pull completed successfully")
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
            self.logger.error("Cannot subscribe to updates: User not authenticated")
            return
        }

        self.logger.info("Setting up real-time subscription for user: \(userId)")

        realTimeSubscription = apiClient.subscribeToEntityUpdates(for: userId) {
            [weak self] entityData in
            guard let self = self else { return }

            self.self.logger.info(
                "Received real-time update with \(entityData.values.map { $0.count }.reduce(0, +)) entities"
            )

            // Process the received entities
            self.processReceivedEntities(entityData, currentUser: currentUser)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            self.self.logger.error("Error processing real-time update: \(error)")
                        }
                    },
                    receiveValue: { _ in
                        self.self.logger.debug("Real-time update processed successfully")
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
            self.self.logger.info("Performing scheduled push of local changes")

            // Only push local changes if we're not already syncing
            guard !self.isSyncing else {
                self.self.logger.info("Skipping scheduled push because sync is already in progress")
                return
            }

            // Push local changes to the server
            self.pushLocalChanges()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            self.self.logger.error("Scheduled push failed: \(error)")
                        }
                    },
                    receiveValue: { _ in
                        self.self.logger.info("Scheduled push completed successfully")
                    }
                )
                .store(in: &self.cancellables)
        }
    }

    /// Stop all sync operations
    func stopSync() {
        self.logger.info("Stopping sync service")

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
            self.logger.error(
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

        self.logger.info("Starting manual sync")
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
                    self?.self.logger.info("Manual sync completed successfully")
                    self?.lastSyncTime = Date()
                } else if case .failure(let error) = completion {
                    self?.self.logger.error("Manual sync failed: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }

    /// Push local changes to the server
    private func pushLocalChanges() -> AnyPublisher<Void, SyncError> {
        self.logger.info("Pushing local changes to Firebase")

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
                        self.self.logger.info("Successfully pushed local changes")
                        promise(.success(()))
                    case .failure(let error):
                        self.self.logger.error("Error pushing local changes: \(error)")
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
        self.logger.info("Pulling changes from Firebase")

        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }

            // Check if user is authenticated
            guard let currentUser = self.auth.currentUser,
                let userId = currentUser.uid
            else {
                self.self.logger.error("Cannot pull changes: User not authenticated")
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
                            self.self.logger.error(
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
                            self.self.logger.info(
                                "Received \(entityCount) updated entities from Firebase")
                        } else {
                            self.self.logger.info("No new updates from Firebase")
                            promise(.success(()))
                            return
                        }

                        self.processReceivedEntities(entityData, currentUser: currentUser)
                            .sink(
                                receiveCompletion: { completion in
                                    switch completion {
                                    case .finished:
                                        self.self.logger.info(
                                            "Successfully processed pulled entities")
                                        promise(.success(()))
                                    case .failure(let error):
                                        self.self.logger.error(
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
        self.logger.info("Processing \(entities.count) User entities")

        for data in entities {
            guard let uid = data["uid"] as? String else {
                self.logger.warning("Skipping User entity without UID")
                continue
            }

            // Check if entity exists or create a new one
            let user: User
            if let existingUser = try users.fetchUnique(withUID: uid) {
                user = existingUser
                self.logger.debug("Found existing User with UID: \(uid)")
            } else {
                // For new users, we need just the UID - the rest will be updated
                user = User(uid: uid)
                modelContext.insert(user)
                self.logger.debug("Created new User with UID: \(uid)")
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

            // Process friend IDs if available
            if let friendIds = data["friendIds"] as? [String], !friendIds.isEmpty {
                self.logger.debug("Processing \(friendIds.count) friends for user \(uid)")

                // Get current friend IDs for comparison
                let currentFriendIds = Set(user.friends.compactMap { $0.uid })
                // Find new friend IDs that need to be added
                let newFriendIds = Set(friendIds).subtracting(currentFriendIds)

                if !newFriendIds.isEmpty {
                    self.logger.debug("Adding \(newFriendIds.count) new friends to user \(uid)")
                    // Fetch and add new friends
                    if let newFriends = try? users.fetchMany(withUIDs: Array(newFriendIds)) {
                        user.friends.append(contentsOf: newFriends)
                    }

                    // If new friends couldn't be found in database, create placeholder users
                    let fetchedIds = Set(user.friends.compactMap { $0.uid })
                    let missingIds = newFriendIds.subtracting(fetchedIds)

                    for missingId in missingIds {
                        let newFriend = User(uid: missingId)
                        modelContext.insert(newFriend)
                        user.friends.append(newFriend)
                        self.logger.debug(
                            "Created placeholder user for friend with UID: \(missingId)")
                    }
                }

                // Remove friends that are no longer in the friend list
                user.friends.removeAll { friend in
                    guard let friendUid = friend.uid else { return false }
                    let shouldRemove = !friendIds.contains(friendUid)
                    if shouldRemove {
                        self.logger.debug("Removing friend with UID \(friendUid) from user \(uid)")
                    }
                    return shouldRemove
                }
            } else if !user.friends.isEmpty {
                self.logger.debug("Clearing all friends for user \(uid)")
                user.friends.removeAll()
            }

            user.markAsSynced()
            self.logger.debug("Successfully processed User: \(uid)")
        }
    }

    @MainActor
    private func processTodoItemEntities(_ entities: [[String: Any]], currentUser: User)
        async throws
    {
        self.logger.info("Processing \(entities.count) TodoItem entities")

        for data in entities {
            guard let uid = data["uid"] as? String else {
                self.logger.warning("Skipping TodoItem entity without UID")
                continue
            }

            // Check if entity exists or create a new one
            let todoItem: TodoItem
            if let existingTodoItem = try todoItems.fetchUnique(withUID: uid) {
                todoItem = existingTodoItem
                self.logger.debug("Found existing TodoItem with UID: \(uid)")
            } else {
                guard let title = data["title"] as? String,
                    let details = data["details"] as? String
                else {
                    self.logger.warning(
                        "Skipping TodoItem without required title or details: \(uid)")
                    continue
                }

                todoItem = TodoItem(title: title, details: details, owner: nil)
                todoItem.uid = uid
                modelContext.insert(todoItem)
                self.logger.debug("Created new TodoItem with UID: \(uid), title: \(title)")
            }

            // Update properties
            todoItem.update(from: data)
            self.logger.debug("Updated properties for TodoItem: \(uid)")

            // Update owner if available
            if let ownerId = data["ownerId"] as? String {
                if ownerId != todoItem.owner?.uid {
                    if let owner = try? users.fetchUnique(withUID: ownerId) {
                        todoItem.owner = owner
                        self.logger.debug("Set owner \(ownerId) for TodoItem: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find owner with UID \(ownerId) for TodoItem: \(uid)")
                    }
                }
            } else if todoItem.owner != nil {
                self.logger.debug("Removing owner from TodoItem: \(uid)")
                todoItem.owner = nil
            }

            // Process meal reference if available
            if let mealUID = data["mealId"] as? String {
                if mealUID != todoItem.meal?.uid {
                    if let meal = try? meals.fetchUnique(withUID: mealUID) {
                        todoItem.meal = meal
                        self.logger.debug("Set meal \(mealUID) for TodoItem: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find meal with UID \(mealUID) for TodoItem: \(uid)")
                    }
                }
            } else if todoItem.meal != nil {
                self.logger.debug("Removing meal from TodoItem: \(uid)")
                todoItem.meal = nil
            }

            // Process shopping list item reference if available
            if let shoppingListItemUID = data["shoppingListItemId"] as? String {
                if shoppingListItemUID != todoItem.shoppingListItem?.uid {
                    if let shoppingListItem = try? shoppingItems.fetchUnique(
                        withUID: shoppingListItemUID)
                    {
                        todoItem.shoppingListItem = shoppingListItem
                        self.logger.debug(
                            "Set shopping list item \(shoppingListItemUID) for TodoItem: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find shopping list item with UID \(shoppingListItemUID) for TodoItem: \(uid)"
                        )
                    }
                }
            } else if todoItem.shoppingListItem != nil {
                self.logger.debug("Removing shopping list item from TodoItem: \(uid)")
                todoItem.shoppingListItem = nil
            }

            // Process category if available
            if let categoryName = data["categoryName"] as? String {
                if categoryName != todoItem.category?.name {
                    todoItem.category = todoItemCategories.fetchOrCreate(named: categoryName)
                    self.logger.debug("Set category '\(categoryName)' for TodoItem: \(uid)")
                }
            } else if todoItem.category != nil {
                self.logger.debug("Removing category from TodoItem: \(uid)")
                todoItem.category = nil
            }

            todoItem.markAsSynced()
            self.logger.debug("Successfully processed TodoItem: \(uid)")
        }
    }

    @MainActor
    private func processRecipeEntities(_ entities: [[String: Any]], currentUser: User) async throws
    {
        self.logger.info("Processing \(entities.count) Recipe entities")

        for data in entities {
            guard let uid = data["uid"] as? String else {
                self.logger.warning("Skipping Recipe entity without UID")
                continue
            }

            // Check if entity exists or create a new one
            let recipe: Recipe
            if let existingRecipe = try recipes.fetchUnique(withUID: uid) {
                recipe = existingRecipe
                self.logger.debug("Found existing Recipe with UID: \(uid)")
            } else {
                guard let title = data["title"] as? String,
                    let details = data["details"] as? String
                else {
                    self.logger.warning("Skipping Recipe without required title or details: \(uid)")
                    continue
                }

                recipe = Recipe(
                    title: title,
                    details: details,
                    owner: nil  // Will be updated based on references
                )
                recipe.uid = uid
                recipe.dirty = false  // Fresh from server
                modelContext.insert(recipe)
                self.logger.debug("Created new Recipe with UID: \(uid), title: \(title)")
            }

            // Update properties using the Recipe's update method
            recipe.update(from: data)
            self.logger.debug("Updated properties for Recipe: \(uid)")

            // Update owner if available
            if let ownerId = data["ownerId"] as? String {
                if ownerId != recipe.owner?.uid {
                    if let owner = try? users.fetchUnique(withUID: ownerId) {
                        recipe.owner = owner
                        self.logger.debug("Set owner \(ownerId) for Recipe: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find owner with UID \(ownerId) for Recipe: \(uid)")
                    }
                }
            } else if recipe.owner != nil {
                self.logger.debug("Removing owner from Recipe: \(uid)")
                recipe.owner = nil
            }

            // Process meal references
            if let mealIds = data["mealIds"] as? [String], !mealIds.isEmpty {
                self.logger.debug("Processing \(mealIds.count) meal references for Recipe: \(uid)")

                let currentMealIds = Set(recipe.meals.compactMap { $0.uid })
                let newMealIds = Set(mealIds).subtracting(currentMealIds)

                if !newMealIds.isEmpty {
                    if let newMeals = try? meals.fetchMany(withUIDs: Array(newMealIds)) {
                        recipe.meals.append(contentsOf: newMeals)
                        self.logger.debug("Added \(newMeals.count) new meals to Recipe: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find any of the \(newMealIds.count) new meals for Recipe: \(uid)"
                        )
                    }
                }

                // Remove meals that are no longer associated with this recipe
                let initialCount = recipe.meals.count
                recipe.meals.removeAll { meal in
                    guard let mealUid = meal.uid else { return false }
                    return !mealIds.contains(mealUid)
                }
                let removedCount = initialCount - recipe.meals.count
                if removedCount > 0 {
                    self.logger.debug("Removed \(removedCount) meals from Recipe: \(uid)")
                }
            } else if !recipe.meals.isEmpty {
                self.logger.debug("Clearing all \(recipe.meals.count) meals from Recipe: \(uid)")
                recipe.meals.removeAll()
            }

            recipe.markAsSynced()
            self.logger.debug("Successfully processed Recipe: \(uid)")
        }
    }

    @MainActor
    private func processMealEntities(_ entities: [[String: Any]], currentUser: User) async throws {
        self.logger.info("Processing \(entities.count) Meal entities")

        for data in entities {
            guard let uid = data["uid"] as? String else {
                self.logger.warning("Skipping Meal entity without UID")
                continue
            }

            // Check if entity exists or create a new one
            let meal: Meal
            if let existingMeal = try meals.fetchUnique(withUID: uid) {
                meal = existingMeal
                self.logger.debug("Found existing Meal with UID: \(uid)")
            } else {
                guard let scalingFactor = data["scalingFactor"] as? Double,
                    let mealTypeRaw = data["mealType"] as? String,
                    let mealType = MealType(rawValue: mealTypeRaw)
                else {
                    self.logger.warning("Skipping Meal without required properties: \(uid)")
                    continue
                }

                meal = Meal(
                    scalingFactor: scalingFactor,
                    todoItem: nil,  // Will be updated later based on references
                    recipe: nil,  // Will be updated later based on references
                    mealType: mealType,
                    owner: nil  // Will be updated later based on references
                )
                meal.uid = uid
                modelContext.insert(meal)
                self.logger.debug("Created new Meal with UID: \(uid), type: \(mealType.rawValue)")
            }

            // Update properties
            meal.update(from: data)
            self.logger.debug("Updated properties for Meal: \(uid)")

            // Update owner if available
            if let ownerId = data["ownerId"] as? String {
                if ownerId != meal.owner?.uid {
                    if let owner = try? users.fetchUnique(withUID: ownerId) {
                        meal.owner = owner
                        self.logger.debug("Set owner \(ownerId) for Meal: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find owner with UID \(ownerId) for Meal: \(uid)")
                    }
                }
            } else if meal.owner != nil {
                self.logger.debug("Removing owner from Meal: \(uid)")
                meal.owner = nil
            }

            // Process recipe reference if available
            if let recipeUID = data["recipeId"] as? String {
                if recipeUID != meal.recipe?.uid {
                    if let recipe = try? recipes.fetchUnique(withUID: recipeUID) {
                        meal.recipe = recipe
                        self.logger.debug("Set recipe \(recipeUID) for Meal: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find recipe with UID \(recipeUID) for Meal: \(uid)")
                    }
                }
            } else if meal.recipe != nil {
                self.logger.debug("Removing recipe from Meal: \(uid)")
                meal.recipe = nil
            }

            // Process todoItem reference if available
            if let todoItemUID = data["todoItemId"] as? String {
                if todoItemUID != meal.todoItem?.uid {
                    if let todoItem = try? todoItems.fetchUnique(withUID: todoItemUID) {
                        meal.todoItem = todoItem
                        self.logger.debug("Set todoItem \(todoItemUID) for Meal: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find todoItem with UID \(todoItemUID) for Meal: \(uid)")
                    }
                }
            } else if meal.todoItem != nil {
                self.logger.debug("Removing todoItem from Meal: \(uid)")
                meal.todoItem = nil
            }

            // Process shopping list items
            if let shoppingItemIds = data["shoppingListItemIds"] as? [String],
                !shoppingItemIds.isEmpty
            {
                self.logger.debug(
                    "Processing \(shoppingItemIds.count) shopping list items for Meal: \(uid)")

                let currentItemIds = Set(meal.shoppingListItems.compactMap { $0.uid })
                let newItemIds = Set(shoppingItemIds).subtracting(currentItemIds)

                if !newItemIds.isEmpty {
                    if let newItems = try? shoppingItems.fetchMany(
                        withUIDs: Array(newItemIds)
                    ) {
                        meal.shoppingListItems.append(contentsOf: newItems)
                        self.logger.debug(
                            "Added \(newItems.count) new shopping items to Meal: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find any of the \(newItemIds.count) new shopping items for Meal: \(uid)"
                        )
                    }
                }

                // Remove items that are no longer associated with this meal
                let initialCount = meal.shoppingListItems.count
                meal.shoppingListItems.removeAll { item in
                    guard let itemUid = item.uid else { return false }
                    return !shoppingItemIds.contains(itemUid)
                }
                let removedCount = initialCount - meal.shoppingListItems.count
                if removedCount > 0 {
                    self.logger.debug("Removed \(removedCount) shopping items from Meal: \(uid)")
                }
            } else if !meal.shoppingListItems.isEmpty {
                self.logger.debug(
                    "Clearing all \(meal.shoppingListItems.count) shopping items from Meal: \(uid)")
                meal.shoppingListItems.removeAll()
            }

            meal.markAsSynced()
            self.logger.debug("Successfully processed Meal: \(uid)")
        }
    }

    @MainActor
    private func processShoppingListItemEntities(_ entities: [[String: Any]], currentUser: User)
        async throws
    {
        self.logger.info("Processing \(entities.count) ShoppingListItem entities")

        for data in entities {
            guard let uid = data["uid"] as? String else {
                self.logger.warning("Skipping ShoppingListItem entity without UID")
                continue
            }

            // Check if entity exists or create a new one
            let shoppingListItem: ShoppingListItem
            if let existingItem = try shoppingItems.fetchUnique(withUID: uid) {
                shoppingListItem = existingItem
                self.logger.debug("Found existing ShoppingListItem with UID: \(uid)")
            } else {
                guard let name = data["name"] as? String else {
                    self.logger.warning("Skipping ShoppingListItem without required name: \(uid)")
                    continue
                }

                shoppingListItem = ShoppingListItem(
                    name: name,
                    quantity: nil,  // Will be updated from data
                    unit: nil,  // Will be updated from data
                    todoItem: nil,  // Will be updated based on references
                    owner: nil  // Will be updated based on references
                )
                shoppingListItem.uid = uid
                modelContext.insert(shoppingListItem)
                self.logger.debug("Created new ShoppingListItem with UID: \(uid), name: \(name)")
            }

            // Update properties
            shoppingListItem.update(from: data)
            self.logger.debug("Updated properties for ShoppingListItem: \(uid)")

            // Update owner if available
            if let ownerId = data["ownerId"] as? String {
                if ownerId != shoppingListItem.owner?.uid {
                    if let owner = try? users.fetchUnique(withUID: ownerId) {
                        shoppingListItem.owner = owner
                        self.logger.debug("Set owner \(ownerId) for ShoppingListItem: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find owner with UID \(ownerId) for ShoppingListItem: \(uid)")
                    }
                }
            } else if shoppingListItem.owner != nil {
                self.logger.debug("Removing owner from ShoppingListItem: \(uid)")
                shoppingListItem.owner = nil
            }

            // Process todoItem reference if available
            if let todoItemUID = data["todoItemId"] as? String {
                if todoItemUID != shoppingListItem.todoItem?.uid {
                    if let todoItem = try? todoItems.fetchUnique(withUID: todoItemUID) {
                        shoppingListItem.todoItem = todoItem
                        self.logger.debug(
                            "Set todoItem \(todoItemUID) for ShoppingListItem: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find todoItem with UID \(todoItemUID) for ShoppingListItem: \(uid)"
                        )
                    }
                }
            } else if shoppingListItem.todoItem != nil {
                self.logger.debug("Removing todoItem from ShoppingListItem: \(uid)")
                shoppingListItem.todoItem = nil
            }

            // Process meal references
            if let mealIds = data["mealIds"] as? [String], !mealIds.isEmpty {
                self.logger.debug(
                    "Processing \(mealIds.count) meal references for ShoppingListItem: \(uid)")

                let currentMealIds = Set(shoppingListItem.meals.compactMap { $0.uid })
                let newMealIds = Set(mealIds).subtracting(currentMealIds)

                if !newMealIds.isEmpty {
                    if let newMeals = try? meals.fetchMany(withUIDs: Array(newMealIds)) {
                        shoppingListItem.meals.append(contentsOf: newMeals)
                        self.logger.debug(
                            "Added \(newMeals.count) new meals to ShoppingListItem: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find any of the \(newMealIds.count) new meals for ShoppingListItem: \(uid)"
                        )
                    }
                }

                // Remove meals that are no longer associated with this shopping list item
                let initialCount = shoppingListItem.meals.count
                shoppingListItem.meals.removeAll { meal in
                    guard let mealUid = meal.uid else { return false }
                    return !mealIds.contains(mealUid)
                }
                let removedCount = initialCount - shoppingListItem.meals.count
                if removedCount > 0 {
                    self.logger.debug("Removed \(removedCount) meals from ShoppingListItem: \(uid)")
                }
            } else if !shoppingListItem.meals.isEmpty {
                self.logger.debug(
                    "Clearing all \(shoppingListItem.meals.count) meals from ShoppingListItem: \(uid)"
                )
                shoppingListItem.meals.removeAll()
            }

            shoppingListItem.markAsSynced()
            self.logger.debug("Successfully processed ShoppingListItem: \(uid)")
        }
    }
}
