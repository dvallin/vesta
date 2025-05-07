import Combine
import FirebaseFirestore
import Foundation
import os

// MARK: - User Search Extension
extension FirebaseAPIClient: UserSearchAPIClient {
    /// Searches for users by partial name or email
    /// - Parameters:
    ///   - query: Search query string (partial name or email)
    ///   - limit: Maximum number of results to return (default: 10)
    /// - Returns: Publisher that emits search results or an error
    func searchUsers(query: String, limit: Int = 10) -> AnyPublisher<[UserSearchResult], Error> {
        logger.info("Searching for users with query: \(query)")

        // Normalize and validate the query
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !normalizedQuery.isEmpty else {
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        return Future<[UserSearchResult], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FirebaseError.unknown))
                return
            }

            // Create a dispatch group to manage multiple queries
            let dispatchGroup = DispatchGroup()
            var allResults: [UserSearchResult] = []
            var searchError: Error?

            // Synchronization queue for thread safety when merging results
            let resultsQueue = DispatchQueue(label: "com.app.Vesta.userSearchResults")

            // Search by exact email
            dispatchGroup.enter()
            self.db.collection("users")
                .whereField("email", isEqualTo: normalizedQuery)
                .limit(to: limit)
                .getDocuments { (snapshot, error) in
                    defer { dispatchGroup.leave() }

                    if let error = error {
                        searchError = error
                        return
                    }

                    if let documents = snapshot?.documents {
                        let results = documents.compactMap { document -> UserSearchResult? in
                            let rawData = document.data()
                            let data = self.desanitizeDTO(rawData)
                            return UserSearchResult(
                                uid: document.documentID,
                                email: data["email"] as? String,
                                displayName: data["displayName"] as? String,
                                photoURL: data["photoURL"] as? String
                            )
                        }

                        resultsQueue.sync {
                            allResults.append(contentsOf: results)
                        }
                    }
                }

            // If the query appears to be a partial email (contains @), search by email prefix
            if normalizedQuery.contains("@") {
                dispatchGroup.enter()
                self.db.collection("users")
                    .whereField("email", isGreaterThanOrEqualTo: normalizedQuery)
                    .whereField("email", isLessThanOrEqualTo: normalizedQuery + "\u{f8ff}")
                    .limit(to: limit)
                    .getDocuments { (snapshot, error) in
                        defer { dispatchGroup.leave() }

                        if let error = error {
                            searchError = error
                            return
                        }

                        if let documents = snapshot?.documents {
                            let results = documents.compactMap { document -> UserSearchResult? in
                                let rawData = document.data()
                                let data = self.desanitizeDTO(rawData)
                                return UserSearchResult(
                                    uid: document.documentID,
                                    email: data["email"] as? String,
                                    displayName: data["displayName"] as? String,
                                    photoURL: data["photoURL"] as? String
                                )
                            }

                            resultsQueue.sync {
                                allResults.append(contentsOf: results)
                            }
                        }
                    }
            } else {
                // Search by display name prefix
                dispatchGroup.enter()
                self.db.collection("users")
                    .whereField("displayName", isGreaterThanOrEqualTo: normalizedQuery)
                    .whereField("displayName", isLessThanOrEqualTo: normalizedQuery + "\u{f8ff}")
                    .limit(to: limit)
                    .getDocuments { (snapshot, error) in
                        defer { dispatchGroup.leave() }

                        if let error = error {
                            searchError = error
                            return
                        }

                        if let documents = snapshot?.documents {
                            let results = documents.compactMap { document -> UserSearchResult? in
                                let rawData = document.data()
                                let data = self.desanitizeDTO(rawData)
                                return UserSearchResult(
                                    uid: document.documentID,
                                    email: data["email"] as? String,
                                    displayName: data["displayName"] as? String,
                                    photoURL: data["photoURL"] as? String
                                )
                            }

                            resultsQueue.sync {
                                allResults.append(contentsOf: results)
                            }
                        }
                    }
            }

            // Process the combined results
            dispatchGroup.notify(queue: .main) {
                if let error = searchError {
                    self.logger.error(
                        "User search failed: \(error.localizedDescription, privacy: .public)")
                    promise(.failure(error))
                    return
                }

                // Remove duplicates based on user ID
                var uniqueResults: [UserSearchResult] = []
                var seenIds = Set<String>()

                for result in allResults {
                    if !seenIds.contains(result.uid) {
                        uniqueResults.append(result)
                        seenIds.insert(result.uid)
                    }
                }

                // Limit the number of results
                let limitedResults = Array(uniqueResults.prefix(limit))

                self.logger.info(
                    "Found \(limitedResults.count) users matching query: \(normalizedQuery)")
                promise(.success(limitedResults))
            }
        }.eraseToAnyPublisher()
    }
}
