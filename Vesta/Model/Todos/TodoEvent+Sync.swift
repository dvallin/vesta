import Foundation

extension TodoEvent {
    /// Converts the TodoEvent to a DTO (dictionary) for syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "uid": uid,
            "eventType": eventType.rawValue,
            "completedAt": completedAt,
        ]
        dto["previousDueDate"] = previousDueDate as Any
        dto["previousRescheduleDate"] = previousRescheduleDate as Any
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
        if dto.keys.contains("previousDueDate") {
            self.previousDueDate = dto["previousDueDate"] as? Date
        }
        if dto.keys.contains("previousRescheduleDate") {
            self.previousRescheduleDate = dto["previousRescheduleDate"] as? Date
        }
    }
}
