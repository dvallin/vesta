import Foundation
import SwiftData

extension User {
    /// Converts the User entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "User",
            "uid": uid,
            "ownerId": uid,
            "lastModifiedBy": uid,

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

        return dto
    }

    func update(from data: [String: Any]) {
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
    }
}
