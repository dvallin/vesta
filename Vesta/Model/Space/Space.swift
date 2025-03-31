import Foundation
import SwiftData

@Model
final class Space: SyncableEntity {
    var id: UUID = UUID()
    var name: String

    var members: [User] = []

    var shareAllRecipes: Bool = true
    var shareAllMeals: Bool = true
    var shareAllShoppingItems: Bool = true

    var sharedCategories: [TodoItemCategory] = []

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
