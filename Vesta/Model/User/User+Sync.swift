import Foundation
import SwiftData

extension User {
    /// Converts the User entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "User",
            "uid": uid,
            "ownerId": uid,
            "isShared": isShared,

            "isEmailVerified": isEmailVerified,
            "createdAt": createdAt,
            "lastSignInAt": lastSignInAt,
        ]

        // Add optional properties
        if let email = email {
            dto["email"] = email
        }

        if let displayName = displayName {
            dto["displayName"] = displayName
        }

        if let photoURL = photoURL {
            dto["photoURL"] = photoURL
        }

        dto["friendIds"] = friends.compactMap { $0.uid }
        dto["receivedInvites"] = receivedInvites.map { $0.toDTO() }
        dto["sentInvites"] = sentInvites.map { $0.toDTO() }

        return dto
    }

    func update(from data: [String: Any]) {
        self.isShared = data["isShared"] as? Bool ?? false

        if let isEmailVerified = data["isEmailVerified"] as? Bool {
            self.isEmailVerified = isEmailVerified
        }

        if let createdAt = data["createdAt"] as? Date {
            self.createdAt = createdAt
        }

        if let lastSignInAt = data["lastSignInAt"] as? Date {
            self.lastSignInAt = lastSignInAt
        }

        if let email = data["email"] as? String {
            self.email = email
        }

        if let displayName = data["displayName"] as? String {
            self.displayName = displayName
        }

        if let photoURL = data["photoURL"] as? String {
            self.photoURL = photoURL
        }
        
        // Process received invites
        if let receivedInvitesData = data["receivedInvites"] as? [[String: Any]] {
            // Remove existing received invites
            self.receivedInvites.removeAll()
            
            // Add new received invites
            for inviteData in receivedInvitesData {
                if let invite = Invite.fromDTO(inviteData, owner: self) {
                    self.receivedInvites.append(invite)
                }
            }
        }
        
        // Process sent invites
        if let sentInvitesData = data["sentInvites"] as? [[String: Any]] {
            // Remove existing sent invites
            self.sentInvites.removeAll()
            
            // Add new sent invites
            for inviteData in sentInvitesData {
                if let invite = Invite.fromDTO(inviteData, owner: self) {
                    self.sentInvites.append(invite)
                }
            }
        }
    }
}

extension Invite {
    /// Converts the Invite entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "uid": uid,
            "createdAt": createdAt,
            "senderUid": senderUid,
            "recipientUid": recipientUid,
        ]

        // Add optional sender properties
        if let senderEmail = senderEmail {
            dto["senderEmail"] = senderEmail
        }
        
        if let senderDisplayName = senderDisplayName {
            dto["senderDisplayName"] = senderDisplayName
        }
        
        if let senderPhotoURL = senderPhotoURL {
            dto["senderPhotoURL"] = senderPhotoURL
        }
        
        // Add optional recipient properties
        if let recipientEmail = recipientEmail {
            dto["recipientEmail"] = recipientEmail
        }
        
        if let recipientDisplayName = recipientDisplayName {
            dto["recipientDisplayName"] = recipientDisplayName
        }
        
        if let recipientPhotoURL = recipientPhotoURL {
            dto["recipientPhotoURL"] = recipientPhotoURL
        }

        return dto
    }
    
    /// Creates an Invite instance from a DTO (Data Transfer Object)
    /// - Parameters:
    ///   - data: Dictionary containing invite data
    ///   - owner: The user to associate this invite with
    /// - Returns: A new Invite instance, or nil if required data is missing
    static func fromDTO(_ data: [String: Any], owner: User?) -> Invite? {
        guard let uid = data["uid"] as? String,
              let senderUid = data["senderUid"] as? String,
              let recipientUid = data["recipientUid"] as? String else { 
            return nil 
        }
        
        let createdAt = data["createdAt"] as? Date ?? Date()
        
        // Get sender information
        let senderEmail = data["senderEmail"] as? String
        let senderDisplayName = data["senderDisplayName"] as? String
        let senderPhotoURL = data["senderPhotoURL"] as? String
        
        // Get recipient information
        let recipientEmail = data["recipientEmail"] as? String
        let recipientDisplayName = data["recipientDisplayName"] as? String
        let recipientPhotoURL = data["recipientPhotoURL"] as? String
        
        let invite = Invite(
            uid: uid,
            createdAt: createdAt,
            senderUid: senderUid,
            recipientUid: recipientUid,
            senderEmail: senderEmail,
            senderDisplayName: senderDisplayName,
            senderPhotoURL: senderPhotoURL,
            recipientEmail: recipientEmail,
            recipientDisplayName: recipientDisplayName,
            recipientPhotoURL: recipientPhotoURL
        )
        invite.owner = owner
        
        return invite
    }
}
