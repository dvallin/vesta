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
class SyncService {
    static let shared = SyncService()

    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?
    private var isSyncing = false

    private let syncInterval: TimeInterval = 60  // Sync every minute

    // API client would be injected here
    private let apiClient: APIClient

    private init(apiClient: APIClient = FirebaseAPIClient.shared) {
        self.apiClient = apiClient
    }

    func configure(with context: ModelContext) {
        self.modelContext = context
    }

    /// Start periodic sync operations
    func startSync() {
        stopSync()  // Ensure we don't have multiple timers

        // Immediately perform an initial sync
        performSync()

        // Schedule periodic sync
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) {
            [weak self] _ in
            self?.performSync()
        }
    }

    /// Stop periodic sync operations
    func stopSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    /// Force an immediate sync operation
    func forceSync() -> Future<Void, SyncError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }

            self.performSync { result in
                switch result {
                case .success:
                    promise(.success(()))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
    }

    // MARK: - Private methods

    private func performSync(completion: ((Result<Void, SyncError>) -> Void)? = nil) {
        guard !isSyncing else {
            completion?(.success(()))
            return
        }

        guard let context = modelContext else {
            completion?(.failure(.unknown))
            return
        }

        // Check if user is authenticated
        guard UserManager.shared.isAuthenticated else {
            completion?(.failure(.notAuthenticated))
            return
        }

        isSyncing = true

        // Synchronize all entity types
        syncEntities(of: TodoItem.self, in: context)
            .flatMap { _ in self.syncEntities(of: TodoItemEvent.self, in: context) }
            .flatMap { _ in self.syncEntities(of: TodoItem.self, in: context) }
            .flatMap { _ in self.syncEntities(of: Recipe.self, in: context) }
            .flatMap { _ in self.syncEntities(of: Meal.self, in: context) }
            .flatMap { _ in self.syncEntities(of: ShoppingListItem.self, in: context) }
            .flatMap { _ in self.syncEntities(of: Space.self, in: context) }
            .sink(
                receiveCompletion: { [weak self] completionState in
                    self?.isSyncing = false
                    switch completionState {
                    case .finished:
                        completion?(.success(()))
                    case .failure(let error):
                        completion?(.failure(error))
                    }
                }, receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    private func syncEntities<T: PersistentModel & SyncableEntity>(
        of type: T.Type, in context: ModelContext
    ) -> Future<Void, SyncError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }

            // Fetch dirty entities of this type
            let descriptor = FetchDescriptor<T>(predicate: #Predicate<T> { $0.dirty == true })

            do {
                let dirtyEntities = try context.fetch(descriptor)

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
                        return self.syncBatch(batch, context: context)
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
        _ entities: [T], context: ModelContext
    ) -> AnyPublisher<Void, SyncError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown))
                return
            }

            // Convert entities to DTOs for API
            let dtos = entities.map { self.convertToDTO($0) }

            // Call appropriate API endpoint based on entity type
            let entityName = String(describing: T.self).lowercased()

            self.apiClient.syncEntities(entityName: entityName, dtos: dtos)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            // Mark entities as synced
                            entities.forEach { entity in
                                entity.markAsSynced()
                            }

                            // Save context
                            do {
                                try context.save()
                                promise(.success(()))
                            } catch {
                                print("Error saving context after sync: \(error)")
                                promise(.failure(.unknown))
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

    // Convert entity to a DTO (Data Transfer Object) for API
    private func convertToDTO<T: SyncableEntity>(_ entity: T) -> [String: Any] {
        if let meal = entity as? Meal {
            return meal.toDTO()
        } else if let shoppingItem = entity as? ShoppingListItem {
            return shoppingItem.toDTO()
        } else if let recipe = entity as? Recipe {
            return recipe.toDTO()
        } else if let space = entity as? Space {
            return space.toDTO()
        } else if let todoItem = entity as? TodoItem {
            return todoItem.toDTO()
        } else if let todoItemEvent = entity as? TodoItemEvent {
            return todoItemEvent.toDTO()
        } else if let user = entity as? User {
            return user.toDTO()
        }

        return [
            "lastModified": entity.lastModified.timeIntervalSince1970,
            "ownerId": entity.owner?.id ?? "",
        ]
    }
}

protocol APIClient {
    func syncEntities(entityName: String, dtos: [[String: Any]]) -> AnyPublisher<Void, Error>
}
