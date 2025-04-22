import Combine
import Foundation

/// Protocol defining the invite management functionality
protocol InviteAPIClient {
    /// Sends an invite to another user
    /// - Parameters:
    ///   - currentUserId: The ID of the current user sending the invite
    ///   - currentUserData: Data about the current user to share with the recipient
    ///   - recipientId: The ID of the user to invite
    ///   - recipientData: Data about the recipient user
    /// - Returns: Publisher that emits void on success or an error
    func sendInvite(
        currentUserId: String,
        currentUserData: [String: Any],
        recipientId: String,
        recipientData: [String: Any]
    ) -> AnyPublisher<Void, Error>
    
    /// Accepts an invite from another user
    /// - Parameters:
    ///   - currentUserId: The ID of the current user accepting the invite
    ///   - inviteId: The ID of the invite being accepted
    ///   - senderId: The ID of the user who sent the invite
    /// - Returns: Publisher that emits void on success or an error
    func acceptInvite(
        currentUserId: String,
        inviteId: String,
        senderId: String
    ) -> AnyPublisher<Void, Error>
    
    /// Declines an invite from another user
    /// - Parameters:
    ///   - currentUserId: The ID of the current user declining the invite
    ///   - inviteId: The ID of the invite being declined
    ///   - senderId: The ID of the user who sent the invite
    /// - Returns: Publisher that emits void on success or an error
    func declineInvite(
        currentUserId: String,
        inviteId: String, 
        senderId: String
    ) -> AnyPublisher<Void, Error>
    
    /// Fetches all received invites for a user
    /// - Parameter userId: The ID of the user whose received invites to fetch
    /// - Returns: Publisher that emits an array of invite data or an error
    func fetchReceivedInvites(userId: String) -> AnyPublisher<[[String: Any]], Error>
    
    /// Fetches all sent invites for a user
    /// - Parameter userId: The ID of the user whose sent invites to fetch
    /// - Returns: Publisher that emits an array of invite data or an error
    func fetchSentInvites(userId: String) -> AnyPublisher<[[String: Any]], Error>
}