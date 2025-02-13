import Foundation
import SwiftData
import SwiftUI

// MARK: - Enums

enum RecurrenceFrequency: String, Codable {
    case daily
    case weekly
    case monthly
    case yearly
}

enum TodoItemEventType: String, Codable {
    case markAsDone
    case delete
    case edit
}

// MARK: - Models

@Model
class TodoItem {
    var title: String
    var details: String
    var dueDate: Date?
    var isCompleted: Bool
    var recurrenceFrequency: RecurrenceFrequency?

    @Relationship(deleteRule: .cascade)
    var events: [TodoItemEvent]

    init(
        title: String, details: String, dueDate: Date?,
        isCompleted: Bool = false, recurrenceFrequency: RecurrenceFrequency? = nil
    ) {
        self.title = title
        self.details = details
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.recurrenceFrequency = recurrenceFrequency
        self.events = []
    }

    init(
        title: String,
        details: String,
        dueDate: Date?,
        isCompleted: Bool = false,
        recurrenceFrequency: RecurrenceFrequency? = nil,
        events: [TodoItemEvent] = []
    ) {
        self.title = title
        self.details = details
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.recurrenceFrequency = recurrenceFrequency
        self.events = events
    }

    // MARK: - Methods

    func markAsDone(modelContext: ModelContext) {
        if let frequency = recurrenceFrequency {
            adjustDueDate(for: frequency)
        } else {
            isCompleted = true
        }
        let event = TodoItemEvent(type: .markAsDone, date: Date())
        events.append(event)
    }

    func delete(modelContext: ModelContext) {
        let event = TodoItemEvent(type: .delete, date: Date())
        events.append(event)
    }

    func edit(
        modelContext: ModelContext,
        title: String? = nil,
        details: String? = nil,
        dueDate: Date? = nil,
        recurrenceFrequency: RecurrenceFrequency? = nil
    ) {
        if let newTitle = title {
            self.title = newTitle
        }
        if let newDetails = details {
            self.details = newDetails
        }
        if let newDueDate = dueDate {
            self.dueDate = newDueDate
        }
        if let freq = recurrenceFrequency {
            self.recurrenceFrequency = freq
        }

        let event = TodoItemEvent(type: .edit, date: Date())
        events.append(event)
    }

    private func adjustDueDate(for frequency: RecurrenceFrequency) {
        guard let currentDueDate = dueDate else { return }
        let calendar = Calendar.current
        switch frequency {
        case .daily:
            dueDate = calendar.date(byAdding: .day, value: 1, to: currentDueDate)
        case .weekly:
            dueDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDueDate)
        case .monthly:
            dueDate = calendar.date(byAdding: .month, value: 1, to: currentDueDate)
        case .yearly:
            dueDate = calendar.date(byAdding: .year, value: 1, to: currentDueDate)
        }
    }
}

@Model
class TodoItemEvent {
    var type: TodoItemEventType
    var date: Date

    // Many-to-one relationship back to the Task that owns this event
    @Relationship(inverse: \TodoItem.events)
    var task: TodoItem?

    init(type: TodoItemEventType, date: Date, task: TodoItem? = nil) {
        self.type = type
        self.date = date
        self.task = task
    }
}
