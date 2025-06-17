import Combine
import Foundation

/// Protocol defining user search operations for API clients
protocol UserSearchAPIClient {
    /// Searches for users by partial name or email
    /// - Parameters:
    ///   - query: Search query string (partial name or email)
    ///   - limit: Maximum number of results to return
    /// - Returns: Publisher that emits search results or an error
    func searchUsers(query: String, limit: Int) -> AnyPublisher<[UserSearchResult], Error>
}
