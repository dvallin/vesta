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
            "isOnHoliday": isOnHoliday,
            "deletedAt": deletedAt as Any,
            "expireAt": expireAt as Any,
        ]

        // Add optional properties (always include to ensure nil values are synced)
        dto["holidayStartDate"] = holidayStartDate as Any
        dto["email"] = email as Any
        dto["displayName"] = displayName as Any
        dto["photoURL"] = photoURL as Any

        dto["friendIds"] = friends.compactMap { $0.uid }
        dto["receivedInvites"] = receivedInvites.map { $0.toDTO() }
        dto["sentInvites"] = sentInvites.map { $0.toDTO() }

        return dto
    }

    func update(from data: [String: Any]) {
        // Handle deletedAt - can be nil when restored
        if data.keys.contains("deletedAt") {
            self.deletedAt = data["deletedAt"] as? Date
        }
        // Handle expireAt - can be nil when restored
        if data.keys.contains("expireAt") {
            self.expireAt = data["expireAt"] as? Date
        }
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

        if data.keys.contains("email") {
            self.email = data["email"] as? String
        }

        if data.keys.contains("displayName") {
            self.displayName = data["displayName"] as? String
        }

        if data.keys.contains("photoURL") {
            self.photoURL = data["photoURL"] as? String
        }

        if let isOnHoliday = data["isOnHoliday"] as? Bool {
            self.isOnHoliday = isOnHoliday
        }

        if data.keys.contains("holidayStartDate") {
            if let holidayStartDate = data["holidayStartDate"] as? Date {
                self.holidayStartDate = holidayStartDate
            } else if self.isOnHoliday {
                // If on holiday but no start date, use current date
                self.holidayStartDate = Date()
            } else {
                // Clear holiday start date when not on holiday
                self.holidayStartDate = nil
            }
        }

        // Process received invites
        self.receivedInvites.removeAll()
        if let receivedInvitesData = data["receivedInvites"] as? [[String: Any]] {
            for inviteData in receivedInvitesData {
                if let invite = Invite.fromDTO(inviteData, owner: self) {
                    self.receivedInvites.append(invite)
                }
            }
        }

        // Process sent invites
        self.sentInvites.removeAll()
        if let sentInvitesData = data["sentInvites"] as? [[String: Any]] {
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

        // Add optional properties (always include to ensure nil values are synced)
        dto["senderEmail"] = senderEmail as Any
        dto["senderDisplayName"] = senderDisplayName as Any
        dto["senderPhotoURL"] = senderPhotoURL as Any
        dto["recipientEmail"] = recipientEmail as Any
        dto["recipientDisplayName"] = recipientDisplayName as Any
        dto["recipientPhotoURL"] = recipientPhotoURL as Any

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
            let recipientUid = data["recipientUid"] as? String
        else {
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
