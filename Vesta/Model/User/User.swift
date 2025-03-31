import Foundation
import SwiftData

@Model
class User {
    var uid: String
    var email: String?
    var displayName: String?
    var photoURL: String?
    var isEmailVerified: Bool
    var createdAt: Date
    var lastSignInAt: Date

    var dirty: Bool = false
    var lastModified: Date = Date()

    init(
        uid: String, email: String? = nil, displayName: String? = nil,
        photoURL: String? = nil, isEmailVerified: Bool = false, createdAt: Date = Date(),
        lastSignInAt: Date = Date()
    ) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.isEmailVerified = isEmailVerified
        self.createdAt = createdAt
        self.lastSignInAt = lastSignInAt
    }
}
