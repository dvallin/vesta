import Combine
import Foundation

/// Protocol defining the API operations required by the sync service
protocol SyncAPIClient {
    /// Synchronizes local entities to the backend
    /// - Parameter dtos: Array of entity dictionaries to sync
    /// - Returns: Publisher that emits void on success or error on failure
    func syncEntities(dtos: [[String: Any]]) -> AnyPublisher<Void, Error>
    
    /// Fetches updated entities from the backend based on last sync time
    /// - Parameters:
    ///   - userId: Current user's ID
    /// - Returns: Publisher that emits fetched entities or an error
    func fetchUpdatedEntities(userId: String) -> AnyPublisher<
        [String: [[String: Any]]], Error
    >

    /// Subscribes to real-time updates for a user's entities
    /// - Parameters:
    ///   - userId: The ID of the user whose entities to subscribe to
    ///   - onUpdate: Callback function triggered when entities are updated
    ///   - entityData: Dictionary containing updated entities by entity type
    /// - Returns: A cancellable object that, when cancelled, will unsubscribe from updates
    func subscribeToEntityUpdates(
        for userId: String,
        onUpdate: @escaping (_ entityData: [String: [[String: Any]]]) -> Void
    ) -> AnyCancellable
}