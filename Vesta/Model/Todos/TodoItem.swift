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
    var ignoreTimeComponent: Bool

    @Relationship(deleteRule: .cascade)
    var events: [TodoItemEvent]

    init(
        title: String,
        details: String,
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        recurrenceFrequency: RecurrenceFrequency? = nil,
        recurrenceType: RecurrenceType? = nil,
        events: [TodoItemEvent] = [],
        ignoreTimeComponent: Bool = true
    ) {
        self.title = title
        self.details = details
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.recurrenceFrequency = recurrenceFrequency
        self.recurrenceType = recurrenceType
        self.events = events
        self.ignoreTimeComponent = ignoreTimeComponent
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

    func markAsDone(modelContext: ModelContext) {
        let event = createEvent(
            type: .markAsDone, previousDueDate: dueDate, previousIsCompleted: isCompleted)

        if let frequency = recurrenceFrequency {
            updateDueDate(
                for: frequency,
                basedOn: recurrenceType == .fixed ? (dueDate ?? event.date) : event.date
            )
        } else {
            isCompleted = true
        }
    }

    func setDetails(modelContext: ModelContext, details: String) {
        let _ = createEvent(type: .editDetails, previousDetails: self.details)
        self.details = details
    }

    func setTitle(modelContext: ModelContext, title: String) {
        let _ = createEvent(type: .editTitle, previousTitle: self.title)
        self.title = title
    }

    func setDueDate(modelContext: ModelContext, dueDate: Date?) {
        let _ = createEvent(type: .editDueDate, previousDueDate: self.dueDate)
        self.dueDate = dueDate
    }

    func setIsCompleted(modelContext: ModelContext, isCompleted: Bool) {
        let _ = createEvent(type: .editIsCompleted, previousIsCompleted: self.isCompleted)
        self.isCompleted = isCompleted
    }

    func setRecurrenceFrequency(
        modelContext: ModelContext, recurrenceFrequency: RecurrenceFrequency?
    ) {
        let _ = createEvent(
            type: .editRecurrenceFrequency, previousRecurrenceFrequency: self.recurrenceFrequency)
        self.recurrenceFrequency = recurrenceFrequency
    }

    func setRecurrenceType(modelContext: ModelContext, recurrenceType: RecurrenceType?) {
        let _ = createEvent(type: .editRecurrenceType, previousRecurrenceType: self.recurrenceType)
        self.recurrenceType = recurrenceType
    }

    func setIgnoreTimeComponent(modelContext: ModelContext, ignoreTimeComponent: Bool) {
        let _ = createEvent(
            type: .editIgnoreTimeComponent, previousIgnoreTimeComponent: self.ignoreTimeComponent)
        self.ignoreTimeComponent = ignoreTimeComponent

        if ignoreTimeComponent, let dueDate = self.dueDate {
            self.dueDate = DateUtils.calendar.startOfDay(for: dueDate)
        }
    }

    func undoLastEvent(modelContext: ModelContext) {
        guard let lastEvent = events.popLast() else { return }

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
        case .editIgnoreTimeComponent:
            self.ignoreTimeComponent =
                lastEvent.previousIgnoreTimeComponent ?? self.ignoreTimeComponent
        }

        modelContext.delete(lastEvent)
    }

    private func updateDueDate(for frequency: RecurrenceFrequency, basedOn baseDate: Date) {
        let calendar = Calendar.current

        switch frequency {
        case .daily:
            dueDate = calendar.date(byAdding: .day, value: 1, to: baseDate)
        case .weekly:
            dueDate = calendar.date(byAdding: .weekOfYear, value: 1, to: baseDate)
        case .monthly:
            dueDate = calendar.date(byAdding: .month, value: 1, to: baseDate)
        case .yearly:
            dueDate = calendar.date(byAdding: .year, value: 1, to: baseDate)
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
        previousIgnoreTimeComponent: Bool? = nil
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
            previousIgnoreTimeComponent: previousIgnoreTimeComponent
        )
        events.append(event)
        return event
    }
}
