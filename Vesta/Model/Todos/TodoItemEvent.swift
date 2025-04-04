import Foundation
import SwiftData

enum TodoItemEventType: String, Codable {
    case created
    case markAsDone
    case editTitle
    case editDetails
    case editDueDate
    case editRecurrenceFrequency
    case editRecurrenceType
    case editIsCompleted
    case editIgnoreTimeComponent
    case editRecurrenceInterval
    case editPriority
    case editCategory

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
        case .editPriority:
            return NSLocalizedString(
                "Edit Priority", comment: "Edit Priority event")
        case .editCategory:
            return NSLocalizedString(
                "Edit Category", comment: "Edit Category event")
        case .created:
            return NSLocalizedString(
                "Created Todo Item", comment: "Created Todo Item event")
        }
    }
}

@Model
class TodoItemEvent: SyncableEntity {
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
    var previousPriority: Int?
    var previousCategory: String?

    @Relationship(deleteRule: .noAction)
    var owner: User?

    @Relationship
    var spaces: [Space]

    var lastModified: Date = Date()
    var dirty: Bool = true

    @Relationship
    var todoItem: TodoItem?

    init(
        type: TodoItemEventType, date: Date, owner: User, todoItem: TodoItem,
        previousTitle: String? = nil, previousDetails: String? = nil, previousDueDate: Date? = nil,
        previousIsCompleted: Bool? = nil, previousRecurrenceFrequency: RecurrenceFrequency? = nil,
        previousRecurrenceType: RecurrenceType? = nil, previousRecurrenceInterval: Int? = nil,
        previousIgnoreTimeComponent: Bool? = nil, previousPriority: Int? = nil,
        previousCategory: String? = nil
    ) {
        self.type = type
        self.date = date
        self.owner = owner
        self.todoItem = todoItem
        self.spaces = []

        self.previousTitle = previousTitle
        self.previousDetails = previousDetails
        self.previousDueDate = previousDueDate
        self.previousIsCompleted = previousIsCompleted
        self.previousRecurrenceFrequency = previousRecurrenceFrequency
        self.previousRecurrenceType = previousRecurrenceType
        self.previousRecurrenceInterval = previousRecurrenceInterval
        self.previousIgnoreTimeComponent = previousIgnoreTimeComponent
        self.previousPriority = previousPriority
        self.previousCategory = previousCategory
    }
}
