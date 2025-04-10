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
    
    /// Updates properties from a dictionary (typically from the server)
    func update(from data: [String: Any]) {
        if let typeRaw = data["type"] as? String,
           let type = TodoItemEventType(rawValue: typeRaw) {
            self.type = type
        }
        
        if let date = data["date"] as? Date {
            self.date = date
        }
        
        // Update previous values
        if let previousTitle = data["previousTitle"] as? String {
            self.previousTitle = previousTitle
        }
        
        if let previousDetails = data["previousDetails"] as? String {
            self.previousDetails = previousDetails
        }
        
        if let previousDueDate = data["previousDueDate"] as? Date {
            self.previousDueDate = previousDueDate
        }
        
        if let previousIsCompleted = data["previousIsCompleted"] as? Bool {
            self.previousIsCompleted = previousIsCompleted
        }
        
        if let previousRecurrenceFrequencyRaw = data["previousRecurrenceFrequency"] as? String,
           let previousRecurrenceFrequency = RecurrenceFrequency(rawValue: previousRecurrenceFrequencyRaw) {
            self.previousRecurrenceFrequency = previousRecurrenceFrequency
        }
        
        if let previousRecurrenceTypeRaw = data["previousRecurrenceType"] as? String,
           let previousRecurrenceType = RecurrenceType(rawValue: previousRecurrenceTypeRaw) {
            self.previousRecurrenceType = previousRecurrenceType
        }
        
        if let previousRecurrenceInterval = data["previousRecurrenceInterval"] as? Int {
            self.previousRecurrenceInterval = previousRecurrenceInterval
        }
        
        if let previousIgnoreTimeComponent = data["previousIgnoreTimeComponent"] as? Bool {
            self.previousIgnoreTimeComponent = previousIgnoreTimeComponent
        }
        
        if let previousPriority = data["previousPriority"] as? Int {
            self.previousPriority = previousPriority
        }
        
        if let previousCategory = data["previousCategory"] as? String {
            self.previousCategory = previousCategory
        }
    }
}
