import Foundation
import SwiftData
import SwiftUI

enum RecurrenceFrequency: String, Codable, CaseIterable {
    case daily, weekly, monthly, yearly

    var displayName: String {
        switch self {
        case .daily:
            return String(
                localized: "todos.recurrence-frequency.daily")
        case .weekly:
            return String(
                localized: "todos.recurrence-frequency.weekly")
        case .monthly:
            return String(
                localized: "todos.recurrence-frequency.monthly")
        case .yearly:
            return String(
                localized: "todos.recurrence-frequency.yearly")
        }
    }
}

enum RecurrenceType: String, Codable, CaseIterable {
    case fixed, flexible

    var displayName: String {
        switch self {
        case .fixed:
            return String(localized: "todos.recurrence-type.fixed")
        case .flexible:
            return String(localized: "todos.recurrence-type.flexible")
        }
    }
}

enum DayOfWeek: String, Codable, CaseIterable {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday

    var displayName: String {
        switch self {
        case .sunday:
            return String(localized: "todos.day-of-week.sunday")
        case .monday:
            return String(localized: "todos.day-of-week.monday")
        case .tuesday:
            return String(localized: "todos.day-of-week.tuesday")
        case .wednesday:
            return String(localized: "todos.day-of-week.wednesday")
        case .thursday:
            return String(localized: "todos.day-of-week.thursday")
        case .friday:
            return String(localized: "todos.day-of-week.friday")
        case .saturday:
            return String(localized: "todos.day-of-week.saturday")
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
    var repeatOn: [DayOfWeek]?
    var ignoreTimeComponent: Bool
    var priority: Int

    var isShared: Bool = false
    var dirty: Bool = true

    var deletedAt: Date? = nil
    var expireAt: Date? = nil

    @Relationship(deleteRule: .nullify)
    var owner: User?

    @Relationship(deleteRule: .cascade)
    var meal: Meal?

    @Relationship(deleteRule: .cascade)
    var shoppingListItem: ShoppingListItem?

    @Relationship(deleteRule: .nullify)
    var category: TodoItemCategory?

    @Relationship(deleteRule: .cascade)
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
        repeatOn: [DayOfWeek]? = nil,
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
        self.repeatOn = repeatOn
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
        repeatOn: [DayOfWeek]? = nil,
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
            recurrenceInterval: recurrenceInterval, repeatOn: repeatOn,
            ignoreTimeComponent: ignoreTimeComponent, priority: priority, category: category,
            owner: owner)
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

        if ignoreTimeComponent {
            return !self.isCompleted && self.isInThePast && !self.isToday
        } else {
            return !self.isCompleted && self.isInThePast
        }
    }

    var isInThePast: Bool {
        guard let dueDate = rescheduleDate ?? dueDate else { return false }
        return dueDate < Date()
    }

    var needsReschedule: Bool {
        return self.isOverdue && !self.isToday
    }

    var lastCompletionDate: Date? {
        events
            .filter { $0.eventType == .completed }
            .compactMap { $0.completedAt }
            .max()
    }

    /// Checks if a completion date is within acceptable tolerance of the target due date
    /// Uses adaptive tolerance based on recurrence frequency and type
    func isWithinStreakTolerance(date: Date, targetDate: Date) -> Bool {
        let toleranceDays = calculateAdaptiveTolerance()
        let tolerance =
            Calendar.current.date(byAdding: .day, value: toleranceDays, to: targetDate)
            ?? targetDate
        return date <= tolerance
    }

    /// Calculates adaptive tolerance in days based on recurrence frequency and type
    /// - Daily habits: 1 day (strict for consistency)
    /// - Weekly tasks: 2 days (allows some flexibility)
    /// - Monthly tasks: 5 days (reasonable for larger intervals)
    /// - Yearly tasks: 14 days (generous for infrequent tasks)
    ///
    /// Modifiers:
    /// - Fixed recurrence: 70% of base (stricter scheduling)
    /// - Flexible recurrence: 130% of base (more adaptable)
    private func calculateAdaptiveTolerance() -> Int {
        guard let frequency = recurrenceFrequency else {
            return 2  // Default for non-recurring items
        }

        let baseToleranceByFrequency: Int
        switch frequency {
        case .daily:
            baseToleranceByFrequency = 1  // Daily habits should be stricter
        case .weekly:
            baseToleranceByFrequency = 2  // Weekly tasks get 2 days
        case .monthly:
            baseToleranceByFrequency = 5  // Monthly tasks get more flexibility
        case .yearly:
            baseToleranceByFrequency = 14  // Yearly tasks get 2 weeks
        }

        // Adjust based on recurrence type
        let typeMultiplier: Double
        switch recurrenceType {
        case .fixed:
            typeMultiplier = 0.7  // Fixed recurrences should be stricter
        case .flexible:
            typeMultiplier = 1.3  // Flexible recurrences get more tolerance
        case .none:
            typeMultiplier = 1.0  // Default multiplier
        }

        return max(1, Int(Double(baseToleranceByFrequency) * typeMultiplier))
    }

