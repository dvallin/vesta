import Foundation
import SwiftData
import SwiftUI

enum RecurrenceFrequency: String, Codable {
    case daily, weekly, monthly, yearly
}

enum RecurrenceType: String, Codable {
    case fixed, flexible
}

@Model
class TodoItem {
    var title: String
    var details: String
    var dueDate: Date?
    var isCompleted: Bool
    var recurrenceFrequency: RecurrenceFrequency?
    var recurrenceType: RecurrenceType?

    @Relationship(deleteRule: .cascade)
    var events: [TodoItemEvent]

    init(
        title: String,
        details: String,
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        recurrenceFrequency: RecurrenceFrequency? = nil,
        recurrenceType: RecurrenceType? = nil,
        events: [TodoItemEvent] = []
    ) {
        self.title = title
        self.details = details
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.recurrenceFrequency = recurrenceFrequency
        self.recurrenceType = recurrenceType
        self.events = events
    }

    func markAsDone(modelContext: ModelContext) {
        let event = TodoItemEvent(type: .markAsDone, date: Date(), todoItem: self)
        events.append(event)

        if let frequency = recurrenceFrequency {
            updateDueDate(
                for: frequency,
                basedOn: recurrenceType == .fixed ? (dueDate ?? event.date) : event.date)
        } else {
            isCompleted = true
        }
    }

    func setDetails(
        modelContext: ModelContext,
        details: String
    ) {
        let event = TodoItemEvent(type: .edit, date: Date(), todoItem: self)
        events.append(event)
        self.details = details
    }

    func setTitle(
        modelContext: ModelContext,
        title: String
    ) {
        let event = TodoItemEvent(type: .edit, date: Date(), todoItem: self)
        events.append(event)
        self.title = title
    }

    func setDueDate(modelContext: ModelContext, dueDate: Date?) {
        let event = TodoItemEvent(type: .edit, date: Date(), todoItem: self)
        events.append(event)
        self.dueDate = dueDate
    }

    func setRecurrenceFrequency(
        modelContext: ModelContext, recurrenceFrequency: RecurrenceFrequency?
    ) {
        let event = TodoItemEvent(type: .edit, date: Date(), todoItem: self)
        events.append(event)
        self.recurrenceFrequency = recurrenceFrequency
    }

    func setRecurrenceType(modelContext: ModelContext, recurrenceType: RecurrenceType?) {
        let event = TodoItemEvent(type: .edit, date: Date(), todoItem: self)
        events.append(event)
        self.recurrenceType = recurrenceType
    }

    func undoLastEvent(modelContext: ModelContext) {
        guard let lastEvent = events.popLast() else { return }

        self.title = lastEvent.snapshotTitle
        self.details = lastEvent.snapshotDetails
        self.dueDate = lastEvent.snapshotDueDate
        self.isCompleted = lastEvent.snapshotIsCompleted
        self.recurrenceFrequency = lastEvent.snapshotRecurrenceFrequency
        self.recurrenceType = lastEvent.snapshotRecurrenceType
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
    }
}
