import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
            granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func scheduleNotification(for item: TodoItem) {
        // Cancel any existing notification for this item
        cancelNotification(for: item)

        // Use rescheduleDate if present, otherwise dueDate
        let effectiveDueDate = item.rescheduleDate ?? item.dueDate
        guard let dueDate = effectiveDueDate, !item.isCompleted else { return }

        let content = UNMutableNotificationContent()
        content.title = item.title
        content.body = Self.notificationBody(for: item, dueDate: dueDate)
        content.sound = .default

        let calendar = Calendar.current

        if item.ignoreTimeComponent {
            // Don't notify those todo items. They are all-day events.
        } else {
            // For time-specific items, notify 15 minutes before
            let triggerDate = dueDate.addingTimeInterval(-15 * 60)

            // Only schedule if the trigger time is in the future
            if triggerDate > Date() {
                let components = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute], from: triggerDate)
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: components, repeats: false)
                scheduleNotificationRequest(for: item, content: content, trigger: trigger)
            }
        }
    }

    private func notificationIdentifier(for item: TodoItem) -> String {
        return "todo_\(item.uid)"
    }

    private func scheduleNotificationRequest(
        for item: TodoItem,
        content: UNNotificationContent,
        trigger: UNNotificationTrigger
    ) {
        let identifier = notificationIdentifier(for: item)
        let request = UNNotificationRequest(
            identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    // Helper to generate a detailed notification body from item data
    private static func notificationBody(for item: TodoItem, dueDate: Date) -> String {
        var lines: [String] = []

        // Format due date
        let dateFormatter = DateFormatter()
        if item.ignoreTimeComponent {
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
        } else {
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
        }
        let dueString = dateFormatter.string(from: dueDate)
        lines.append("Due: \(dueString)")

        // Details
        if !item.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("Details: \(item.details)")
        }

        // Recurrence
        if let freq = item.recurrenceFrequency {
            var recurrence = freq.displayName
            if let interval = item.recurrenceInterval, interval > 1 {
                recurrence = "Every \(interval) \(freq.displayName.lowercased())"
            }
            if let type = item.recurrenceType {
                recurrence += " (\(type.displayName))"
            }
            lines.append("Repeats: \(recurrence)")
        }

        return lines.joined(separator: "\n")
    }

    func cancelNotification(for item: TodoItem) {
        let identifier = notificationIdentifier(for: item)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            identifier
        ])
    }
}
