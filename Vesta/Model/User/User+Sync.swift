import Foundation
import SwiftData

extension User {
    /// Converts the User entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "User",
            "uid": uid,
            "lastModified": lastModified,

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

}
