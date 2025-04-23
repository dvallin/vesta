import Combine
import FirebaseFirestore
import Foundation
import os

// MARK: - Invite Management Extension
extension FirebaseAPIClient: InviteAPIClient {
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
    ) -> AnyPublisher<Void, Error> {
        logger.info("Sending invite from user \(currentUserId) to user \(recipientId)")

        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FirebaseError.unknown))
                return
            }

            let batch = self.db.batch()

            // Create invite objects
            let timestamp = Date().timeIntervalSince1970
            let inviteId = "\(currentUserId)_to_\(recipientId)_\(timestamp)"

            // Prepare invite data for the sender to store
            var sentInvite: [String: Any] = [
                "uid": inviteId,
                "createdAt": FieldValue.serverTimestamp(),
                "recipientUid": recipientId,
            ]

            // Add recipient data to sent invite
            if let email = recipientData["email"] as? String {
                sentInvite["email"] = email
            }

            if let displayName = recipientData["displayName"] as? String {
                sentInvite["displayName"] = displayName
            }

            if let photoURL = recipientData["photoURL"] as? String {
                sentInvite["photoURL"] = photoURL
            }

            // Prepare invite data for the recipient to store
            var receivedInvite: [String: Any] = [
                "uid": inviteId,
                "createdAt": FieldValue.serverTimestamp(),
                "senderUid": currentUserId,
            ]

            // Add sender data to received invite
            if let email = currentUserData["email"] as? String {
                receivedInvite["email"] = email
            }

            if let displayName = currentUserData["displayName"] as? String {
                receivedInvite["displayName"] = displayName
            }

            if let photoURL = currentUserData["photoURL"] as? String {
                receivedInvite["photoURL"] = photoURL
            }

            // Add the invite to each user's document
            let senderRef = self.db.collection("users").document(currentUserId)
            let recipientRef = self.db.collection("users").document(recipientId)

            // Update sender document with new sent invite
            batch.updateData(
                [
                    "sentInvites": FieldValue.arrayUnion([sentInvite]),
                    "lastModified": FieldValue.serverTimestamp(),
                ], forDocument: senderRef)

            // Update recipient document with new received invite
            batch.updateData(
                [
                    "receivedInvites": FieldValue.arrayUnion([receivedInvite]),
                    "lastModified": FieldValue.serverTimestamp(),
                ], forDocument: recipientRef)

            // Execute the batch
            batch.commit { error in
                if let error = error {
                    self.logger.error(
                        "Failed to send invite: \(error.localizedDescription, privacy: .public)")
                    promise(.failure(error))
                } else {
                    self.logger.info(
                        "Successfully sent invite from \(currentUserId) to \(recipientId)")
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

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
    ) -> AnyPublisher<Void, Error> {
        logger.info("User \(currentUserId) accepting invite \(inviteId) from \(senderId)")

        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FirebaseError.unknown))
                return
            }

            // Get current user document to find the received invite
            self.db.collection("users").document(currentUserId).getDocument { [weak self] (userDoc, error) in
                guard let self = self else {
                    promise(.failure(FirebaseError.unknown))
                    return
                }

                if let error = error {
                    self.logger.error(
                        "Error fetching user document: \(error.localizedDescription, privacy: .public)"
                    )
                    promise(.failure(error))
                    return
                }

                guard let userDoc = userDoc, userDoc.exists,
                      var receivedInvites = userDoc.data()?["receivedInvites"] as? [[String: Any]] else {
                    self.logger.error("User document or receivedInvites not found")
                    promise(.failure(FirebaseError.notFound))
                    return
                }

                // Find the invite in the receivedInvites array
                guard let inviteIndex = receivedInvites.firstIndex(where: { ($0["uid"] as? String) == inviteId }) else {
                    self.logger.error("Received invite with ID \(inviteId) not found")
                    promise(.failure(FirebaseError.notFound))
                    return
                }

                let receivedInvite = receivedInvites[inviteIndex]

                // Now get the sender document to find the sent invite
                self.db.collection("users").document(senderId).getDocument { [weak self] (senderDoc, error) in
                    guard let self = self else {
                        promise(.failure(FirebaseError.unknown))
                        return
                    }

                    if let error = error {
                        self.logger.error(
                            "Error fetching sender document: \(error.localizedDescription, privacy: .public)"
                        )
                        promise(.failure(error))
                        return
                    }

                    guard let senderDoc = senderDoc, senderDoc.exists,
                          var sentInvites = senderDoc.data()?["sentInvites"] as? [[String: Any]] else {
                        self.logger.error("Sender document or sentInvites not found")
                        promise(.failure(FirebaseError.notFound))
                        return
                    }

                    // Find the matching sent invite
                    // Matching by inviteId which should be the same in both arrays
                    guard let sentInviteIndex = sentInvites.firstIndex(where: { ($0["uid"] as? String) == inviteId }) else {
                        self.logger.error("Sent invite with ID \(inviteId) not found")
                        promise(.failure(FirebaseError.notFound))
                        return
                    }

                    // Create a batch operation
                    let batch = self.db.batch()

                    // Update current user document - add friend and remove received invite
                    let currentUserRef = self.db.collection("users").document(currentUserId)
                    batch.updateData([
                        "friendIds": FieldValue.arrayUnion([senderId]),
                        "receivedInvites": FieldValue.arrayRemove([receivedInvite]),
                        "lastModified": FieldValue.serverTimestamp()
                    ], forDocument: currentUserRef)

                    // Update sender document - add friend and remove sent invite
                    let senderRef = self.db.collection("users").document(senderId)
                    batch.updateData([
                        "friendIds": FieldValue.arrayUnion([currentUserId]),
                        "sentInvites": FieldValue.arrayRemove([sentInvites[sentInviteIndex]]),
                        "lastModified": FieldValue.serverTimestamp()
                    ], forDocument: senderRef)

                    // Execute the batch
                    batch.commit { error in
                        if let error = error {
                            self.logger.error(
                                "Failed to accept invite: \(error.localizedDescription, privacy: .public)"
                            )
                            promise(.failure(error))
                        } else {
                            self.logger.info(
                                "Successfully accepted invite, added \(senderId) and \(currentUserId) as friends"
                            )
                            promise(.success(()))
                        }
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

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
    ) -> AnyPublisher<Void, Error> {
        logger.info("User \(currentUserId) declining invite \(inviteId) from \(senderId)")

        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FirebaseError.unknown))
                return
            }

            // Get current user document to find the received invite
            self.db.collection("users").document(currentUserId).getDocument { [weak self] (userDoc, error) in
                guard let self = self else {
                    promise(.failure(FirebaseError.unknown))
                    return
                }

                if let error = error {
                    self.logger.error(
                        "Error fetching user document: \(error.localizedDescription, privacy: .public)"
                    )
                    promise(.failure(error))
                    return
                }

                guard let userDoc = userDoc, userDoc.exists,
                      var receivedInvites = userDoc.data()?["receivedInvites"] as? [[String: Any]] else {
                    self.logger.error("User document or receivedInvites not found")
                    promise(.failure(FirebaseError.notFound))
                    return
                }

                // Find the invite in the receivedInvites array
                guard let inviteIndex = receivedInvites.firstIndex(where: { ($0["uid"] as? String) == inviteId }) else {
                    self.logger.error("Received invite with ID \(inviteId) not found")
                    promise(.failure(FirebaseError.notFound))
                    return
                }

                let receivedInvite = receivedInvites[inviteIndex]

                // Now get the sender document to find the sent invite
                self.db.collection("users").document(senderId).getDocument { [weak self] (senderDoc, error) in
                    guard let self = self else {
                        promise(.failure(FirebaseError.unknown))
                        return
                    }

                    if let error = error {
                        self.logger.error(
                            "Error fetching sender document: \(error.localizedDescription, privacy: .public)"
                        )
                        promise(.failure(error))
                        return
                    }

                    guard let senderDoc = senderDoc, senderDoc.exists,
                          var sentInvites = senderDoc.data()?["sentInvites"] as? [[String: Any]] else {
                        self.logger.error("Sender document or sentInvites not found")
                        promise(.failure(FirebaseError.notFound))
                        return
                    }

                    // Find the matching sent invite
                    // Matching by inviteId which should be the same in both arrays
                    guard let sentInviteIndex = sentInvites.firstIndex(where: { ($0["uid"] as? String) == inviteId }) else {
                        self.logger.error("Sent invite with ID \(inviteId) not found")
                        promise(.failure(FirebaseError.notFound))
                        return
                    }

                    // Create a batch operation
                    let batch = self.db.batch()

                    // Update current user document - remove received invite only (don't add friend)
                    let currentUserRef = self.db.collection("users").document(currentUserId)
                    batch.updateData([
                        "receivedInvites": FieldValue.arrayRemove([receivedInvite]),
                        "lastModified": FieldValue.serverTimestamp()
                    ], forDocument: currentUserRef)

                    // Update sender document - remove sent invite only (don't add friend)
                    let senderRef = self.db.collection("users").document(senderId)
                    batch.updateData([
                        "sentInvites": FieldValue.arrayRemove([sentInvites[sentInviteIndex]]),
                        "lastModified": FieldValue.serverTimestamp()
                    ], forDocument: senderRef)

                    // Execute the batch
                    batch.commit { error in
                        if let error = error {
                            self.logger.error(
                                "Failed to decline invite: \(error.localizedDescription, privacy: .public)"
                            )
                            promise(.failure(error))
                        } else {
                            self.logger.info(
                                "Successfully declined invite from \(senderId)")
                            promise(.success(()))
                        }
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Fetches all received invites for a user
    /// - Parameter userId: The ID of the user whose received invites to fetch
    /// - Returns: Publisher that emits an array of invite data or an error
    func fetchReceivedInvites(userId: String) -> AnyPublisher<[[String: Any]], Error> {
        logger.info("Fetching received invites for user \(userId)")

        return Future<[[String: Any]], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FirebaseError.unknown))
                return
            }

            self.db.collection("users").document(userId).getDocument { (document, error) in
                if let error = error {
                    self.logger.error(
                        "Error fetching user document: \(error.localizedDescription, privacy: .public)"
                    )
                    promise(.failure(error))
                    return
                }

                guard let document = document, document.exists else {
                    self.logger.error("User document not found")
                    promise(.failure(FirebaseError.notFound))
                    return
                }

                if let receivedInvites = document.data()?["receivedInvites"] as? [[String: Any]] {
                    self.logger.info("Fetched \(receivedInvites.count) received invites for user \(userId)")
                    promise(.success(receivedInvites))
                } else {
                    // Return empty array if no receivedInvites field or it's not an array
                    self.logger.info("No received invites found for user \(userId)")
                    promise(.success([]))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Fetches all sent invites for a user
    /// - Parameter userId: The ID of the user whose sent invites to fetch
    /// - Returns: Publisher that emits an array of invite data or an error
    func fetchSentInvites(userId: String) -> AnyPublisher<[[String: Any]], Error> {
        logger.info("Fetching sent invites for user \(userId)")

        return Future<[[String: Any]], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FirebaseError.unknown))
                return
            }

            self.db.collection("users").document(userId).getDocument { (document, error) in
                if let error = error {
                    self.logger.error(
                        "Error fetching user document: \(error.localizedDescription, privacy: .public)"
                    )
                    promise(.failure(error))
                    return
                }

                guard let document = document, document.exists else {
                    self.logger.error("User document not found")
                    promise(.failure(FirebaseError.notFound))
                    return
                }

                if let sentInvites = document.data()?["sentInvites"] as? [[String: Any]] {
                    self.logger.info("Fetched \(sentInvites.count) sent invites for user \(userId)")
                    promise(.success(sentInvites))
                } else {
                    // Return empty array if no sentInvites field or it's not an array
                    self.logger.info("No sent invites found for user \(userId)")
                    promise(.success([]))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
