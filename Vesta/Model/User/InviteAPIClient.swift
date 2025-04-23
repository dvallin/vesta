import Combine
import Foundation

/// Protocol defining the invite management functionality
protocol InviteAPIClient {
    /// Sends an invite to another user
    /// - Parameter invite: The complete invite object to be sent
    /// - Returns: Publisher that emits void on success or an error
    func sendInvite(_ invite: Invite) -> AnyPublisher<Void, Error>

    /// Accepts an invite from another user (only the recipient can accept)
    /// - Parameter invite: The invite object to be accepted
    /// - Returns: Publisher that emits void on success or an error
    func acceptInvite(_ invite: Invite) -> AnyPublisher<Void, Error>

    /// Declines an invite from another user (only the recipient can decline)
    /// - Parameter invite: The invite object to be declined
    /// - Returns: Publisher that emits void on success or an error
    func declineInvite(_ invite: Invite) -> AnyPublisher<Void, Error>

    /// Fetches all received invites for a user
    /// - Parameter userId: The ID of the user whose received invites to fetch
    /// - Returns: Publisher that emits an array of invite data or an error
    func fetchReceivedInvites(userId: String) -> AnyPublisher<[[String: Any]], Error>

    /// Fetches all sent invites for a user
    /// - Parameter userId: The ID of the user whose sent invites to fetch
    /// - Returns: Publisher that emits an array of invite data or an error
    func fetchSentInvites(userId: String) -> AnyPublisher<[[String: Any]], Error>
}
