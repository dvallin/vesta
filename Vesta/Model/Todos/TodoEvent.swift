import Foundation
import SwiftData

enum TodoEventType: String, Codable, CaseIterable {
    case completed
    case skipped
}

@Model
class TodoEvent {
    @Attribute(.unique) var uid: String
    var eventType: TodoEventType
    var completedAt: Date
    var previousDueDate: Date?
    var previousRescheduleDate: Date?

    @Relationship(inverse: \TodoItem.events)
    var todoItem: TodoItem?

    init(
        eventType: TodoEventType,
        completedAt: Date,
        todoItem: TodoItem?,
        previousDueDate: Date?,
        previousRescheduleDate: Date?
    ) {
        self.uid = UUID().uuidString
        self.eventType = eventType
        self.completedAt = completedAt
        self.todoItem = todoItem
        self.previousDueDate = previousDueDate
        self.previousRescheduleDate = previousRescheduleDate
    }
}
