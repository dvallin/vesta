import Foundation
import SwiftData

extension User {
    /// Converts the User entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "User",
            "id": id,
            "lastModified": lastModified.timeIntervalSince1970,

            "uid": uid,
            "isEmailVerified": isEmailVerified,
            "createdAt": createdAt.timeIntervalSince1970,
            "lastSignInAt": lastSignInAt.timeIntervalSince1970,
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

}
