import Foundation
import SwiftData

@Model
class TodoItemCategory {
    var name: String

    @Relationship(inverse: \TodoItem.category)
    var todoItems: [TodoItem]

    @Relationship(inverse: \Space.sharedCategories)
    var spaces: [Space] = []

    init(name: String) {
        self.name = name
        self.todoItems = []
    }
}
