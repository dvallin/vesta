import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
    }

    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) {
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
        content.title = Self.notificationTitle(for: dueDate)
        content.body = Self.notificationBody(for: item)
        content.sound = .default
        content.userInfo = ["todoItemUID": item.uid]

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

    // Helper to generate a concise notification title.
    private static func notificationTitle(for dueDate: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        let timeString = timeFormatter.string(from: dueDate)
        
        return String(
            format: NSLocalizedString("Due in 15 min at %@", comment: "Notification title with due time"),
            timeString
        )
    }

    // Helper to generate a concise, informative notification body.
    // Note: This is computed at scheduling time (which may be days before delivery),
    // so we avoid relative time like "In X minutes" and show static info instead.
    private static func notificationBody(for item: TodoItem) -> String {
        var lines: [String] = []

        // Start with the todo item title
        lines.append(item.title)

        // Show category if present
        if let category = item.category?.name, !category.isEmpty {
            lines.append(category)
        }

        // Show details if present (truncated to keep notification concise)
        let trimmedDetails = item.details.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedDetails.isEmpty {
            let maxLength = 80
            let truncated =
                trimmedDetails.count > maxLength
                ? String(trimmedDetails.prefix(maxLength)) + "\u{2026}"
                : trimmedDetails
            lines.append(truncated)
        }

        return lines.joined(separator: "\n")
    }

    func cancelNotification(for item: TodoItem) {
        let identifier = notificationIdentifier(for: item)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            identifier
        ])
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let todoItemUID = userInfo["todoItemUID"] as? String {
            DispatchQueue.main.async {
                DeepLinkManager.shared.pendingTodoItemUID = todoItemUID
            }
        }
        completionHandler()
    }

    // Handle notifications when app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
