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

    var dirty: Bool = true

    @Relationship(deleteRule: .noAction)
    var owner: User?
    
    @Relationship(deleteRule: .noAction)
    var lastModifiedBy: User?

    @Relationship(deleteRule: .cascade, inverse: \TodoItemEvent.todoItem)
    var events: [TodoItemEvent]

    @Relationship
    var meal: Meal?

    @Relationship
    var shoppingListItem: ShoppingListItem?

    @Relationship
    var category: TodoItemCategory?

    @Relationship
    var spaces: [Space]

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
        category: TodoItemCategory? = nil,
        owner: User
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
        self.events = events
        self.category = category
        self.owner = owner
        self.spaces = []
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
        category: TodoItemCategory? = nil,
        owner: User
    ) -> TodoItem {
        let item = TodoItem(
            title: title, details: details, dueDate: dueDate,
            recurrenceFrequency: recurrenceFrequency, recurrenceType: recurrenceType,
            recurrenceInterval: recurrenceInterval, ignoreTimeComponent: ignoreTimeComponent,
            priority: priority, category: category, owner: owner)
        _ = item.createEvent(type: TodoItemEventType.created, currentUser: owner)
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
        let event = createEvent(
            type: .markAsDone, previousDueDate: dueDate, previousIsCompleted: isCompleted,
            currentUser: currentUser)

        if let frequency = recurrenceFrequency {
            let baseDate = recurrenceType == .fixed ? (dueDate ?? event.date) : event.date
            let baseDateWithTime = DateUtils.preserveTime(from: dueDate, applying: baseDate)
            updateDueDate(for: frequency, basedOn: baseDateWithTime ?? baseDate, currentUser: currentUser)
        } else {
            isCompleted.toggle()
        }

        NotificationManager.shared.scheduleNotification(for: self)
        self.markAsDirty(currentUser)
    }

    func setDetails(details: String, currentUser: User) {
        let _ = createEvent(
            type: .editDetails, previousDetails: self.details, currentUser: currentUser)
        self.details = details
        self.markAsDirty(currentUser)
    }

    func setTitle(title: String, currentUser: User) {
        let _ = createEvent(type: .editTitle, previousTitle: self.title, currentUser: currentUser)
        self.title = title
        self.markAsDirty(currentUser)
    }

    func setDueDate(dueDate: Date?, currentUser: User) {
        let _ = createEvent(
            type: .editDueDate, previousDueDate: self.dueDate, currentUser: currentUser)
        self.dueDate = dueDate

        NotificationManager.shared.scheduleNotification(for: self)
        self.markAsDirty(currentUser)
    }

    func setIsCompleted(isCompleted: Bool, currentUser: User) {
        let _ = createEvent(
            type: .editIsCompleted, previousIsCompleted: self.isCompleted, currentUser: currentUser)
        self.isCompleted = isCompleted

        NotificationManager.shared.scheduleNotification(for: self)
        self.markAsDirty(currentUser)
    }

    func setRecurrenceFrequency(
        recurrenceFrequency: RecurrenceFrequency?, currentUser: User
    ) {
        let _ = createEvent(
            type: .editRecurrenceFrequency, previousRecurrenceFrequency: self.recurrenceFrequency,
            currentUser: currentUser)
        self.recurrenceFrequency = recurrenceFrequency
        self.markAsDirty(currentUser)
    }

    func setRecurrenceInterval(recurrenceInterval: Int?, currentUser: User) {
        let _ = createEvent(
            type: .editRecurrenceInterval, previousRecurrenceInterval: self.recurrenceInterval,
            currentUser: currentUser)
        self.recurrenceInterval = recurrenceInterval
        self.markAsDirty(currentUser)
    }

    func setRecurrenceType(recurrenceType: RecurrenceType?, currentUser: User) {
        let _ = createEvent(
            type: .editRecurrenceType, previousRecurrenceType: self.recurrenceType,
            currentUser: currentUser)
        self.recurrenceType = recurrenceType
        self.markAsDirty(currentUser)
    }

    func setIgnoreTimeComponent(ignoreTimeComponent: Bool, currentUser: User) {
        let _ = createEvent(
            type: .editIgnoreTimeComponent, previousIgnoreTimeComponent: self.ignoreTimeComponent,
            currentUser: currentUser)
        self.ignoreTimeComponent = ignoreTimeComponent

        if ignoreTimeComponent, let dueDate = self.dueDate {
            self.dueDate = DateUtils.calendar.startOfDay(for: dueDate)
        }

        // Reschedule notification with new time component setting
        NotificationManager.shared.scheduleNotification(for: self)
        self.markAsDirty(currentUser)
    }

    func setPriority(priority: Int, currentUser: User) {
        let _ = createEvent(
            type: .editPriority, previousPriority: self.priority, currentUser: currentUser)
        self.priority = priority
        self.markAsDirty(currentUser)
    }

    func setCategory(category: TodoItemCategory?, currentUser: User) {
        let _ = createEvent(
            type: .editCategory, previousCategory: self.category?.name, currentUser: currentUser)
        self.category = category
        self.markAsDirty(currentUser)
    }

    func undoLastEvent(currentUser: User) -> TodoItemEvent? {
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

        self.markAsDirty(currentUser)

        return lastEvent
    }

    private func updateDueDate(for frequency: RecurrenceFrequency, basedOn baseDate: Date, currentUser: User) {
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

        self.markAsDirty(currentUser)
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
        previousCategory: String? = nil,
        currentUser: User
    ) -> TodoItemEvent {
        let event = TodoItemEvent(
            type: type,
            date: Date(),
            owner: currentUser,
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
