import Foundation
import SwiftData

extension TodoItemEvent {
    /// Converts the TodoItemEvent entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "TodoItemEvent",
            "uid": uid,
            "ownerId": owner?.uid ?? "",
            "lastModifiedBy": lastModifiedBy?.uid,

            "type": type.rawValue,
            "date": date,
        ]

        // Add parent todo item reference
        if let todoItemId = todoItem?.uid {
            dto["todoItemId"] = todoItemId
        }

        // Add optional previous values
        if let previousTitle = previousTitle {
            dto["previousTitle"] = previousTitle
        }

        if let previousDetails = previousDetails {
            dto["previousDetails"] = previousDetails
        }

        if let previousDueDate = previousDueDate {
            dto["previousDueDate"] = previousDueDate
        }

        if let previousIsCompleted = previousIsCompleted {
            dto["previousIsCompleted"] = previousIsCompleted
        }

        if let previousRecurrenceFrequency = previousRecurrenceFrequency {
            dto["previousRecurrenceFrequency"] = previousRecurrenceFrequency.rawValue
        }

        if let previousRecurrenceType = previousRecurrenceType {
            dto["previousRecurrenceType"] = previousRecurrenceType.rawValue
        }

        if let previousRecurrenceInterval = previousRecurrenceInterval {
            dto["previousRecurrenceInterval"] = previousRecurrenceInterval
        }

        if let previousIgnoreTimeComponent = previousIgnoreTimeComponent {
            dto["previousIgnoreTimeComponent"] = previousIgnoreTimeComponent
        }

        if let previousPriority = previousPriority {
            dto["previousPriority"] = previousPriority
        }

        if let previousCategory = previousCategory {
            dto["previousCategory"] = previousCategory
        }

        return dto
    }
}
