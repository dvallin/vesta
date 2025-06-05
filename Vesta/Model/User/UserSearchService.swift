import Combine
import Foundation
import os

/// Service for searching users in Firebase
class UserSearchService {
    private let apiClient: UserSearchAPIClient
    private let logger = Logger(subsystem: "com.app.Vesta", category: "UserSearch")
    private var cancellables = Set<AnyCancellable>()
    
    init(apiClient: UserSearchAPIClient = FirebaseAPIClient()) {
        self.apiClient = apiClient
    }

    /// Searches for users by partial name or email
    /// - Parameters:
    ///   - query: Search query string (partial name or email)
    ///   - limit: Maximum number of results to return (default: 10)
    ///   - completion: Callback that returns search results or an error
    func searchUsers(
        query: String,
        limit: Int = 10,
        completion: @escaping (Result<[UserSearchResult], Error>) -> Void
    ) {
        logger.info("Searching for users with query: \(query)")

        apiClient.searchUsers(query: query, limit: limit)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionStatus in
                    guard let self = self else { return }

                    if case .failure(let error) = completionStatus {
                        self.logger.error(
                            "User search failed: \(error.localizedDescription, privacy: .public)")
                        completion(.failure(error))
                    }
                },
                receiveValue: { [weak self] results in
                    guard let self = self else { return }

                    self.logger.info("Found \(results.count) users matching query: \(query)")
                    completion(.success(results))
                }
            )
            .store(in: &cancellables)
    }

    /// Asynchronous version of searchUsers for use with Swift concurrency
    /// - Parameters:
    ///   - query: Search query string (partial name or email)
    ///   - limit: Maximum number of results to return (default: 10)
    /// - Returns: Array of UserSearchResult objects
    func searchUsers(query: String, limit: Int = 10) async throws -> [UserSearchResult] {
        try await withCheckedThrowingContinuation { continuation in
            searchUsers(query: query, limit: limit) { result in
                continuation.resume(with: result)
            }
        }
    }
}
