import Foundation
import SwiftData

@Model
class TodoItemCategory {
    var name: String

    @Relationship(inverse: \TodoItem.category)
    var todoItems: [TodoItem]

    init(name: String) {
        self.name = name
        self.todoItems = []
    }
}
