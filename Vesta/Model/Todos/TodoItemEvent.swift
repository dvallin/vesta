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
    case editIgnoreTimeComponent
    case editRecurrenceInterval

    var displayName: String {
        switch self {
        case .markAsDone:
            return NSLocalizedString("Mark as Done", comment: "Mark as Done event")
        case .editTitle:
            return NSLocalizedString("Edit Title", comment: "Edit Title event")
        case .editDetails:
            return NSLocalizedString("Edit Details", comment: "Edit Details event")
        case .editDueDate:
            return NSLocalizedString("Edit Due Date", comment: "Edit Due Date event")
        case .editRecurrenceFrequency:
            return NSLocalizedString(
                "Edit Recurrence Frequency", comment: "Edit Recurrence Frequency event")
        case .editRecurrenceType:
            return NSLocalizedString("Edit Recurrence Type", comment: "Edit Recurrence Type event")
        case .editIsCompleted:
            return NSLocalizedString("Edit Is Completed", comment: "Edit Is Completed event")
        case .editIgnoreTimeComponent:
            return NSLocalizedString(
                "Edit Ignore Time Component", comment: "Edit Ignore Time Component event")
        case .editRecurrenceInterval:
            return NSLocalizedString(
                "Edit Recurrence Interval", comment: "Edit Recurrence Interval event")
        }
    }
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
    var previousRecurrenceInterval: Int?
    var previousIgnoreTimeComponent: Bool?

    @Relationship(inverse: \TodoItem.events)
    var todoItem: TodoItem?

    init(
        type: TodoItemEventType, date: Date, todoItem: TodoItem, previousTitle: String? = nil,
        previousDetails: String? = nil, previousDueDate: Date? = nil,
        previousIsCompleted: Bool? = nil, previousRecurrenceFrequency: RecurrenceFrequency? = nil,
        previousRecurrenceType: RecurrenceType? = nil, previousRecurrenceInterval: Int? = nil,
        previousIgnoreTimeComponent: Bool? = nil
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
        self.previousRecurrenceInterval = previousRecurrenceInterval
        self.previousIgnoreTimeComponent = previousIgnoreTimeComponent
    }
}
