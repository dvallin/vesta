import Foundation
import SwiftData

enum TodoItemEventType: String, Codable {
    case markAsDone
    case editTitle
    case editDetails
    case editDueDate
    case editRecurrenceFrequency
    case editRecurrenceType
    case editIsCompleted
}

@Model
class TodoItemEvent {
    var type: TodoItemEventType
    var date: Date

    var previousTitle: String?
    var previousDetails: String?
    var previousDueDate: Date?
    var previousIsCompleted: Bool?
    var previousRecurrenceFrequency: RecurrenceFrequency?
    var previousRecurrenceType: RecurrenceType?

    @Relationship(inverse: \TodoItem.events)
    var todoItem: TodoItem?

    init(
        type: TodoItemEventType, date: Date, todoItem: TodoItem, previousTitle: String? = nil,
        previousDetails: String? = nil, previousDueDate: Date? = nil,
        previousIsCompleted: Bool? = nil, previousRecurrenceFrequency: RecurrenceFrequency? = nil,
        previousRecurrenceType: RecurrenceType? = nil
    ) {
        self.type = type
        self.date = date
        self.todoItem = todoItem

        self.previousTitle = previousTitle
        self.previousDetails = previousDetails
        self.previousDueDate = previousDueDate
        self.previousIsCompleted = previousIsCompleted
        self.previousRecurrenceFrequency = previousRecurrenceFrequency
        self.previousRecurrenceType = previousRecurrenceType
    }
}
