import Combine
import FirebaseFirestore
import Foundation
import os

// MARK: - Invite Management Extension
extension FirebaseAPIClient: InviteAPIClient {
    /// Sends an invite to another user
    /// - Parameter invite: The invite object to be sent
    /// - Returns: Publisher that emits void on success or an error
    func sendInvite(_ invite: Invite) -> AnyPublisher<Void, Error> {
        logger.info("Sending invite from user \(invite.senderUid) to user \(invite.recipientUid)")

        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FirebaseError.unknown))
                return
            }

            let batch = self.db.batch()
            // Add the invite to each user's document
            let senderRef = self.db.collection("users").document(invite.senderUid)
            let recipientRef = self.db.collection("users").document(invite.recipientUid)

            let dto = invite.toDTO()
            batch.updateData(
                [
                    "sentInvites": FieldValue.arrayUnion([dto]),
                    "lastModified": FieldValue.serverTimestamp(),
                ], forDocument: senderRef)
            batch.updateData(
                [
                    "receivedInvites": FieldValue.arrayUnion([dto]),
                    "lastModified": FieldValue.serverTimestamp(),
                ], forDocument: recipientRef)

            batch.commit { error in
                if let error = error {
                    self.logger.error(
                        "Failed to send invite: \(error.localizedDescription, privacy: .public)")
                    promise(.failure(error))
                } else {
                    self.logger.info(
                        "Successfully sent invite from \(invite.senderUid) to \(invite.recipientUid)")
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Accepts an invite from another user (only the recipient can accept)
    /// - Parameter invite: The invite object to be accepted
    /// - Returns: Publisher that emits void on success or an error
    func acceptInvite(_ invite: Invite) -> AnyPublisher<Void, Error> {
        logger.info("User \(invite.recipientUid) accepting invite \(invite.uid) from \(invite.senderUid)")

        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FirebaseError.unknown))
                return
            }

            // Create a batch operation
            let batch = self.db.batch()
            let dto = invite.toDTO()

            // Update recipient document - add friend and remove received invite
            let recipientRef = self.db.collection("users").document(invite.recipientUid)
            batch.updateData(
                [
                    "friendIds": FieldValue.arrayUnion([invite.senderUid]),
                    "receivedInvites": FieldValue.arrayRemove([dto]),
                    "lastModified": FieldValue.serverTimestamp(),
                ], forDocument: recipientRef)

            // Update sender document - add friend and remove sent invite
            let senderRef = self.db.collection("users").document(invite.senderUid)
            batch.updateData(
                [
                    "friendIds": FieldValue.arrayUnion([invite.recipientUid]),
                    "sentInvites": FieldValue.arrayRemove([dto]),
                    "lastModified": FieldValue.serverTimestamp(),
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
                        "Successfully accepted invite, added \(invite.senderUid) and \(invite.recipientUid) as friends"
                    )
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Declines an invite from another user (only the recipient can decline)
    /// - Parameter invite: The invite object to be declined
    /// - Returns: Publisher that emits void on success or an error
    func declineInvite(_ invite: Invite) -> AnyPublisher<Void, Error> {
        
        logger.info("User \(invite.recipientUid) declining invite \(invite.uid) from \(invite.senderUid)")

        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FirebaseError.unknown))
                return
            }
            
            // Create a batch operation
            let batch = self.db.batch()
            let dto = invite.toDTO()

            // Update recipient document - remove received invite
            let recipientRef = self.db.collection("users").document(invite.recipientUid)
            batch.updateData(
                [
                    "receivedInvites": FieldValue.arrayRemove([dto]),
                    "lastModified": FieldValue.serverTimestamp(),
                ], forDocument: recipientRef)

            // Update sender document - remove sent invite
            let senderRef = self.db.collection("users").document(invite.senderUid)
            batch.updateData(
                [
                    "sentInvites": FieldValue.arrayRemove([dto]),
                    "lastModified": FieldValue.serverTimestamp(),
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
                        "Successfully declined invite from \(invite.senderUid)"
                    )
                    promise(.success(()))
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
                    self.logger.info(
                        "Fetched \(receivedInvites.count) received invites for user \(userId)")
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
