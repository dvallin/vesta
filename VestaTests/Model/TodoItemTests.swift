import SwiftData
import XCTest

@testable import Vesta

final class TodoItemTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var user: User!

    override func setUp() {
        super.setUp()
        container = try! ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        context = ModelContext(container)

        // Set up the UserService to return our test user
        user = Fixtures.createUser()
        UserService.shared.setCurrentUser(user: user)
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    // MARK: - Creation Tests

    func testCreateTodoItem() throws {
        // Arrange & Act
        let todoItem = TodoItem.create(title: "Test Task", details: "Test Details")
        context.insert(todoItem)

        // Assert
        XCTAssertEqual(todoItem.title, "Test Task")
        XCTAssertEqual(todoItem.details, "Test Details")
        XCTAssertEqual(todoItem.owner?.uid, user.uid)
        XCTAssertFalse(todoItem.isCompleted)
        XCTAssertNil(todoItem.recurrenceFrequency)
        XCTAssertTrue(todoItem.ignoreTimeComponent)
        XCTAssertEqual(todoItem.priority, 4)
        XCTAssertEqual(todoItem.events.count, 1)
        XCTAssertEqual(todoItem.events.first?.type, .created)
        XCTAssertTrue(todoItem.dirty, "New item should be marked as dirty")
    }

    // MARK: - Property Update Tests

    func testSetTitle() throws {
        // Arrange
        let todoItem = TodoItem(
            title: "Initial Title", details: "Details", owner: user!)
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.setTitle(title: "Updated Title")

        // Assert
        XCTAssertEqual(todoItem.title, "Updated Title")
        XCTAssertEqual(todoItem.events.count, 1)
        XCTAssertEqual(todoItem.events.first?.type, .editTitle)
        XCTAssertEqual(todoItem.events.first?.previousTitle, "Initial Title")
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after title change")
    }

    func testSetDetails() throws {
        // Arrange
        let todoItem = TodoItem(
            title: "Task", details: "Initial Details", owner: user!)
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.setDetails(details: "Updated Details")

        // Assert
        XCTAssertEqual(todoItem.details, "Updated Details")
        XCTAssertEqual(todoItem.events.count, 1)
        XCTAssertEqual(todoItem.events.first?.type, .editDetails)
        XCTAssertEqual(todoItem.events.first?.previousDetails, "Initial Details")
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after details change")
    }

    func testSetDueDate() throws {
        // Arrange
        let todoItem = TodoItem(title: "Task", details: "Details", owner: user!)
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag
        let newDate = Date()

        // Act
        todoItem.setDueDate(dueDate: newDate)

        // Assert
        XCTAssertEqual(todoItem.dueDate, newDate)
        XCTAssertEqual(todoItem.events.count, 1)
        XCTAssertEqual(todoItem.events.first?.type, .editDueDate)
        XCTAssertNil(todoItem.events.first?.previousDueDate)
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after due date change")
    }

    func testSetIsCompleted() throws {
        // Arrange
        let todoItem = TodoItem(title: "Task", details: "Details", owner: user!)
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.setIsCompleted(isCompleted: true)

        // Assert
        XCTAssertTrue(todoItem.isCompleted)
        XCTAssertEqual(todoItem.events.count, 1)
        XCTAssertEqual(todoItem.events.first?.type, .editIsCompleted)
        XCTAssertEqual(todoItem.events.first?.previousIsCompleted, false)
        XCTAssertTrue(
            todoItem.dirty, "Item should be marked as dirty after completion status change")
    }

    func testSetRecurrenceFrequency() throws {
        // Arrange
        let todoItem = TodoItem(title: "Task", details: "Details", owner: user!)
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.setRecurrenceFrequency(recurrenceFrequency: .weekly)

        // Assert
        XCTAssertEqual(todoItem.recurrenceFrequency, .weekly)
        XCTAssertEqual(todoItem.events.count, 1)
        XCTAssertEqual(todoItem.events.first?.type, .editRecurrenceFrequency)
        XCTAssertNil(todoItem.events.first?.previousRecurrenceFrequency)
        XCTAssertTrue(
            todoItem.dirty, "Item should be marked as dirty after recurrence frequency change")
    }

    func testSetRecurrenceType() throws {
        // Arrange
        let todoItem = TodoItem(title: "Task", details: "Details", owner: user!)
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.setRecurrenceType(recurrenceType: .fixed)

        // Assert
        XCTAssertEqual(todoItem.recurrenceType, .fixed)
        XCTAssertEqual(todoItem.events.count, 1)
        XCTAssertEqual(todoItem.events.first?.type, .editRecurrenceType)
        XCTAssertNil(todoItem.events.first?.previousRecurrenceType)
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after recurrence type change")
    }

    func testSetRecurrenceInterval() throws {
        // Arrange
        let todoItem = TodoItem(title: "Task", details: "Details", owner: user!)
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.setRecurrenceInterval(recurrenceInterval: 2)

        // Assert
        XCTAssertEqual(todoItem.recurrenceInterval, 2)
        XCTAssertEqual(todoItem.events.count, 1)
        XCTAssertEqual(todoItem.events.first?.type, .editRecurrenceInterval)
        XCTAssertNil(todoItem.events.first?.previousRecurrenceInterval)
        XCTAssertTrue(
            todoItem.dirty, "Item should be marked as dirty after recurrence interval change")
    }

    func testSetIgnoreTimeComponent() throws {
        // Arrange
        let todoItem = TodoItem(
            title: "Task", details: "Details", ignoreTimeComponent: true,
            owner: user!)
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.setIgnoreTimeComponent(ignoreTimeComponent: false)

        // Assert
        XCTAssertFalse(todoItem.ignoreTimeComponent)
        XCTAssertEqual(todoItem.events.count, 1)
        XCTAssertEqual(todoItem.events.first?.type, .editIgnoreTimeComponent)
        XCTAssertEqual(todoItem.events.first?.previousIgnoreTimeComponent, true)
        XCTAssertTrue(
            todoItem.dirty, "Item should be marked as dirty after ignore time component change")
    }

    func testSetPriority() throws {
        // Arrange
        let todoItem = TodoItem(
            title: "Task", details: "Details", priority: 3, owner: user!)
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.setPriority(priority: 1)

        // Assert
        XCTAssertEqual(todoItem.priority, 1)
        XCTAssertEqual(todoItem.events.count, 1)
        XCTAssertEqual(todoItem.events.first?.type, .editPriority)
        XCTAssertEqual(todoItem.events.first?.previousPriority, 3)
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after priority change")
    }

    func testSetCategory() throws {
        // Arrange
        let todoItem = TodoItem(title: "Task", details: "Details", owner: user!)
        let category = TodoItemCategory(name: "Test Category")
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.setCategory(category: category)

        // Assert
        XCTAssertEqual(todoItem.category?.name, "Test Category")
        XCTAssertEqual(todoItem.events.count, 1)
        XCTAssertEqual(todoItem.events.first?.type, .editCategory)
        XCTAssertNil(todoItem.events.first?.previousCategory)
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after category change")
    }

    // MARK: - Date Status Tests

    func testIsToday() throws {
        // Arrange - Today
        let todayItem = TodoItem(
            title: "Today", details: "",
            dueDate: Date(),
            owner: user!)

        // Arrange - Tomorrow
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let tomorrowItem = TodoItem(
            title: "Tomorrow", details: "",
            dueDate: tomorrow,
            owner: user!)

        // Assert
        XCTAssertTrue(todayItem.isToday, "Item due today should return true for isToday")
        XCTAssertFalse(tomorrowItem.isToday, "Item due tomorrow should return false for isToday")
    }

    func testIsCurrentWeek() throws {
        // Arrange - Today
        let user = user
        let todayItem = TodoItem(
            title: "Today", details: "",
            dueDate: Date(),
            owner: user!)

        // Arrange - Next Week
        let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())!
        let nextWeekItem = TodoItem(
            title: "Next Week", details: "",
            dueDate: nextWeek,
            owner: user!)

        // Assert
        XCTAssertTrue(todayItem.isCurrentWeek, "Item due today should be in current week")
        XCTAssertFalse(
            nextWeekItem.isCurrentWeek, "Item due next week should not be in current week")
    }

    func testIsOverdue() throws {
        // Arrange - Yesterday with time component ignored
        let user = user
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let overdueItem = TodoItem(
            title: "Overdue", details: "",
            dueDate: yesterday,
            ignoreTimeComponent: true,
            owner: user!)

        // Arrange - Yesterday with time component not ignored
        let overdueWithTimeItem = TodoItem(
            title: "Overdue with time", details: "",
            dueDate: yesterday,
            ignoreTimeComponent: false,
            owner: user!)

        // Arrange - Today but completed
        let completedItem = TodoItem(
            title: "Completed", details: "",
            dueDate: yesterday,
            isCompleted: true,
            owner: user!)

        // Assert
        XCTAssertTrue(overdueItem.isOverdue, "Item due yesterday should be overdue")
        XCTAssertTrue(
            overdueWithTimeItem.isOverdue, "Item due yesterday with time should be overdue")
        XCTAssertFalse(completedItem.isOverdue, "Completed item should not be overdue")
    }

    func testNeedsReschedule() throws {
        // Arrange - Yesterday
        let user = user
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let overdueItem = TodoItem(
            title: "Overdue", details: "",
            dueDate: yesterday,
            owner: user!)

        // Arrange - Today
        let todayItem = TodoItem(
            title: "Today", details: "",
            dueDate: Date(),
            owner: user!)

        // Assert
        XCTAssertTrue(overdueItem.needsReschedule, "Overdue item should need reschedule")
        XCTAssertFalse(todayItem.needsReschedule, "Today's item should not need reschedule")
    }

    // MARK: - Recurrence Tests

    func testMarkAsDoneWithNoRecurrence() throws {
        // Arrange
        let todoItem = TodoItem(title: "Task", details: "Details", owner: user!)
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.markAsDone()

        // Assert
        XCTAssertTrue(todoItem.isCompleted, "Item should be marked completed")
        XCTAssertEqual(todoItem.events.count, 1)
        XCTAssertEqual(todoItem.events.first?.type, .markAsDone)
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after being marked as done")
    }

    func testMarkAsDoneWithDailyRecurrence() throws {
        // Arrange
        let today = Date()
        let todoItem = TodoItem(
            title: "Daily Task",
            details: "Details",
            dueDate: today,
            recurrenceFrequency: .daily,
            recurrenceInterval: 1,
            owner: user!
        )
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.markAsDone()

        // Assert
        XCTAssertFalse(todoItem.isCompleted, "Recurring item should not be marked as completed")

        // Check if the due date is now tomorrow
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let dueDateComponents = Calendar.current.dateComponents(
            [.year, .month, .day], from: todoItem.dueDate!)
        let tomorrowComponents = Calendar.current.dateComponents(
            [.year, .month, .day], from: tomorrow)

        XCTAssertEqual(dueDateComponents.year, tomorrowComponents.year)
        XCTAssertEqual(dueDateComponents.month, tomorrowComponents.month)
        XCTAssertEqual(dueDateComponents.day, tomorrowComponents.day)
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after being marked as done")
    }

    func testMarkAsDoneWithWeeklyRecurrence() throws {
        // Arrange
        let today = Date()
        let todoItem = TodoItem(
            title: "Weekly Task",
            details: "Details",
            dueDate: today,
            recurrenceFrequency: .weekly,
            recurrenceInterval: 1,
            owner: user!
        )
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.markAsDone()

        // Assert
        XCTAssertFalse(todoItem.isCompleted, "Recurring item should not be marked as completed")

        // Check if the due date is now next week
        let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: today)!
        let dueDateComponents = Calendar.current.dateComponents(
            [.year, .month, .day], from: todoItem.dueDate!)
        let nextWeekComponents = Calendar.current.dateComponents(
            [.year, .month, .day], from: nextWeek)

        XCTAssertEqual(dueDateComponents.year, nextWeekComponents.year)
        XCTAssertEqual(dueDateComponents.month, nextWeekComponents.month)
        XCTAssertEqual(dueDateComponents.day, nextWeekComponents.day)
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after being marked as done")
    }

    func testMarkAsDoneWithFlexibleRecurrence() throws {
        // Arrange
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let todoItem = TodoItem(
            title: "Flexible Task",
            details: "Details",
            dueDate: yesterday,
            recurrenceFrequency: .daily,
            recurrenceType: .flexible,
            recurrenceInterval: 1,
            owner: user!
        )
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.markAsDone()

        // Assert
        // Due date should be based on completion time, not the original due date
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let dueDateComponents = Calendar.current.dateComponents(
            [.year, .month, .day], from: todoItem.dueDate!)
        let tomorrowComponents = Calendar.current.dateComponents(
            [.year, .month, .day], from: tomorrow)

        XCTAssertEqual(dueDateComponents.year, tomorrowComponents.year)
        XCTAssertEqual(dueDateComponents.month, tomorrowComponents.month)
        XCTAssertEqual(dueDateComponents.day, tomorrowComponents.day)
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after being marked as done")
    }

    func testMarkAsDoneWithFixedRecurrence() throws {
        // Arrange
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let todoItem = TodoItem(
            title: "Fixed Task",
            details: "Details",
            dueDate: yesterday,
            recurrenceFrequency: .daily,
            recurrenceType: .fixed,
            recurrenceInterval: 1,
            owner: user!
        )
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.markAsDone()

        // Assert
        // Due date should be based on the original due date
        let today = Calendar.current.date(byAdding: .day, value: 1, to: yesterday)!
        let dueDateComponents = Calendar.current.dateComponents(
            [.year, .month, .day], from: todoItem.dueDate!)
        let todayComponents = Calendar.current.dateComponents([.year, .month, .day], from: today)

        XCTAssertEqual(dueDateComponents.year, todayComponents.year)
        XCTAssertEqual(dueDateComponents.month, todayComponents.month)
        XCTAssertEqual(dueDateComponents.day, todayComponents.day)
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after being marked as done")
    }

    // MARK: - Undo Tests

    func testUndoLastEvent() throws {
        // Arrange
        let todoItem = TodoItem(
            title: "Original Title", details: "Original Details", owner: user!)
        context.insert(todoItem)
        todoItem.setTitle(title: "Updated Title")
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        let undoneEvent = todoItem.undoLastEvent()

        // Assert
        XCTAssertEqual(todoItem.title, "Original Title", "Title should be restored to original")
        XCTAssertEqual(todoItem.events.count, 0, "Event should be removed")
        XCTAssertEqual(
            undoneEvent?.type, .editTitle, "Returned event should be the edit title event")
        XCTAssertEqual(
            undoneEvent?.previousTitle, "Original Title", "Previous title in event should match")
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after undoing an event")
    }

    func testUndoMultipleEvents() throws {
        // Arrange
        let todoItem = TodoItem(
            title: "Original Title", details: "Original Details", owner: user!)
        context.insert(todoItem)
        todoItem.setTitle(title: "Updated Title")
        todoItem.setDetails(details: "Updated Details")
        todoItem.setPriority(priority: 1)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act & Assert - First undo (priority)
        var undoneEvent = todoItem.undoLastEvent()
        XCTAssertEqual(undoneEvent?.type, .editPriority)
        XCTAssertEqual(todoItem.priority, 4)
        XCTAssertTrue(
            todoItem.dirty, "Item should be marked as dirty after undoing priority change")

        todoItem.markAsSynced()  // Reset dirty flag

        // Act & Assert - Second undo (details)
        undoneEvent = todoItem.undoLastEvent()
        XCTAssertEqual(undoneEvent?.type, .editDetails)
        XCTAssertEqual(todoItem.details, "Original Details")
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after undoing details change")

        todoItem.markAsSynced()  // Reset dirty flag

        // Act & Assert - Third undo (title)
        undoneEvent = todoItem.undoLastEvent()
        XCTAssertEqual(undoneEvent?.type, .editTitle)
        XCTAssertEqual(todoItem.title, "Original Title")
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after undoing title change")

        todoItem.markAsSynced()  // Reset dirty flag

        // Act & Assert - No more events to undo
        undoneEvent = todoItem.undoLastEvent()
        XCTAssertNil(undoneEvent)
        XCTAssertFalse(todoItem.dirty, "Item should not be dirty when no event was undone")
    }

    // MARK: - Integration Tests

    func testTimeComponentBehavior() throws {
        // Arrange
        let now = Date()
        let todoItem = TodoItem(
            title: "Task",
            details: "Details",
            dueDate: now,
            ignoreTimeComponent: false,  // Start with false
            owner: user!
        )
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act & Assert - With ignoreTimeComponent = false
        todoItem.setDueDate(dueDate: now)
        XCTAssertNotEqual(
            Calendar.current.startOfDay(for: todoItem.dueDate!),
            todoItem.dueDate!,
            "Due date should preserve time when ignoreTimeComponent is false"
        )
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after due date change")

        todoItem.markAsSynced()  // Reset dirty flag

        // Act & Assert - Setting ignoreTimeComponent to true should convert date
        todoItem.setIgnoreTimeComponent(ignoreTimeComponent: true)
        XCTAssertEqual(
            Calendar.current.startOfDay(for: todoItem.dueDate!),
            todoItem.dueDate!,
            "Due date should be start of day after setting ignoreTimeComponent to true"
        )
        XCTAssertTrue(
            todoItem.dirty, "Item should be marked as dirty after ignore time component change")

        todoItem.markAsSynced()  // Reset dirty flag

        // Act & Assert - New dates while ignoreTimeComponent is true
        let newDate = Date().addingTimeInterval(3600)  // one hour later
        todoItem.setDueDate(dueDate: newDate)
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after due date change")
    }

    func testSyncableBehavior() throws {
        // Arrange
        let todoItem = TodoItem(title: "Task", details: "Details", owner: user!)
        context.insert(todoItem)

        // Act
        todoItem.setTitle(title: "New Title")

        // Assert
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after modification")

        // Act
        todoItem.markAsSynced()

        // Assert
        XCTAssertFalse(todoItem.dirty, "Item should not be dirty after marked as synced")

        // Act
        todoItem.setPriority(priority: 1)

        // Assert
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after another modification")
    }
}
