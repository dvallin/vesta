import Foundation
import SwiftData

@Model
class TodoItemCategory {
    var name: String
    var color: String?

    @Relationship(inverse: \TodoItem.category)
    var todoItems: [TodoItem]

    init(name: String, color: String? = nil) {
        self.name = name
        self.color = color
        self.todoItems = []
    }
}
