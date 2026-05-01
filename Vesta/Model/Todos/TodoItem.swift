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

enum HealthTrend: String {
    case improving
    case stable
    case declining

    var systemImage: String {
        switch self {
        case .improving:
            return "arrow.up.right"
        case .stable:
            return "arrow.right"
        case .declining:
            return "arrow.down.right"
        }
    }

    var displayName: String {
        switch self {
        case .improving:
            return String(localized: "todos.health-trend.improving")
        case .stable:
            return String(localized: "todos.health-trend.stable")
        case .declining:
            return String(localized: "todos.health-trend.declining")
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
        let sortedEvents = events.sorted { $0.completedAt < $1.completedAt }
        guard !sortedEvents.isEmpty else { return 0 }

        var streak = 0
        var consecutiveMisses = 0
        let maxConsecutiveMisses = 2

        for event in sortedEvents.reversed() {
            if event.eventType == .completed && wasCompletedWithinReasonableTime(event) {
                streak += 1
                consecutiveMisses = 0
            } else if event.eventType == .skipped {
                // Skipped tasks don't break the streak, just don't add to it
                continue
            } else {
                // Late completion or other event types: apply decay
                consecutiveMisses += 1
                if consecutiveMisses >= maxConsecutiveMisses {
                    // Two consecutive misses: full reset
                    break
                }
                // First miss: halve the accumulated streak (graceful decay)
                streak = streak / 2
            }
        }

        // If currently overdue beyond tolerance, apply one decay penalty
        if self.streakMissed {
            streak = streak / 2
        }

        return streak
    }

    var bestStreak: Int {
        let sortedEvents = events.sorted { $0.completedAt < $1.completedAt }
        guard !sortedEvents.isEmpty else { return 0 }

        var current = 0
        var best = 0
        for event in sortedEvents {
            if event.eventType == .completed && wasCompletedWithinReasonableTime(event) {
                current += 1
                best = max(best, current)
            } else if event.eventType == .skipped {
                // Skipped tasks don't break the streak, just don't count
                continue
            } else {
                current = 0
            }
        }
        return max(best, currentStreak)
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
        let sCap = adaptiveStreakCap
        let streak = Double(self.currentStreak)
        let base = 100.0 * (streak / (streak + sCap))
        // Subtle quality bonus: up to +5% for completing before the due date
        let qualityBonus = onTimeRate * 5.0
        return min(100, Int(base + qualityBonus))
    }

    /// Adapts the streak saturation cap based on recurrence frequency.
    /// Lower caps mean health grows faster per completion, which is appropriate
    /// for less frequent tasks where each completion represents more elapsed time.
    /// - Daily: S_CAP=7 (~50% at 1 week, ~75% at 3 weeks)
    /// - Weekly: S_CAP=5 (~50% at 5 weeks, ~75% at 15 weeks)
    /// - Monthly: S_CAP=3 (~50% at 3 months, ~75% at 9 months)
    /// - Yearly: S_CAP=2 (~50% at 2 years, ~75% at 6 years)
    private var adaptiveStreakCap: Double {
        switch recurrenceFrequency {
        case .daily:
            return 7.0
        case .weekly:
            return 5.0
        case .monthly:
            return 3.0
        case .yearly:
            return 2.0
        case .none:
            return 5.0
        }
    }

    /// Determines if health is trending up, stable, or down by comparing
    /// the on-time completion rate of recent events vs older events.
    var healthTrend: HealthTrend {
        let completedEvents =
            events
            .filter { $0.eventType == .completed }
            .sorted { $0.completedAt < $1.completedAt }

        // Need at least 4 completed events to determine a meaningful trend
        guard completedEvents.count >= 4 else { return .stable }

        let midpoint = completedEvents.count / 2
        let olderEvents = Array(completedEvents.prefix(midpoint))
        let recentEvents = Array(completedEvents.suffix(from: midpoint))

        let olderRate = onTimeRateFor(events: olderEvents)
        let recentRate = onTimeRateFor(events: recentEvents)

        let threshold = 0.15
        if recentRate > olderRate + threshold {
            return .improving
        } else if recentRate < olderRate - threshold {
            return .declining
        }
        return .stable
    }

    /// The fraction of completed events in the current streak that were
    /// completed on or before the due date (not just within tolerance).
    /// Returns a value from 0.0 to 1.0.
    var onTimeRate: Double {
        let sortedEvents = events.sorted { $0.completedAt < $1.completedAt }
        let streakEvents = recentStreakCompletions(from: sortedEvents)
        guard !streakEvents.isEmpty else { return 0.0 }
        return onTimeRateFor(events: streakEvents)
    }

    /// Calculates the on-time rate for a given set of events.
    /// "On time" means completed on or before the due date (stricter than tolerance).
    private func onTimeRateFor(events: [TodoEvent]) -> Double {
        guard !events.isEmpty else { return 0.0 }
        let onTimeCount = events.filter { wasCompletedOnTime($0) }.count
        return Double(onTimeCount) / Double(events.count)
    }

    /// Checks if an event was completed on or before its due date (strict, no tolerance).
    private func wasCompletedOnTime(_ event: TodoEvent) -> Bool {
        guard event.eventType == .completed else { return false }
        guard let completedAt = event.completedAt as Date?,
            let dueDate = event.previousDueDate
        else {
            return false
        }
        return completedAt <= dueDate
    }

    /// Extracts the completed events that belong to the current streak
    /// (walking backwards from most recent, stopping at the first non-on-time,
    /// non-skipped event — mirroring the streak logic).
    private func recentStreakCompletions(from sortedEvents: [TodoEvent]) -> [TodoEvent] {
        var streakEvents: [TodoEvent] = []
        for event in sortedEvents.reversed() {
            if event.eventType == .completed && wasCompletedWithinReasonableTime(event) {
                streakEvents.append(event)
            } else if event.eventType == .skipped {
                continue
            } else {
                break
            }
        }
        return streakEvents
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
