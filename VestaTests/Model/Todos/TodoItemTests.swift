import SwiftData
import XCTest

@testable import Vesta

class TodoItemTests: XCTestCase {

    private var modelContainer: ModelContainer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        modelContainer = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        try super.tearDownWithError()
    }

    func testInitialization() {
        // Given that a TodoItem is initialized
        let todo = TodoItem(title: "Test Task", details: "Details", dueDate: nil)

        // Then the fields should be set correctly
        XCTAssertEqual(todo.title, "Test Task")
        XCTAssertEqual(todo.details, "Details")
        XCTAssertNil(todo.dueDate)
        XCTAssertFalse(todo.isCompleted)
        XCTAssertNil(todo.recurrenceFrequency)
        XCTAssertTrue(todo.events.isEmpty)
    }

    func testMarkAsDoneWithoutRecurrence() {
        // Given that a TodoItem is created without recurrence
        let todo = TodoItem(title: "Test Task", details: "Details", dueDate: nil)
        let modelContext = ModelContext(modelContainer)

        // When the item is marked as done
        todo.markAsDone(modelContext: modelContext)

        // Then the item should be marked as completed
        XCTAssertTrue(todo.isCompleted)
        // And an event should be recorded
        XCTAssertEqual(todo.events.count, 1)
        XCTAssertEqual(todo.events.first?.type, .markAsDone)
    }

    func testMarkAsDoneWithDailyRecurrence() {
        // Given that a TodoItem is created with daily recurrence
        let dueDate = Date()
        let todo = TodoItem(
            title: "Test Task",
            details: "Details",
            dueDate: dueDate,
            recurrenceFrequency: .daily
        )
        let modelContext = ModelContext(modelContainer)

        // When the item is marked as done
        todo.markAsDone(modelContext: modelContext)

        // Then the item should not be marked as completed
        XCTAssertFalse(todo.isCompleted)
        // And an event should be recorded
        XCTAssertEqual(todo.events.count, 1)
        XCTAssertEqual(todo.events.first?.type, .markAsDone)
        // And the due date should be updated to the next day
        let expectedDueDate = Calendar.current.date(
            byAdding: .day, value: 1, to: todo.events.first!.date)!
        XCTAssertEqual(todo.dueDate, expectedDueDate)
    }

    func testMarkAsDoneWithDailyFixedRecurrence() {
        // Given that a TodoItem is created with daily fixed recurrence
        let calendar = Calendar.current
        let originalDueDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
        let todo = TodoItem(
            title: "Fixed Daily Task",
            details: "Details",
            dueDate: originalDueDate,
            recurrenceFrequency: .daily,
            recurrenceType: .fixed
        )
        let modelContext = ModelContext(modelContainer)

        // When the item is marked as done
        todo.markAsDone(modelContext: modelContext)

        // Then the due date should be updated to the next day at the same time
        let expectedNewDueDate = calendar.date(byAdding: .day, value: 1, to: originalDueDate)
        XCTAssertEqual(todo.dueDate, expectedNewDueDate)
        // And the item should not be marked as completed
        XCTAssertFalse(todo.isCompleted)
    }
    
    func testMarkAsDoneWithDailyFlexibleRecurrence() {
        // Given that a TodoItem is created with daily flexible recurrence
        let originalDueDate = Calendar.current.date(
            bySettingHour: 9, minute: 0, second: 0, of: Date())!
        let todo = TodoItem(
            title: "Flexible Daily Task",
            details: "Details",
            dueDate: originalDueDate,
            recurrenceFrequency: .daily,
            recurrenceType: .flexible
        )
        let modelContext = ModelContext(modelContainer)

        // When the item is marked as done
        todo.markAsDone(modelContext: modelContext)

        // Then the due date should be updated to one day from the event date
        let eventDate = todo.events.first!.date
        let expectedDueDate = Calendar.current.date(byAdding: .day, value: 1, to: eventDate)!
        XCTAssertEqual(
            todo.dueDate,
            expectedDueDate,
            "Due date should be about 1 day from the event date.")
        // And the item should not be marked as completed
        XCTAssertFalse(todo.isCompleted)
    }

    func testEdit() {
        // Given that a TodoItem is created
        let todo = TodoItem(title: "Test Task", details: "Details", dueDate: nil)
        let modelContext = ModelContext(modelContainer)
        let newTitle = "New Title"
        let newDetails = "New Details"
        let newDueDate = Date()
        let newRecurrenceFrequency: RecurrenceFrequency = .weekly
        let newRecurrenceType: RecurrenceType = .flexible

        // When the item is edited
        todo.setTitle(modelContext: modelContext, title: newTitle)
        todo.setDetails(modelContext: modelContext, details: newDetails)
        todo.setDueDate(modelContext: modelContext, dueDate: newDueDate)
        todo.setRecurrenceFrequency(
            modelContext: modelContext, recurrenceFrequency: newRecurrenceFrequency)
        todo.setRecurrenceType(modelContext: modelContext, recurrenceType: newRecurrenceType)

        // Then the fields should be updated
        XCTAssertEqual(todo.title, newTitle)
        XCTAssertEqual(todo.details, newDetails)
        XCTAssertEqual(todo.dueDate, newDueDate)
        XCTAssertEqual(todo.recurrenceFrequency, newRecurrenceFrequency)
        XCTAssertEqual(todo.recurrenceType, newRecurrenceType)
        // And events should be recorded
        XCTAssertEqual(todo.events.count, 5)
        XCTAssertEqual(todo.events[0].type, .editTitle)
        XCTAssertEqual(todo.events[1].type, .editDetails)
        XCTAssertEqual(todo.events[2].type, .editDueDate)
        XCTAssertEqual(todo.events[3].type, .editRecurrenceFrequency)
        XCTAssertEqual(todo.events[4].type, .editRecurrenceType)
    }

    func testUndoLastEvent() {
        // Given that a TodoItem is created
        let todo = TodoItem(title: "Test Task", details: "Details", dueDate: nil)
        let modelContext = ModelContext(modelContainer)

        // And that the item is marked as done
        todo.markAsDone(modelContext: modelContext)

        // Then the item should be marked as completed
        XCTAssertTrue(todo.isCompleted)
        // And an event should be recorded
        XCTAssertEqual(todo.events.count, 1)
        XCTAssertEqual(todo.events.first?.type, .markAsDone)

        // When the last event is undone
        todo.undoLastEvent(modelContext: modelContext)

        // Then the item should be marked as not completed
        XCTAssertFalse(todo.isCompleted)
        // And the events should be empty
        XCTAssertTrue(todo.events.isEmpty)

        // Given that the item is edited
        let newTitle = "New Title"
        todo.setTitle(modelContext: modelContext, title: newTitle)

        // Then the title should be updated
        XCTAssertEqual(todo.title, newTitle)
        // And an event should be recorded
        XCTAssertEqual(todo.events.count, 1)
        XCTAssertEqual(todo.events.first?.type, .editTitle)

        // When the last event is undone
        todo.undoLastEvent(modelContext: modelContext)

        // Then the title should be reverted to the original
        XCTAssertEqual(todo.title, "Test Task")
        // And the events should be empty
        XCTAssertTrue(todo.events.isEmpty)
    }
}
