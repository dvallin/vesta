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

        // Now guard if there should be any notifications
        guard let dueDate = item.dueDate, !item.isCompleted else { return }

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Task"
        content.body = item.title
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

    private func scheduleNotificationRequest(
        for item: TodoItem,
        content: UNNotificationContent,
        trigger: UNNotificationTrigger
    ) {
        let identifier = "todo_\(item.id)"
        let request = UNNotificationRequest(
            identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    func cancelNotification(for item: TodoItem) {
        let identifier = "todo_\(item.id)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            identifier
        ])
    }
}
