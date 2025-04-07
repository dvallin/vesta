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
    private var userManager: UserManager

    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?
    private var isSyncing = false

    private let syncInterval: TimeInterval = 60  // Sync every minute

    // API client would be injected here
    private let apiClient: APIClient

    public init(
        apiClient: APIClient = FirebaseAPIClient(), userManager: UserManager,
        modelContext: ModelContext
    ) {
        self.apiClient = apiClient
        self.modelContext = modelContext
        self.userManager = userManager
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

        // Check if user is authenticated
        guard userManager.currentUser != nil else {
            completion?(.failure(.notAuthenticated))
            return
        }

        isSyncing = true

        // Synchronize all entity types
        syncEntities(of: TodoItem.self)
            .flatMap { _ in self.syncEntities(of: TodoItemEvent.self) }
            .flatMap { _ in self.syncEntities(of: TodoItem.self) }
            .flatMap { _ in self.syncEntities(of: Recipe.self) }
            .flatMap { _ in self.syncEntities(of: Meal.self) }
            .flatMap { _ in self.syncEntities(of: ShoppingListItem.self) }
            .flatMap { _ in self.syncEntities(of: Space.self) }
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

                        case .failure(let error):
                            print("Error syncing \(entityName): \(error)")
                            promise(.failure(.apiError(error)))
                        }
                    }, receiveValue: { _ in }
                )
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
}

protocol APIClient {
    func syncEntities(dtos: [[String: Any]]) -> AnyPublisher<Void, Error>
}
