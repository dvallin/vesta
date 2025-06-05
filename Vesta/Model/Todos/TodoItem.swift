import Foundation
import SwiftData
import SwiftUI

enum RecurrenceFrequency: String, Codable, CaseIterable {
    case daily, weekly, monthly, yearly

    var displayName: String {
        switch self {
        case .daily:
            return NSLocalizedString("Daily", comment: "Recurrence frequency: daily")
        case .weekly:
            return NSLocalizedString("Weekly", comment: "Recurrence frequency: weekly")
        case .monthly:
            return NSLocalizedString("Monthly", comment: "Recurrence frequency: monthly")
        case .yearly:
            return NSLocalizedString("Yearly", comment: "Recurrence frequency: yearly")
        }
    }
}

enum RecurrenceType: String, Codable, CaseIterable {
    case fixed, flexible

    var displayName: String {
        switch self {
        case .fixed:
            return NSLocalizedString("Fixed", comment: "Recurrence type: fixed")
        case .flexible:
            return NSLocalizedString("Flexible", comment: "Recurrence type: flexible")
        }
    }
}

@Model
class TodoItem: SyncableEntity {
    @Attribute(.unique) var uid: String?

    var title: String
    var details: String
    var dueDate: Date?
    var isCompleted: Bool
    var recurrenceFrequency: RecurrenceFrequency?
    var recurrenceType: RecurrenceType?
    var recurrenceInterval: Int?
    var ignoreTimeComponent: Bool
    var priority: Int

    var isShared: Bool = false
    var dirty: Bool = true

    @Relationship(deleteRule: .noAction)
    var owner: User?

    @Relationship
    var meal: Meal?

    @Relationship
    var shoppingListItem: ShoppingListItem?

    @Relationship
    var category: TodoItemCategory?

    init(
        title: String,
        details: String,
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        recurrenceFrequency: RecurrenceFrequency? = nil,
        recurrenceType: RecurrenceType? = nil,
        recurrenceInterval: Int? = nil,
        ignoreTimeComponent: Bool = true,
        priority: Int = 4,
        meal: Meal? = nil,
        shoppingListItem: ShoppingListItem? = nil,
        category: TodoItemCategory? = nil,
        owner: User?
    ) {
        self.uid = UUID().uuidString
        self.title = title
        self.details = details
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.recurrenceFrequency = recurrenceFrequency
        self.recurrenceType = recurrenceType
        self.recurrenceInterval = recurrenceInterval
        self.ignoreTimeComponent = ignoreTimeComponent
        self.priority = priority
        self.meal = meal
        self.shoppingListItem = shoppingListItem
        self.category = category
        self.owner = owner
    }

    static func create(
        title: String, details: String,
        dueDate: Date? = nil,
        recurrenceFrequency: RecurrenceFrequency? = nil,
        recurrenceType: RecurrenceType? = nil,
        recurrenceInterval: Int? = nil,
        ignoreTimeComponent: Bool = true,
        priority: Int = 4,
        meal: Meal? = nil,
        shoppingListItem: ShoppingListItem? = nil,
        category: TodoItemCategory? = nil,
        owner: User
    ) -> TodoItem {
        let item = TodoItem(
            title: title, details: details, dueDate: dueDate,
            recurrenceFrequency: recurrenceFrequency, recurrenceType: recurrenceType,
            recurrenceInterval: recurrenceInterval, ignoreTimeComponent: ignoreTimeComponent,
            priority: priority, category: category, owner: owner)
        return item
    }

    var isToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
    var isCurrentWeek: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDate(dueDate, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        let isInThePast = dueDate < Date()
        if ignoreTimeComponent {
            return !self.isCompleted && isInThePast && !self.isToday
        } else {
            return !self.isCompleted && isInThePast
        }
    }

    var needsReschedule: Bool {
        return self.isOverdue && !self.isToday
    }

    func markAsDone(currentUser: User) {
        let now = Date()
        if let frequency = recurrenceFrequency {
            let baseDate = recurrenceType == .fixed ? (dueDate ?? now) : now
            let baseDateWithTime = DateUtils.preserveTime(from: dueDate, applying: baseDate)
            updateDueDate(
                for: frequency, basedOn: baseDateWithTime ?? baseDate, currentUser: currentUser)
        } else {
            isCompleted.toggle()
        }

        NotificationManager.shared.scheduleNotification(for: self)
        self.markAsDirty()
    }

    func setDetails(details: String, currentUser: User) {
        self.details = details
        self.markAsDirty()
    }

    func setTitle(title: String, currentUser: User) {
        self.title = title
        self.markAsDirty()
    }

    func setDueDate(dueDate: Date?, currentUser: User) {
        self.dueDate = dueDate

        NotificationManager.shared.scheduleNotification(for: self)
        self.markAsDirty()
    }

    func setIsCompleted(isCompleted: Bool, currentUser: User) {
        self.isCompleted = isCompleted

        NotificationManager.shared.scheduleNotification(for: self)
        self.markAsDirty()
    }

    func setRecurrenceFrequency(
        recurrenceFrequency: RecurrenceFrequency?, currentUser: User
    ) {
        self.recurrenceFrequency = recurrenceFrequency
        self.markAsDirty()
    }

    func setRecurrenceInterval(recurrenceInterval: Int?, currentUser: User) {
        self.recurrenceInterval = recurrenceInterval
        self.markAsDirty()
    }

    func setRecurrenceType(recurrenceType: RecurrenceType?, currentUser: User) {
        self.recurrenceType = recurrenceType
        self.markAsDirty()
    }

    func setIgnoreTimeComponent(ignoreTimeComponent: Bool, currentUser: User) {
        self.ignoreTimeComponent = ignoreTimeComponent

        if ignoreTimeComponent, let dueDate = self.dueDate {
            self.dueDate = DateUtils.calendar.startOfDay(for: dueDate)
        }

        // Reschedule notification with new time component setting
        NotificationManager.shared.scheduleNotification(for: self)
        self.markAsDirty()
    }

    func setPriority(priority: Int, currentUser: User) {
        self.priority = priority
        self.markAsDirty()
    }

    func setCategory(category: TodoItemCategory?, currentUser: User) {
        self.category = category
        self.markAsDirty()
    }

    private func updateDueDate(
        for frequency: RecurrenceFrequency, basedOn baseDate: Date, currentUser: User
    ) {
        let calendar = Calendar.current
        let interval = recurrenceInterval ?? 1

        switch frequency {
        case .daily:
            dueDate = calendar.date(byAdding: .day, value: interval, to: baseDate)
        case .weekly:
            dueDate = calendar.date(byAdding: .weekOfYear, value: interval, to: baseDate)
        case .monthly:
            dueDate = calendar.date(byAdding: .month, value: interval, to: baseDate)
        case .yearly:
            dueDate = calendar.date(byAdding: .year, value: interval, to: baseDate)
        }

        if ignoreTimeComponent, let dueDate = dueDate {
            self.dueDate = DateUtils.calendar.startOfDay(for: dueDate)
        }

        self.markAsDirty()
    }
}
