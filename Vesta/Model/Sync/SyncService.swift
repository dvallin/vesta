import Combine
import Foundation
import SwiftData

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

    private let syncInterval: TimeInterval = 10  // seconds

    // API client would be injected here
    private let apiClient: APIClient

    public init(
        apiClient: APIClient = FirebaseAPIClient(),
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

    /// Start periodic sync operations
    func startSync() {
        stopSync()

        // Immediately perform an initial sync
        syncOnce()

        // Schedule periodic sync
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) {
            [weak self] _ in
            self?.syncOnce()
        }
    }

    /// Stop periodic sync operations
    func stopSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    // MARK: - Private methods
    /// Perform a full bidirectional sync (push local changes, then pull remote changes)
    private func syncOnce(completion: ((Result<Void, SyncError>) -> Void)? = nil) {
        guard !isSyncing else {
            completion?(.success(()))
            return
        }

        // Check if user is authenticated
        guard auth.currentUser != nil else {
            completion?(.failure(.notAuthenticated))
            return
        }

        isSyncing = true

        // Perform bidirectional sync: push changes then pull changes
        pushLocalChanges()
            .flatMap { [weak self] _ -> Future<Void, SyncError> in
                guard let self = self else {
                    return Future { promise in promise(.failure(.unknown)) }
                }
                // Then pull changes from the server
                return self.pullChangesFromFirebase()
            }
            .sink(
                receiveCompletion: { [weak self] completionState in
                    Task { @MainActor in
                        self?.isSyncing = false
                        switch completionState {
                        case .finished:
                            completion?(.success(()))
                        case .failure(let error):
                            completion?(.failure(error))
                        }
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    /// Push local changes to the server
    private func pushLocalChanges() -> Future<Void, SyncError> {
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
                        promise(.success(()))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &self.cancellables)
        }
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
    func pullChangesFromFirebase() -> Future<Void, SyncError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }

            // Check if user is authenticated
            guard let currentUser = self.auth.currentUser,
                let userId = currentUser.uid
            else {
                promise(.failure(.notAuthenticated))
                return
            }

            // Define entity types to sync
            let entityTypes = [
                "User",
                "TodoItem",
                "Recipe",
                "Meal",
                "ShoppingListItem",
            ]

            self.apiClient.fetchUpdatedEntities(entityTypes: entityTypes, userId: userId)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            promise(.success(()))
                        case .failure(let error):
                            print("Error pulling changes: \(error)")
                            promise(.failure(.apiError(error)))
                        }
                    },
                    receiveValue: { [weak self] entityData in
                        guard let self = self else {
                            promise(.failure(.unknown))
                            return
                        }

                        self.processReceivedEntities(entityData, currentUser: currentUser)
                            .sink(
                                receiveCompletion: { completion in
                                    switch completion {
                                    case .finished:
                                        promise(.success(()))
                                    case .failure(let error):
                                        promise(.failure(error))
                                    }
                                },
                                receiveValue: { _ in }
                            )
                            .store(in: &self.cancellables)
                    }
                )
                .store(in: &self.cancellables)
        }
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

            // Update lastModifiedBy if available
            if let lastModifiedById = data["lastModifiedBy"] as? String {
                if lastModifiedById != user.lastModifiedBy?.uid {
                    if lastModifiedById == uid {
                        user.lastModifiedBy = user
                    } else if let lastModifiedBy = try? users.fetchUnique(withUID: lastModifiedById)
                    {
                        user.lastModifiedBy = lastModifiedBy
                    }
                }
            } else if user.lastModifiedBy != nil {
                user.lastModifiedBy = nil
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

            // Update lastModifiedBy if available
            if let lastModifiedById = data["lastModifiedBy"] as? String {
                if lastModifiedById != todoItem.lastModifiedBy?.uid {
                    if let lastModifiedBy = try? users.fetchUnique(withUID: lastModifiedById) {
                        todoItem.lastModifiedBy = lastModifiedBy
                    }
                }
            } else if todoItem.lastModifiedBy != nil {
                todoItem.lastModifiedBy = nil
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

            // Update properties
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

            // Update lastModifiedBy if available
            if let lastModifiedById = data["lastModifiedBy"] as? String {
                if lastModifiedById != recipe.lastModifiedBy?.uid {
                    if let lastModifiedBy = try? users.fetchUnique(withUID: lastModifiedById) {
                        recipe.lastModifiedBy = lastModifiedBy
                    }
                }
            } else if recipe.lastModifiedBy != nil {
                recipe.lastModifiedBy = nil
            }

            // For non-syncable related entities (ingredients and steps), we always recreate them
            // Process ingredients - first remove all existing ingredients
            recipe.ingredients.removeAll()

            // Then add new ingredients from data
            if let ingredients = data["ingredients"] as? [[String: Any]] {
                for ingredientData in ingredients {
                    guard let name = ingredientData["name"] as? String,
                        let order = ingredientData["order"] as? Int
                    else { continue }

                    let quantity = ingredientData["quantity"] as? Double
                    var unit: Unit? = nil
                    if let unitRaw = ingredientData["unit"] as? String {
                        unit = Unit(rawValue: unitRaw)
                    }

                    let ingredient = Ingredient(
                        name: name,
                        order: order,
                        quantity: quantity,
                        unit: unit,
                        recipe: recipe
                    )
                    recipe.ingredients.append(ingredient)
                }
            }

            // Process steps - first remove all existing steps
            recipe.steps.removeAll()

            // Then add new steps from data
            if let steps = data["steps"] as? [[String: Any]] {
                for stepData in steps {
                    guard let order = stepData["order"] as? Int,
                        let instruction = stepData["instruction"] as? String,
                        let typeRaw = stepData["type"] as? String,
                        let type = StepType(rawValue: typeRaw)
                    else { continue }

                    let duration = stepData["duration"] as? TimeInterval

                    let step = RecipeStep(
                        order: order,
                        instruction: instruction,
                        type: type,
                        duration: duration,
                        recipe: recipe
                    )
                    recipe.steps.append(step)
                }
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

            // Update lastModifiedBy if available
            if let lastModifiedById = data["lastModifiedBy"] as? String {
                if lastModifiedById != meal.lastModifiedBy?.uid {
                    if let lastModifiedBy = try? users.fetchUnique(withUID: lastModifiedById) {
                        meal.lastModifiedBy = lastModifiedBy
                    }
                }
            } else if meal.lastModifiedBy != nil {
                meal.lastModifiedBy = nil
            }

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

            // Update lastModifiedBy if available
            if let lastModifiedById = data["lastModifiedBy"] as? String {
                if lastModifiedById != shoppingListItem.lastModifiedBy?.uid {
                    if let lastModifiedBy = try? users.fetchUnique(withUID: lastModifiedById) {
                        shoppingListItem.lastModifiedBy = lastModifiedBy
                    }
                }
            } else if shoppingListItem.lastModifiedBy != nil {
                shoppingListItem.lastModifiedBy = nil
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

protocol APIClient {
    func syncEntities(dtos: [[String: Any]]) -> AnyPublisher<Void, Error>
    func fetchUpdatedEntities(entityTypes: [String], userId: String) -> AnyPublisher<
        [String: [[String: Any]]], Error
    >
}
