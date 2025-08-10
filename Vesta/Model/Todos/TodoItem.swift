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
    @Attribute(.unique) var uid: String

    var title: String
    var details: String
    var dueDate: Date?
    var rescheduleDate: Date?
    var isCompleted: Bool
    var recurrenceFrequency: RecurrenceFrequency?
    var recurrenceType: RecurrenceType?
    var recurrenceInterval: Int?
    var ignoreTimeComponent: Bool
    var priority: Int

    var isShared: Bool = false
    var dirty: Bool = true

    var deletedAt: Date? = nil
    var expireAt: Date? = nil

    @Relationship(deleteRule: .noAction)
    var owner: User?

    @Relationship
    var meal: Meal?

    @Relationship
    var shoppingListItem: ShoppingListItem?

    @Relationship
    var category: TodoItemCategory?

    @Relationship
    var events: [TodoEvent] = []

    init(
        title: String,
        details: String,
        dueDate: Date? = nil,
        rescheduleDate: Date? = nil,
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
        self.rescheduleDate = rescheduleDate
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
        rescheduleDate: Date? = nil,
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
            title: title, details: details, dueDate: dueDate, rescheduleDate: rescheduleDate,
            recurrenceFrequency: recurrenceFrequency, recurrenceType: recurrenceType,
            recurrenceInterval: recurrenceInterval, ignoreTimeComponent: ignoreTimeComponent,
            priority: priority, category: category, owner: owner)
        return item
    }

    var isFrozen: Bool {
        guard let category = category, let owner = owner else { return false }
        return category.isFreezable && owner.isOnHoliday
    }

    var isToday: Bool {
        guard let dueDate = rescheduleDate ?? dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    var isCurrentWeek: Bool {
        guard let dueDate = rescheduleDate ?? dueDate else { return false }
        return Calendar.current.isDate(dueDate, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var isNext3Days: Bool {
        guard let dueDate = rescheduleDate ?? dueDate else { return false }
        let today = Calendar.current.startOfDay(for: Date())
        let dueDateDay = Calendar.current.startOfDay(for: dueDate)

        if Calendar.current.isDateInToday(dueDate) {
            return true
        }

        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today),
            let dayAfterTomorrow = Calendar.current.date(byAdding: .day, value: 2, to: today)
        else {
            return false
        }

        let tomorrowDay = Calendar.current.startOfDay(for: tomorrow)
        let dayAfterTomorrowDay = Calendar.current.startOfDay(for: dayAfterTomorrow)

        return dueDateDay == tomorrowDay || dueDateDay == dayAfterTomorrowDay
    }

    var isOverdue: Bool {
        if self.isFrozen {
            return false
        }

        guard let dueDate = rescheduleDate ?? dueDate else { return false }
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
        handleEvent(eventType: .completed, currentUser: currentUser)
    }

    func skip(currentUser: User) {
        guard recurrenceFrequency != nil else { return }
        handleEvent(eventType: .skipped, currentUser: currentUser)
    }

    private func handleEvent(eventType: TodoEventType, currentUser: User) {
        let now = Date()
        let event = TodoEvent(
            eventType: eventType,
            completedAt: now,
            todoItem: self,
            previousDueDate: self.dueDate,
            previousRescheduleDate: self.rescheduleDate
        )
        self.events.append(event)

        if let frequency = recurrenceFrequency {
            var baseDate: Date
            if recurrenceType == .fixed {
                baseDate = dueDate ?? now
            } else {
                baseDate = now
            }
            let baseDateWithTime = DateUtils.preserveTime(from: dueDate, applying: baseDate)
            updateDueDate(
                for: frequency, basedOn: baseDateWithTime ?? baseDate, currentUser: currentUser)
        } else if eventType == .completed {
            isCompleted.toggle()
        }

        self.rescheduleDate = nil
        self.markAsDirty()
    }

    func unfreeze(currentUser: User) {
        let now = Date()
        let startDate = currentUser.holidayStartDate ?? now
        if let frequency = recurrenceFrequency {
            if recurrenceType == .fixed {
                let baseDate = dueDate ?? now
                let baseDateWithTime = DateUtils.preserveTime(from: dueDate, applying: baseDate)
                updateDueDate(
                    for: frequency, basedOn: baseDateWithTime ?? baseDate, currentUser: currentUser)
            } else {
                let daysDifference =
                    Calendar.current.dateComponents([.day], from: startDate, to: now).day ?? 0
                guard let originalDueDate = dueDate else { return }
                let newDueDate =
                    Calendar.current.date(
                        byAdding: .day, value: daysDifference, to: originalDueDate)
                    ?? originalDueDate
                self.dueDate = newDueDate
                self.markAsDirty()
            }
        }
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
        self.rescheduleDate = nil

        self.markAsDirty()
    }

    func setIsCompleted(isCompleted: Bool, currentUser: User) {
        self.isCompleted = isCompleted
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

    func setRescheduleDate(rescheduleDate: Date?, currentUser: User) {
        self.rescheduleDate = rescheduleDate
        self.markAsDirty()
    }

    private func updateDueDate(
        for frequency: RecurrenceFrequency, basedOn baseDate: Date, currentUser: User
    ) {
        let calendar = Calendar.current
        let interval = recurrenceInterval ?? 1
        let now = Date()

        // Get calendar component based on frequency
        let component: Calendar.Component = {
            switch frequency {
            case .daily: return .day
            case .weekly: return .weekOfYear
            case .monthly: return .month
            case .yearly: return .year
            }
        }()

        // Calculate initial due date
        var newDueDate =
            calendar.date(byAdding: component, value: interval, to: baseDate) ?? baseDate

        // Add intervals until the due date is in the future
        while newDueDate < now {
            newDueDate =
                calendar.date(byAdding: component, value: interval, to: newDueDate) ?? newDueDate
        }

        if ignoreTimeComponent {
            self.dueDate = DateUtils.calendar.startOfDay(for: newDueDate)
        } else {
            self.dueDate = newDueDate
        }

        self.markAsDirty()
    }

    // MARK: - Undo Last Event

    /// Undo the last event (mark as done, skip, etc.) by restoring previous state and removing the event.
    func undoLastEvent() {
        guard let lastEvent = events.last else { return }

        // Restore previous due/reschedule dates if available
        if let previousDueDate = lastEvent.previousDueDate {
            self.dueDate = previousDueDate
        }
        if let previousRescheduleDate = lastEvent.previousRescheduleDate {
            self.rescheduleDate = previousRescheduleDate
        }

        // Restore completion state if the last event was .completed
        if lastEvent.eventType == .completed {
            self.isCompleted = false
        }

        // Remove the last event
        self.events.removeLast()
    }

    // MARK: - Completion Analytics

    /// Computes the time intervals between completion and the previous due date for all completed events.
    var completionDistances: [TimeInterval] {
        events
            .filter { $0.eventType == .completed }
            .compactMap { event in
                guard let completedAt = event.completedAt as Date?,
                    let previousDueDate = event.previousDueDate
                else { return nil }
                return completedAt.timeIntervalSince(previousDueDate)
            }
    }

    var meanCompletionDistance: TimeInterval? {
        let distances = completionDistances
        guard !distances.isEmpty else { return nil }
        return distances.reduce(0, +) / Double(distances.count)
    }

    var medianCompletionDistance: TimeInterval? {
        let distances = completionDistances.sorted()
        guard !distances.isEmpty else { return nil }
        let mid = distances.count / 2
        if distances.count % 2 == 0 {
            return (distances[mid - 1] + distances[mid]) / 2
        } else {
            return distances[mid]
        }
    }

    /// Returns the date of the last completion event, or nil if never completed
    var lastCompletionDate: Date? {
        events
            .filter { $0.eventType == .completed }
            .compactMap { $0.completedAt }
            .max()
    }

    var varianceCompletionDistance: TimeInterval? {
        let distances = completionDistances
        guard let mean = meanCompletionDistance, !distances.isEmpty else { return nil }
        if distances.count == 1 {
            return 0
        }
        let variance =
            distances.map { pow($0 - mean, 2) }.reduce(0, +) / Double(distances.count - 1)
        return variance
    }

    // MARK: - Soft Delete Operations

    func softDelete(currentUser: User) {
        self.deletedAt = Date()
        self.setExpiration()
        self.markAsDirty()

        // Soft delete related entities only if they're not already deleted
        if let meal = self.meal, meal.deletedAt == nil {
            meal.softDelete(currentUser: currentUser)
        }
        if let shoppingListItem = self.shoppingListItem, shoppingListItem.deletedAt == nil {
            shoppingListItem.softDelete(currentUser: currentUser)
        }
    }

    func restore(currentUser: User) {
        self.deletedAt = nil
        self.clearExpiration()
        self.markAsDirty()

        // Restore related entities only if they're currently deleted
        if let meal = self.meal, meal.deletedAt != nil {
            meal.restore(currentUser: currentUser)
        }
        if let shoppingListItem = self.shoppingListItem, shoppingListItem.deletedAt != nil {
            shoppingListItem.restore(currentUser: currentUser)
        }
    }
}
