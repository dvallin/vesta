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
        createEvent(type: .markAsDone, previousDueDate: dueDate, previousIsCompleted: isCompleted)

        if let frequency = recurrenceFrequency {
            updateDueDate(
                for: frequency,
                basedOn: recurrenceType == .fixed ? (dueDate ?? Date()) : Date()
            )
        } else {
            isCompleted = true
        }
    }

    func setDetails(modelContext: ModelContext, details: String) {
        createEvent(type: .editDetails, previousDetails: self.details)
        self.details = details
    }

    func setTitle(modelContext: ModelContext, title: String) {
        createEvent(type: .editTitle, previousTitle: self.title)
        self.title = title
    }

    func setDueDate(modelContext: ModelContext, dueDate: Date?) {
        createEvent(type: .editDueDate, previousDueDate: self.dueDate)
        self.dueDate = dueDate
    }

    func setIsCompleted(modelContext: ModelContext, isCompleted: Bool) {
        createEvent(type: .editIsCompleted, previousIsCompleted: self.isCompleted)
        self.isCompleted = isCompleted
    }

    func setRecurrenceFrequency(
        modelContext: ModelContext, recurrenceFrequency: RecurrenceFrequency?
    ) {
        createEvent(
            type: .editRecurrenceFrequency, previousRecurrenceFrequency: self.recurrenceFrequency)
        self.recurrenceFrequency = recurrenceFrequency
    }

    func setRecurrenceType(modelContext: ModelContext, recurrenceType: RecurrenceType?) {
        createEvent(type: .editRecurrenceType, previousRecurrenceType: self.recurrenceType)
        self.recurrenceType = recurrenceType
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
    }

    private func createEvent(
        type: TodoItemEventType,
        previousTitle: String? = nil,
        previousDetails: String? = nil,
        previousDueDate: Date? = nil,
        previousIsCompleted: Bool? = nil,
        previousRecurrenceFrequency: RecurrenceFrequency? = nil,
        previousRecurrenceType: RecurrenceType? = nil
    ) {
        let event = TodoItemEvent(
            type: type,
            date: Date(),
            todoItem: self,
            previousTitle: previousTitle,
            previousDetails: previousDetails,
            previousDueDate: previousDueDate,
            previousIsCompleted: previousIsCompleted,
            previousRecurrenceFrequency: previousRecurrenceFrequency,
            previousRecurrenceType: previousRecurrenceType
        )
        events.append(event)
    }
}
