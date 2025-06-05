import Combine
import Foundation
import OSLog
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
    private var entityProcessorCoordinator: EntityProcessorCoordinator

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

        // Initialize the entity processor coordinator
        self.entityProcessorCoordinator = EntityProcessorCoordinator(
            modelContext: modelContext,
            users: users,
            todoItems: todoItems,
            todoItemCategories: todoItemCategories,
            meals: meals,
            recipes: recipes,
            shoppingItems: shoppingItems,
            logger: logger
        )
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
                                // Map the API entity types to our internal structure
                                let mappedEntityData = self.mapEntityTypes(entityData)

                                // Process all entities using the coordinator
                                try await self.entityProcessorCoordinator.processEntities(
                                    mappedEntityData,
                                    currentUser: currentUser
                                )

                                // Save all changes
                                try self.modelContext.save()

                                // Complete successfully
                                promise(.success(()))
                            } catch {
                                self.logger.error("Error processing entities: \(error)")
                                promise(.failure(.unknown))
                            }
                        }
                    }
                } catch {
                    self.logger.error("Error in MainActor scheduling: \(error)")
                    await MainActor.run {
                        promise(.failure(.unknown))
                    }
                }
            }
        }
    }

    /// Maps the API entity type names to our internal entity names
    private func mapEntityTypes(_ entityData: [String: [[String: Any]]]) -> [String: [[String:
        Any]]]
    {
        var mappedData: [String: [[String: Any]]] = [:]

        for (entityType, entities) in entityData {
            switch entityType {
            case "User":
                mappedData["users"] = entities
            case "TodoItem":
                mappedData["todoItems"] = entities
            case "Recipe":
                mappedData["recipes"] = entities
            case "Meal":
                mappedData["meals"] = entities
            case "ShoppingListItem":
                mappedData["shoppingListItems"] = entities
            default:
                self.logger.warning("Unknown entity type: \(entityType)")
            }
        }

        return mappedData
    }

    // Entity processing has been refactored into separate processor classes

    // Entity processing has been refactored into separate processor classes

    // Entity processing has been refactored into separate processor classes

    // Entity processing has been refactored into separate processor classes

    // Entity processing has been refactored into separate processor classes
}
