import Foundation
import SwiftData

extension TodoItem {
    /// Converts the TodoItem entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "TodoItem",
            "uid": uid,
            "ownerId": owner?.uid ?? "",
            "isShared": isShared,

            "title": title,
            "details": details,
            "isCompleted": isCompleted,
            "ignoreTimeComponent": ignoreTimeComponent,
            "priority": priority,
        ]

        // Add optional properties
        if let dueDate = dueDate {
            dto["dueDate"] = dueDate
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

        if let mealId = meal?.uid {
            dto["mealId"] = mealId
        }

        if let shoppingListItemId = shoppingListItem?.uid {
            dto["shoppingListItemId"] = shoppingListItemId
        }

        // Add events for analytics (was completionEvents)
        dto["events"] = events.map { $0.toDTO() }

        return dto
    }

    // Method to update properties directly from a DTO during sync operations without triggering events
    func update(from dto: [String: Any]) {
        self.isShared = dto["isShared"] as? Bool ?? false

        if let title = dto["title"] as? String {
            self.title = title
        }
        if let details = dto["details"] as? String {
            self.details = details
        }
        if let dueDate = dto["dueDate"] as? Date {
            self.dueDate = dueDate
        }
        if let isCompleted = dto["isCompleted"] as? Bool {
            self.isCompleted = isCompleted
        }
        if let ignoreTimeComponent = dto["ignoreTimeComponent"] as? Bool {
            self.ignoreTimeComponent = ignoreTimeComponent
        }
        if let priority = dto["priority"] as? Int {
            self.priority = priority
        }
        if let recurrenceFrequencyRaw = dto["recurrenceFrequency"] as? String {
            self.recurrenceFrequency = RecurrenceFrequency(rawValue: recurrenceFrequencyRaw)
        }
        if let recurrenceTypeRaw = dto["recurrenceType"] as? String {
            self.recurrenceType = RecurrenceType(rawValue: recurrenceTypeRaw)
        }
        if let recurrenceInterval = dto["recurrenceInterval"] as? Int {
            self.recurrenceInterval = recurrenceInterval
        }

        // Update events from DTOs (was completionEvents)
        if let eventsDTOs = dto["events"] as? [[String: Any]] {
            self.events.removeAll()
            for eventDTO in eventsDTOs {
                let eventType: TodoEventType
                if let eventTypeRaw = eventDTO["eventType"] as? String,
                    let parsedType = TodoEventType(rawValue: eventTypeRaw)
                {
                    eventType = parsedType
                } else {
                    eventType = .completed
                }
                let event = TodoEvent(
                    eventType: eventType,
                    completedAt: eventDTO["completedAt"] as? Date ?? Date(),
                    todoItem: self,
                    previousDueDate: eventDTO["previousDueDate"] as? Date,
                    previousRescheduleDate: eventDTO["previousRescheduleDate"] as? Date
                )
                self.events.append(event)
            }
        }
    }
}
