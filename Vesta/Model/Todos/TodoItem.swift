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
class TodoItem {
    var title: String
    var details: String
    var dueDate: Date?
    var isCompleted: Bool
    var recurrenceFrequency: RecurrenceFrequency?
    var recurrenceType: RecurrenceType?
    var recurrenceInterval: Int?
    var ignoreTimeComponent: Bool
    var priority: Int

    @Relationship(deleteRule: .cascade)
    var events: [TodoItemEvent]

    @Relationship(inverse: \Meal.todoItem)
    var meal: Meal?

    @Relationship(inverse: \ShoppingListItem.todoItem)
    var shoppingListItem: ShoppingListItem?

    @Relationship()
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
        events: [TodoItemEvent] = [],
        meal: Meal? = nil,
        shoppingListItem: ShoppingListItem? = nil,
        category: TodoItemCategory? = nil
    ) {
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
        self.events = events
        self.category = category
    }

    static func create(
        title: String, details: String,
        dueDate: Date? = nil,
        recurrenceFrequency: RecurrenceFrequency? = nil,
        recurrenceType: RecurrenceType? = nil,
        recurrenceInterval: Int? = nil,
        ignoreTimeComponent: Bool = true,
        priority: Int = 4,
        events: [TodoItemEvent] = [],
        meal: Meal? = nil,
        shoppingListItem: ShoppingListItem? = nil,
        category: TodoItemCategory? = nil
    ) -> TodoItem {
        let item = TodoItem(
            title: title, details: details, dueDate: dueDate,
            recurrenceFrequency: recurrenceFrequency, recurrenceType: recurrenceType,
            recurrenceInterval: recurrenceInterval, ignoreTimeComponent: ignoreTimeComponent,
            priority: priority, category: category)
        item.recordCreationEvent()
        return item
    }

    func recordCreationEvent() {
        let event = TodoItemEvent(type: .created, date: Date(), todoItem: self)
        self.events.append(event)
    }

    var isToday: Bool {
        guard let dueDate = dueDate else { return false }
        return DateUtils.calendar.isDateInToday(dueDate)
    }

    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        let gracePeriod = TimeInterval(2 * 60 * 60)
        let isInThePast = dueDate.addingTimeInterval(gracePeriod) < Date()
        if ignoreTimeComponent {
            return !self.isCompleted && isInThePast && !self.isToday
        } else {
            return !self.isCompleted && isInThePast
        }
    }

    var needsReschedule: Bool {
        return self.isOverdue && !self.isToday
    }

    func markAsDone() {
        let event = createEvent(
            type: .markAsDone, previousDueDate: dueDate, previousIsCompleted: isCompleted)

        if let frequency = recurrenceFrequency {
            updateDueDate(
                for: frequency,
                basedOn: recurrenceType == .fixed ? (dueDate ?? event.date) : event.date
            )
        } else {
            isCompleted.toggle()
        }
    }

    func setDetails(details: String) {
        let _ = createEvent(type: .editDetails, previousDetails: self.details)
        self.details = details
    }

    func setTitle(title: String) {
        let _ = createEvent(type: .editTitle, previousTitle: self.title)
        self.title = title
    }

    func setDueDate(dueDate: Date?) {
        let _ = createEvent(type: .editDueDate, previousDueDate: self.dueDate)
        self.dueDate = dueDate

        if dueDate != nil {
            NotificationManager.shared.scheduleNotification(for: self)
        } else {
            NotificationManager.shared.cancelNotification(for: self)
        }
    }

    func setIsCompleted(isCompleted: Bool) {
        let _ = createEvent(type: .editIsCompleted, previousIsCompleted: self.isCompleted)
        self.isCompleted = isCompleted

        if isCompleted {
            NotificationManager.shared.cancelNotification(for: self)
        } else {
            NotificationManager.shared.scheduleNotification(for: self)
        }
    }

    func setRecurrenceFrequency(
        recurrenceFrequency: RecurrenceFrequency?
    ) {
        let _ = createEvent(
            type: .editRecurrenceFrequency, previousRecurrenceFrequency: self.recurrenceFrequency)
        self.recurrenceFrequency = recurrenceFrequency
    }

    func setRecurrenceInterval(recurrenceInterval: Int?) {
        let _ = createEvent(
            type: .editRecurrenceInterval, previousRecurrenceInterval: self.recurrenceInterval)
        self.recurrenceInterval = recurrenceInterval
    }

    func setRecurrenceType(recurrenceType: RecurrenceType?) {
        let _ = createEvent(type: .editRecurrenceType, previousRecurrenceType: self.recurrenceType)
        self.recurrenceType = recurrenceType
    }

    func setIgnoreTimeComponent(ignoreTimeComponent: Bool) {
        let _ = createEvent(
            type: .editIgnoreTimeComponent, previousIgnoreTimeComponent: self.ignoreTimeComponent)
        self.ignoreTimeComponent = ignoreTimeComponent

        if ignoreTimeComponent, let dueDate = self.dueDate {
            self.dueDate = DateUtils.calendar.startOfDay(for: dueDate)
        }

        // Reschedule notification with new time component setting
        NotificationManager.shared.scheduleNotification(for: self)
    }

    func setPriority(priority: Int) {
        let _ = createEvent(type: .editPriority, previousPriority: self.priority)
        self.priority = priority
    }

    func setCategory(category: TodoItemCategory?) {
        let _ = createEvent(type: .editCategory, previousCategory: self.category?.name)
        self.category = category
    }

    func undoLastEvent() -> TodoItemEvent? {
        guard let lastEvent = events.popLast() else { return nil }

        switch lastEvent.type {
        case .markAsDone:
            self.isCompleted = lastEvent.previousIsCompleted ?? self.isCompleted
            self.dueDate = lastEvent.previousDueDate
        case .editTitle:
            self.title = lastEvent.previousTitle ?? self.title
        case .editDetails:
            self.details = lastEvent.previousDetails ?? self.details
        case .editIsCompleted:
            self.isCompleted = lastEvent.previousIsCompleted ?? self.isCompleted
        case .editDueDate:
            self.dueDate = lastEvent.previousDueDate
        case .editRecurrenceFrequency:
            self.recurrenceFrequency = lastEvent.previousRecurrenceFrequency
        case .editRecurrenceType:
            self.recurrenceType = lastEvent.previousRecurrenceType
        case .editRecurrenceInterval:
            self.recurrenceInterval = lastEvent.previousRecurrenceInterval
        case .editIgnoreTimeComponent:
            self.ignoreTimeComponent =
                lastEvent.previousIgnoreTimeComponent ?? self.ignoreTimeComponent
        case .editPriority:
            self.priority = lastEvent.previousPriority ?? self.priority
        case .editCategory:
            // TODO: somehow fetch the category by name or create it.
            self.category = self.category
        case .created:
            break
        }

        return lastEvent
    }

    private func updateDueDate(for frequency: RecurrenceFrequency, basedOn baseDate: Date) {
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
    }

    private func createEvent(
        type: TodoItemEventType,
        previousTitle: String? = nil,
        previousDetails: String? = nil,
        previousDueDate: Date? = nil,
        previousIsCompleted: Bool? = nil,
        previousRecurrenceFrequency: RecurrenceFrequency? = nil,
        previousRecurrenceType: RecurrenceType? = nil,
        previousRecurrenceInterval: Int? = nil,
        previousIgnoreTimeComponent: Bool? = nil,
        previousPriority: Int? = nil,
        previousCategory: String? = nil
    ) -> TodoItemEvent {
        let event = TodoItemEvent(
            type: type,
            date: Date(),
            todoItem: self,
            previousTitle: previousTitle,
            previousDetails: previousDetails,
            previousDueDate: previousDueDate,
            previousIsCompleted: previousIsCompleted,
            previousRecurrenceFrequency: previousRecurrenceFrequency,
            previousRecurrenceType: previousRecurrenceType,
            previousRecurrenceInterval: previousRecurrenceInterval,
            previousIgnoreTimeComponent: previousIgnoreTimeComponent,
            previousPriority: previousPriority,
            previousCategory: previousCategory
        )
        events.append(event)
        return event
    }
}
