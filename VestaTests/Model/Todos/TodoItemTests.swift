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
        let todo = TodoItem(title: "Test Task", details: "Details", dueDate: nil)
        XCTAssertEqual(todo.title, "Test Task")
        XCTAssertEqual(todo.details, "Details")
        XCTAssertNil(todo.dueDate)
        XCTAssertFalse(todo.isCompleted)
        XCTAssertNil(todo.recurrenceFrequency)
        XCTAssertTrue(todo.events.isEmpty)
    }

    func testMarkAsDoneWithoutRecurrence() {
        let todo = TodoItem(title: "Test Task", details: "Details", dueDate: nil)
        let modelContext = ModelContext(modelContainer)
        todo.markAsDone(modelContext: modelContext)
        XCTAssertTrue(todo.isCompleted)
        XCTAssertEqual(todo.events.count, 1)
        XCTAssertEqual(todo.events.first?.type, .markAsDone)
    }

    func testMarkAsDoneWithDailyRecurrence() {
        let dueDate = Date()
        let todo = TodoItem(
            title: "Test Task", details: "Details", dueDate: dueDate, recurrenceFrequency: .daily)
        let modelContext = ModelContext(modelContainer)
        todo.markAsDone(modelContext: modelContext)
        XCTAssertFalse(todo.isCompleted)
        XCTAssertEqual(todo.events.count, 1)
        XCTAssertEqual(todo.events.first?.type, .markAsDone)
        XCTAssertEqual(Calendar.current.date(byAdding: .day, value: 1, to: dueDate), todo.dueDate)
    }

    func testDelete() {
        let todo = TodoItem(title: "Test Task", details: "Details", dueDate: nil)
        let modelContext = ModelContext(modelContainer)
        todo.delete(modelContext: modelContext)
        XCTAssertEqual(todo.events.count, 1)
        XCTAssertEqual(todo.events.first?.type, .delete)
    }

    func testEdit() {
        let todo = TodoItem(title: "Test Task", details: "Details", dueDate: nil)
        let modelContext = ModelContext(modelContainer)
        let newTitle = "New Title"
        let newDetails = "New Details"
        let newDueDate = Date()
        let newRecurrenceFrequency: RecurrenceFrequency = .weekly

        todo.edit(
            modelContext: modelContext, title: newTitle, details: newDetails, dueDate: newDueDate,
            recurrenceFrequency: newRecurrenceFrequency)

        XCTAssertEqual(todo.title, newTitle)
        XCTAssertEqual(todo.details, newDetails)
        XCTAssertEqual(todo.dueDate, newDueDate)
        XCTAssertEqual(todo.recurrenceFrequency, newRecurrenceFrequency)
        XCTAssertEqual(todo.events.count, 1)
        XCTAssertEqual(todo.events.first?.type, .edit)
    }
}