    /// Returns the current tolerance in days for this item (useful for debugging/UI)
    var currentToleranceDays: Int {
        return calculateAdaptiveTolerance()
    }

    var isHabitItem: Bool {
        return self.recurrenceFrequency != nil
    }

    var streakMissed: Bool {
        if self.isFrozen {
            return false
        }
        guard let dueDate = dueDate else { return true }
        return self.isInThePast && !isWithinStreakTolerance(date: Date(), targetDate: dueDate)
    }

    var currentStreak: Int {
        if self.streakMissed {
            return 0
        }

        let sortedEvents = events.sorted { $0.completedAt < $1.completedAt }
        guard !sortedEvents.isEmpty else { return 0 }

        var streak = 0
        for event in sortedEvents.reversed() {
            if event.eventType == .completed && wasCompletedWithinReasonableTime(event) {
                streak += 1
            } else if event.eventType == .skipped {
                // Skipped tasks don't break the streak, just don't add to it
                continue
            } else {
                // Late completion or other event types break the streak
                break
            }
        }
        return streak
    }

    private func wasCompletedWithinReasonableTime(_ event: TodoEvent) -> Bool {
        guard let date = event.completedAt as Date? else {
            return false
        }
        guard let dueDate = event.previousDueDate else {
            return false
        }
        return isWithinStreakTolerance(date: date, targetDate: dueDate)
    }

    var health: Int {
        let S_CAP = 5.0
        let streak = Double(self.currentStreak)
        return Int(100 * (streak / (streak + S_CAP)))
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

    func setRepeatOn(repeatOn: [DayOfWeek]?, currentUser: User) {
        self.repeatOn = repeatOn
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
        let interval = recurrenceInterval ?? 1

        let newDueDate: Date

        newDueDate = findNextOccurrence(
            from: baseDate, frequency: frequency, interval: interval, repeatOn: repeatOn)

        if ignoreTimeComponent {
            self.dueDate = DateUtils.calendar.startOfDay(for: newDueDate)
        } else {
            self.dueDate = newDueDate
        }

        self.markAsDirty()
    }

    private func findNextOccurrence(
        from baseDate: Date, frequency: RecurrenceFrequency, interval: Int,
        repeatOn: [DayOfWeek]? = nil
    ) -> Date {
        let calendar = Calendar.current
        let now = Date()

        // Special handling for weekly fixed recurrence with repeatOn days
        if frequency == .weekly, let repeatOn = repeatOn, !repeatOn.isEmpty {
            let targetWeekdays = repeatOn.map { dayOfWeek in
                switch dayOfWeek {
                case .sunday: return 1
                case .monday: return 2
                case .tuesday: return 3
                case .wednesday: return 4
                case .thursday: return 5
                case .friday: return 6
                case .saturday: return 7
                }
            }

            let maxSearchDays = 7 * interval + 7
            for dayOffset in 1...maxSearchDays {
                guard
                    let candidateDate = calendar.date(
                        byAdding: .day, value: dayOffset, to: baseDate)
                else { continue }
                let weekday = calendar.component(.weekday, from: candidateDate)

                if targetWeekdays.contains(weekday) && candidateDate > now {
                    // Check if this candidate respects the interval requirement
                    let weeksSinceBase =
                        calendar.dateComponents([.weekOfYear], from: baseDate, to: candidateDate)
                        .weekOfYear ?? 0

                    if weeksSinceBase % interval == 0 {
                        // Preserve time from original baseDate
                        let preservedTime =
                            DateUtils.preserveTime(from: baseDate, applying: candidateDate)
                            ?? candidateDate
                        return preservedTime
                    }
                }
            }

            // Fallback: if nothing found, return base date plus interval weeks
            return calendar.date(byAdding: .weekOfYear, value: interval, to: baseDate) ?? baseDate
        }

        // Standard recurrence logic for all other cases
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

        return newDueDate
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

    // MARK: - Soft Delete Operations

    func softDelete(currentUser: User) {
        // Early return if already soft deleted
        guard self.deletedAt == nil else { return }

        self.deletedAt = Date()
        self.setExpiration()
        self.markAsDirty()

        if let meal = self.meal {
            meal.softDelete(currentUser: currentUser)
        }
        if let shoppingListItem = self.shoppingListItem {
            shoppingListItem.softDelete(currentUser: currentUser)
        }
    }

    func restore(currentUser: User) {
        // Early return if not soft deleted
        guard self.deletedAt != nil else { return }

        self.deletedAt = nil
        self.clearExpiration()
        self.markAsDirty()

        if let meal = self.meal {
            meal.restore(currentUser: currentUser)
        }
        if let shoppingListItem = self.shoppingListItem {
            shoppingListItem.restore(currentUser: currentUser)
        }

    }

}
