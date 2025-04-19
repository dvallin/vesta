import Foundation
import SwiftData

@Model
final class Space: SyncableEntity {
    @Attribute(.unique) var uid: String?

    @Relationship(deleteRule: .noAction)
    var lastModifiedBy: User?

    var name: String

    @Relationship(deleteRule: .noAction, inverse: \User.spaces)
    var members: [User] = []

    var shareAllRecipes: Bool = true
    var shareAllMeals: Bool = true
    var shareAllShoppingItems: Bool = true

    @Relationship
    var sharedCategories: [TodoItemCategory] = []

    @Relationship(deleteRule: .noAction)
    var owner: User?

    var dirty: Bool = true

    init(name: String, owner: User?) {
        self.uid = UUID().uuidString
        self.name = name
        self.owner = owner
        self.dirty = true
    }
}
