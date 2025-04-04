import Foundation
import SwiftData

@Model
final class Space: SyncableEntity {
    var id: UUID = UUID()
    var name: String

    @Relationship(deleteRule: .noAction, inverse: \User.spaces)
    var members: [User] = []

    var shareAllRecipes: Bool = true
    var shareAllMeals: Bool = true
    var shareAllShoppingItems: Bool = true

    var sharedCategories: [TodoItemCategory] = []

    @Relationship(deleteRule: .noAction)
    var owner: User?

    var lastModified: Date = Date()
    var dirty: Bool = true

    init(name: String, owner: User) {
        self.name = name
        self.owner = owner
        self.lastModified = Date()
        self.dirty = true
    }
}
