import Foundation
import SwiftData

@Model
class User: SyncableEntity {
    @Attribute(.unique) var uid: String?

    var email: String?
    var displayName: String?
    var photoURL: String?
    var isEmailVerified: Bool
    var createdAt: Date
    var lastSignInAt: Date

    @Relationship(deleteRule: .noAction)
    var friends: [User] = []

    var shareMeals: Bool? = false
    var shareShoppingItems: Bool? = false
    var shareTodoItemCategories: [TodoItemCategory] = []

    @Relationship(deleteRule: .noAction)
    var owner: User? = nil

    var isShared: Bool = false
    var dirty: Bool = true

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
