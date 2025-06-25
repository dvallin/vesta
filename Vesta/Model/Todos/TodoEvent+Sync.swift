import Foundation

extension TodoEvent {
    /// Converts the TodoEvent to a DTO (dictionary) for syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "uid": uid,
            "eventType": eventType.rawValue,
            "completedAt": completedAt,
        ]
        if let previousDueDate = previousDueDate {
            dto["previousDueDate"] = previousDueDate
        }
        if let previousRescheduleDate = previousRescheduleDate {
            dto["previousRescheduleDate"] = previousRescheduleDate
        }
        return dto
    }

    /// Updates the TodoEvent from a DTO (dictionary)
    func update(from dto: [String: Any]) {
        if let eventTypeRaw = dto["eventType"] as? String,
            let eventType = TodoEventType(rawValue: eventTypeRaw)
        {
            self.eventType = eventType
        }
        if let completedAt = dto["completedAt"] as? Date {
            self.completedAt = completedAt
        }
        if let previousDueDate = dto["previousDueDate"] as? Date {
            self.previousDueDate = previousDueDate
        }
        if let previousRescheduleDate = dto["previousRescheduleDate"] as? Date {
            self.previousRescheduleDate = previousRescheduleDate
        }
    }
}
