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
                        "Successfully sent invite from \(invite.senderUid) to \(invite.recipientUid)"
                    )
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
        logger.info(
            "User \(invite.recipientUid) accepting invite \(invite.uid) from \(invite.senderUid)")

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

        logger.info(
            "User \(invite.recipientUid) declining invite \(invite.uid) from \(invite.senderUid)")

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
}
