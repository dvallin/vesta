import Foundation
import SwiftData

@Model
class User: SyncableEntity {
    @Attribute(.unique) var uid: String

    var email: String?
    var displayName: String?
    var photoURL: String?
    var isEmailVerified: Bool
    var createdAt: Date
    var lastSignInAt: Date

    @Relationship(deleteRule: .noAction)
    var friends: [User] = []
    @Relationship(deleteRule: .cascade)
    var receivedInvites: [Invite] = []
    @Relationship(deleteRule: .cascade)
    var sentInvites: [Invite] = []

    var shareMeals: Bool? = false
    var shareShoppingItems: Bool? = false
    var shareTodoItemCategories: [TodoItemCategory] = []
    var isOnHoliday: Bool = false
    var holidayStartDate: Date?

    @Relationship(deleteRule: .noAction)
    var owner: User? = nil

    var isShared: Bool = false
    var dirty: Bool = true

    init(
        uid: String, email: String? = nil, displayName: String? = nil,
        photoURL: String? = nil, isEmailVerified: Bool = false, createdAt: Date = Date(),
        lastSignInAt: Date = Date(),
        isOnHoliday: Bool = false,
        holidayStartDate: Date? = nil
    ) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.isEmailVerified = isEmailVerified
        self.createdAt = createdAt
        self.lastSignInAt = lastSignInAt
        self.isOnHoliday = isOnHoliday
        self.holidayStartDate = holidayStartDate
    }
}

@Model
class Invite {
    @Relationship(deleteRule: .noAction)
    var owner: User?

    var uid: String
    var createdAt: Date

    // Sender information
    var senderUid: String
    var senderEmail: String?
    var senderDisplayName: String?
    var senderPhotoURL: String?

    // Recipient information
    var recipientUid: String
    var recipientEmail: String?
    var recipientDisplayName: String?
    var recipientPhotoURL: String?

    init(
        uid: String,
        createdAt: Date,
        senderUid: String,
        recipientUid: String,
        senderEmail: String? = nil,
        senderDisplayName: String? = nil,
        senderPhotoURL: String? = nil,
        recipientEmail: String? = nil,
        recipientDisplayName: String? = nil,
        recipientPhotoURL: String? = nil
    ) {
        self.uid = uid
        self.createdAt = createdAt
        self.senderUid = senderUid
        self.recipientUid = recipientUid
        self.senderEmail = senderEmail
        self.senderDisplayName = senderDisplayName
        self.senderPhotoURL = senderPhotoURL
        self.recipientEmail = recipientEmail
        self.recipientDisplayName = recipientDisplayName
        self.recipientPhotoURL = recipientPhotoURL
    }
}
