import Foundation
import SwiftData

@Model
class TodoItemCategory {
    var name: String
    var color: String?
    var isFreezable: Bool = false

    @Relationship(inverse: \TodoItem.category)
    var todoItems: [TodoItem]

    init(name: String, color: String? = nil, isFreezable: Bool = false) {
        self.name = name
        self.color = color
        self.isFreezable = isFreezable
        self.todoItems = []
    }
}
