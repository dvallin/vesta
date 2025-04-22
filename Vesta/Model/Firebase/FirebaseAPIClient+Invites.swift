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
            
            // Create invite ID - combine sender and recipient IDs with timestamp to ensure uniqueness
            let timestamp = Date().timeIntervalSince1970
            let sentInviteId = "\(currentUserId)_to_\(recipientId)_\(timestamp)"
            let receivedInviteId = "\(recipientId)_from_\(currentUserId)_\(timestamp)"
            
            // Prepare invite data for the recipient (contains sender info)
            var sentInviteData: [String: Any] = [
                "uid": sentInviteId,
                "createdAt": FieldValue.serverTimestamp(),
                "lastModified": FieldValue.serverTimestamp()
            ]
            
            // Add recipient data to sent invite
            if let email = recipientData["email"] as? String {
                sentInviteData["email"] = email
            }
            
            if let displayName = recipientData["displayName"] as? String {
                sentInviteData["displayName"] = displayName
            }
            
            if let photoURL = recipientData["photoURL"] as? String {
                sentInviteData["photoURL"] = photoURL
            }
            
            // Prepare invite data for the sender (contains recipient info)
            var receivedInviteData: [String: Any] = [
                "uid": receivedInviteId,
                "createdAt": FieldValue.serverTimestamp(),
                "lastModified": FieldValue.serverTimestamp()
            ]
            
            // Add sender data to received invite
            if let email = currentUserData["email"] as? String {
                receivedInviteData["email"] = email
            }
            
            if let displayName = currentUserData["displayName"] as? String {
                receivedInviteData["displayName"] = displayName
            }
            
            if let photoURL = currentUserData["photoURL"] as? String {
                receivedInviteData["photoURL"] = photoURL
            }
            
            // Add invite to sender's sent invites
            let sentInviteRef = self.db.collection("users").document(currentUserId)
                .collection("sentInvites").document(sentInviteId)
            
            // Add invite to recipient's received invites
            let receivedInviteRef = self.db.collection("users").document(recipientId)
                .collection("receivedInvites").document(receivedInviteId)
            
            // Add both operations to the batch
            batch.setData(sentInviteData, forDocument: sentInviteRef)
            batch.setData(receivedInviteData, forDocument: receivedInviteRef)
            
            // Execute the batch
            batch.commit { error in
                if let error = error {
                    self.logger.error("Failed to send invite: \(error.localizedDescription, privacy: .public)")
                    promise(.failure(error))
                } else {
                    self.logger.info("Successfully sent invite from \(currentUserId) to \(recipientId)")
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
            
            let batch = self.db.batch()
            
            // 1. Get the sent invite ID from the received invite
            self.db.collection("users").document(currentUserId)
                .collection("receivedInvites").document(inviteId)
                .getDocument { [weak self] (document, error) in
                    guard let self = self else {
                        promise(.failure(FirebaseError.unknown))
                        return
                    }
                    
                    if let error = error {
                        self.logger.error("Error fetching invite: \(error.localizedDescription, privacy: .public)")
                        promise(.failure(error))
                        return
                    }
                    
                    guard let document = document, document.exists else {
                        self.logger.error("Invite not found")
                        promise(.failure(FirebaseError.notFound))
                        return
                    }
                    
                    // Extract the original sent invite ID by reversing the pattern
                    // Assuming we can find the matching sent invite by looking at all sent invites from sender
                    self.db.collection("users").document(senderId)
                        .collection("sentInvites")
                        .whereField("email", isEqualTo: document.data()?["email"] as? String ?? "")
                        .getDocuments { [weak self] (snapshot, error) in
                            guard let self = self else {
                                promise(.failure(FirebaseError.unknown))
                                return
                            }
                            
                            if let error = error {
                                self.logger.error("Error finding matching sent invite: \(error.localizedDescription, privacy: .public)")
                                promise(.failure(error))
                                return
                            }
                            
                            guard let documents = snapshot?.documents, !documents.isEmpty else {
                                self.logger.error("No matching sent invite found")
                                promise(.failure(FirebaseError.notFound))
                                return
                            }
                            
                            // Find the sent invite that matches this received invite
                            let sentInviteId = documents[0].documentID
                            
                            // Create a batch operation
                            let newBatch = self.db.batch()
                            
                            // 2. Update each user's friends list
                            // Add sender to recipient's friends
                            let currentUserRef = self.db.collection("users").document(currentUserId)
                            newBatch.updateData([
                                "friendIds": FieldValue.arrayUnion([senderId]),
                                "lastModified": FieldValue.serverTimestamp()
                            ], forDocument: currentUserRef)
                            
                            // Add recipient to sender's friends
                            let senderRef = self.db.collection("users").document(senderId)
                            newBatch.updateData([
                                "friendIds": FieldValue.arrayUnion([currentUserId]),
                                "lastModified": FieldValue.serverTimestamp()
                            ], forDocument: senderRef)
                            
                            // 3. Delete the invites
                            // Delete from sender's sent invites
                            let sentInviteRef = self.db.collection("users").document(senderId)
                                .collection("sentInvites").document(sentInviteId)
                            newBatch.deleteDocument(sentInviteRef)
                            
                            // Delete from recipient's received invites
                            let receivedInviteRef = self.db.collection("users").document(currentUserId)
                                .collection("receivedInvites").document(inviteId)
                            newBatch.deleteDocument(receivedInviteRef)
                            
                            // Execute the batch
                            newBatch.commit { error in
                                if let error = error {
                                    self.logger.error("Failed to accept invite: \(error.localizedDescription, privacy: .public)")
                                    promise(.failure(error))
                                } else {
                                    self.logger.info("Successfully accepted invite, added \(senderId) and \(currentUserId) as friends")
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
            
            // Similar process as acceptInvite but we only delete the invites
            let batch = self.db.batch()
            
            // 1. Get the sent invite ID from the received invite
            self.db.collection("users").document(currentUserId)
                .collection("receivedInvites").document(inviteId)
                .getDocument { [weak self] (document, error) in
                    guard let self = self else {
                        promise(.failure(FirebaseError.unknown))
                        return
                    }
                    
                    if let error = error {
                        self.logger.error("Error fetching invite: \(error.localizedDescription, privacy: .public)")
                        promise(.failure(error))
                        return
                    }
                    
                    guard let document = document, document.exists else {
                        self.logger.error("Invite not found")
                        promise(.failure(FirebaseError.notFound))
                        return
                    }
                    
                    // Extract the original sent invite ID by finding matching invite
                    self.db.collection("users").document(senderId)
                        .collection("sentInvites")
                        .whereField("email", isEqualTo: document.data()?["email"] as? String ?? "")
                        .getDocuments { [weak self] (snapshot, error) in
                            guard let self = self else {
                                promise(.failure(FirebaseError.unknown))
                                return
                            }
                            
                            if let error = error {
                                self.logger.error("Error finding matching sent invite: \(error.localizedDescription, privacy: .public)")
                                promise(.failure(error))
                                return
                            }
                            
                            guard let documents = snapshot?.documents, !documents.isEmpty else {
                                self.logger.error("No matching sent invite found")
                                promise(.failure(FirebaseError.notFound))
                                return
                            }
                            
                            // Find the sent invite that matches this received invite
                            let sentInviteId = documents[0].documentID
                            
                            // Create a batch operation
                            let newBatch = self.db.batch()
                            
                            // Delete from sender's sent invites
                            let sentInviteRef = self.db.collection("users").document(senderId)
                                .collection("sentInvites").document(sentInviteId)
                            newBatch.deleteDocument(sentInviteRef)
                            
                            // Delete from recipient's received invites
                            let receivedInviteRef = self.db.collection("users").document(currentUserId)
                                .collection("receivedInvites").document(inviteId)
                            newBatch.deleteDocument(receivedInviteRef)
                            
                            // Execute the batch
                            newBatch.commit { error in
                                if let error = error {
                                    self.logger.error("Failed to decline invite: \(error.localizedDescription, privacy: .public)")
                                    promise(.failure(error))
                                } else {
                                    self.logger.info("Successfully declined invite from \(senderId)")
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
            
            self.db.collection("users").document(userId).collection("receivedInvites")
                .getDocuments { (snapshot, error) in
                    if let error = error {
                        self.logger.error("Error fetching received invites: \(error.localizedDescription, privacy: .public)")
                        promise(.failure(error))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        promise(.success([]))
                        return
                    }
                    
                    let invites = documents.map { document -> [String: Any] in
                        var data = document.data()
                        data["uid"] = document.documentID
                        return data
                    }
                    
                    self.logger.info("Fetched \(invites.count) received invites for user \(userId)")
                    promise(.success(invites))
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
            
            self.db.collection("users").document(userId).collection("sentInvites")
                .getDocuments { (snapshot, error) in
                    if let error = error {
                        self.logger.error("Error fetching sent invites: \(error.localizedDescription, privacy: .public)")
                        promise(.failure(error))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        promise(.success([]))
                        return
                    }
                    
                    let invites = documents.map { document -> [String: Any] in
                        var data = document.data()
                        data["uid"] = document.documentID
                        return data
                    }
                    
                    self.logger.info("Fetched \(invites.count) sent invites for user \(userId)")
                    promise(.success(invites))
                }
        }
        .eraseToAnyPublisher()
    }
}