import Foundation
import SwiftData

extension TodoItem {
    /// Converts the TodoItem entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "TodoItem",
            "id": id,
            "lastModified": lastModified.timeIntervalSince1970,
            "ownerId": owner?.id ?? "",

            "title": title,
            "details": details,
            "isCompleted": isCompleted,
            "ignoreTimeComponent": ignoreTimeComponent,
            "priority": priority,
        ]

        // Add optional properties
        if let dueDate = dueDate {
            dto["dueDate"] = dueDate.timeIntervalSince1970
        }

        if let recurrenceFrequency = recurrenceFrequency {
            dto["recurrenceFrequency"] = recurrenceFrequency.rawValue
        }

        if let recurrenceType = recurrenceType {
            dto["recurrenceType"] = recurrenceType.rawValue
        }

        if let recurrenceInterval = recurrenceInterval {
            dto["recurrenceInterval"] = recurrenceInterval
        }

        // Add relationship references
        if let categoryName = category?.name {
            dto["categoryName"] = categoryName
        }

        if let mealId = meal?.id {
            dto["mealId"] = mealId
        }

        if let shoppingListItemId = shoppingListItem?.id {
            dto["shoppingListItemId"] = shoppingListItemId
        }

        return dto
    }
}
