import Foundation
import SwiftData

enum TodoItemEventType: String, Codable {
    case markAsDone
    case edit
}

@Model
class TodoItemEvent {
    var type: TodoItemEventType
    var date: Date

    var snapshotTitle: String
    var snapshotDetails: String
    var snapshotDueDate: Date?
    var snapshotIsCompleted: Bool
    var snapshotRecurrenceFrequency: RecurrenceFrequency?
    var snapshotRecurrenceType: RecurrenceType?

    @Relationship(inverse: \TodoItem.events)
    var todoItem: TodoItem?

    init(type: TodoItemEventType, date: Date, todoItem: TodoItem) {
        self.type = type
        self.date = date
        self.todoItem = todoItem

        self.snapshotTitle = todoItem.title
        self.snapshotDetails = todoItem.details
        self.snapshotDueDate = todoItem.dueDate
        self.snapshotIsCompleted = todoItem.isCompleted
        self.snapshotRecurrenceFrequency = todoItem.recurrenceFrequency
        self.snapshotRecurrenceType = todoItem.recurrenceType
    }
}
