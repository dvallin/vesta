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

        // Set up the UserAuthService to return our test user
        user = Fixtures.createUser()
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    // MARK: - Creation Tests

    func testCreateTodoItem() throws {
        // Arrange & Act
        let todoItem = TodoItem.create(
            title: "Test Task",
            details: "Test Details",
            owner: user
        )
        context.insert(todoItem)

        // Assert
        XCTAssertEqual(todoItem.title, "Test Task")
        XCTAssertEqual(todoItem.details, "Test Details")
        XCTAssertEqual(todoItem.owner?.uid, user.uid)
        XCTAssertFalse(todoItem.isCompleted)
        XCTAssertNil(todoItem.recurrenceFrequency)
        XCTAssertTrue(todoItem.ignoreTimeComponent)
        XCTAssertEqual(todoItem.priority, 4)
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
        todoItem.setTitle(title: "Updated Title", currentUser: user)

        // Assert
        XCTAssertEqual(todoItem.title, "Updated Title")
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after title change")
    }

    func testSetDetails() throws {
        // Arrange
        let todoItem = TodoItem(
            title: "Task", details: "Initial Details", owner: user!)
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.setDetails(details: "Updated Details", currentUser: user)

        // Assert
        XCTAssertEqual(todoItem.details, "Updated Details")
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after details change")
    }

    func testSetDueDate() throws {
        // Arrange
        let todoItem = TodoItem(
            title: "Task", details: "Details", owner: user!)
        context.insert(todoItem)
        let today = Date()
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.setDueDate(dueDate: today, currentUser: user)

        // Assert
        XCTAssertNotNil(todoItem.dueDate)
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after due date change")
    }

    func testSetIsCompleted() throws {
        // Arrange
        let todoItem = TodoItem(title: "Task", details: "Details", owner: user!)
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.setIsCompleted(isCompleted: true, currentUser: user)

        // Assert
        XCTAssertTrue(todoItem.isCompleted)
        XCTAssertTrue(
            todoItem.dirty, "Item should be marked as dirty after completion status change")
    }

    func testSetRecurrenceFrequency() throws {
        // Arrange
        let todoItem = TodoItem(title: "Task", details: "Details", owner: user!)
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.setRecurrenceFrequency(recurrenceFrequency: .weekly, currentUser: user)

        // Assert
        XCTAssertEqual(todoItem.recurrenceFrequency, .weekly)
        XCTAssertTrue(
            todoItem.dirty, "Item should be marked as dirty after recurrence frequency change")
    }

    func testSetRecurrenceType() throws {
        // Arrange
        let todoItem = TodoItem(title: "Task", details: "Details", owner: user!)
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.setRecurrenceType(recurrenceType: .fixed, currentUser: user)

        // Assert
        XCTAssertEqual(todoItem.recurrenceType, .fixed)
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after recurrence type change")
    }

    func testSetRecurrenceInterval() throws {
        // Arrange
        let todoItem = TodoItem(title: "Task", details: "Details", owner: user!)
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.setRecurrenceInterval(recurrenceInterval: 2, currentUser: user)

        // Assert
        XCTAssertEqual(todoItem.recurrenceInterval, 2)
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
        todoItem.setIgnoreTimeComponent(ignoreTimeComponent: false, currentUser: user)

        // Assert
        XCTAssertFalse(todoItem.ignoreTimeComponent)
        XCTAssertTrue(
            todoItem.dirty, "Item should be marked as dirty after ignore time component change")
    }

    func testSetPriority() throws {
        // Arrange
        let todoItem = TodoItem(title: "Task", details: "Details", priority: 3, owner: user!)
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.setPriority(priority: 1, currentUser: user)

        // Assert
        XCTAssertEqual(todoItem.priority, 1)
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after priority change")
    }

    func testSetCategory() throws {
        // Arrange
        let todoItem = TodoItem(title: "Task", details: "Details", owner: user!)
        let category = TodoItemCategory(name: "Test Category")
        context.insert(todoItem)
        todoItem.markAsSynced()  // Reset dirty flag

        // Act
        todoItem.setCategory(category: category, currentUser: user)

        // Assert
        XCTAssertEqual(todoItem.category?.name, "Test Category")
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
        todoItem.markAsDone(currentUser: user)

        // Assert
        XCTAssertTrue(todoItem.isCompleted, "Item should be marked completed")
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
        todoItem.markAsDone(currentUser: user)

        // Assert
        XCTAssertFalse(todoItem.isCompleted, "Recurring item should not be marked as completed")

        // Now should be set to today since it's a flexible recurrence
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
        todoItem.markAsDone(currentUser: user)

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
        todoItem.markAsDone(currentUser: user)

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
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
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
        todoItem.markAsDone(currentUser: user)

        // Assert
        // Due date should be based on the original due date
        let today = Calendar.current.date(byAdding: .day, value: 1, to: yesterday)!
        let dueDateComponents = Calendar.current.dateComponents(
            [.year, .month, .day], from: todoItem.dueDate!)
        let tomorrowComponents = Calendar.current.dateComponents(
            [.year, .month, .day], from: tomorrow)

        XCTAssertEqual(dueDateComponents.year, tomorrowComponents.year)
        XCTAssertEqual(dueDateComponents.month, tomorrowComponents.month)
        XCTAssertEqual(dueDateComponents.day, tomorrowComponents.day)
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after being marked as done")
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
        todoItem.setDueDate(dueDate: now, currentUser: user)
        XCTAssertNotEqual(
            Calendar.current.startOfDay(for: todoItem.dueDate!),
            todoItem.dueDate!,
            "Due date should preserve time when ignoreTimeComponent is false"
        )
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after due date change")

        todoItem.markAsSynced()  // Reset dirty flag

        // Act & Assert - Setting ignoreTimeComponent to true should convert date
        todoItem.setIgnoreTimeComponent(ignoreTimeComponent: true, currentUser: user)
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
        todoItem.setDueDate(dueDate: newDate, currentUser: user)
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after due date change")
    }

    func testSyncableBehavior() throws {
        // Arrange
        let todoItem = TodoItem(title: "Task", details: "Details", owner: user!)
        context.insert(todoItem)

        // Act
        todoItem.setTitle(title: "New Title", currentUser: user)

        // Assert
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after modification")

        // Act
        todoItem.markAsSynced()

        // Assert
        XCTAssertFalse(todoItem.dirty, "Item should not be dirty after marked as synced")

        // Act
        todoItem.setPriority(priority: 1, currentUser: user)

        // Assert
        XCTAssertTrue(todoItem.dirty, "Item should be marked as dirty after another modification")
    }

    func testFixedRecurrenceWithReschedule() throws {
        // Arrange
        let calendar = Calendar.current
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: yesterday)!

        let item = TodoItem(
            title: "Weekly Task",
            details: "Weekly recurring task",
            dueDate: yesterday,
            isCompleted: false,
            recurrenceFrequency: .weekly,
            recurrenceType: .fixed,
            recurrenceInterval: 1,
            owner: user
        )

        // Act - Reschedule from yesterday to tomorrow
        item.setRescheduleDate(rescheduleDate: tomorrow, currentUser: user)

        // Complete the task
        item.markAsDone(currentUser: user)

        // Assert - Next occurrence should maintain weekly pattern from original date
        XCTAssertNotNil(item.dueDate)

        // The next occurrence should be scheduled for next week (7 days from yesterday)
        let dueComponents = calendar.dateComponents([.year, .month, .day], from: item.dueDate!)
        let expectedComponents = calendar.dateComponents(
            [.year, .month, .day], from: nextWeek)

        XCTAssertEqual(dueComponents.year, expectedComponents.year)
        XCTAssertEqual(dueComponents.month, expectedComponents.month)
        XCTAssertEqual(dueComponents.day, expectedComponents.day)

        // Reschedule date should be cleared after completion
        XCTAssertNil(item.rescheduleDate)
    }

    func testMarkAsDoneWithOldFixedRecurrence() throws {
        // Arrange
        let calendar = Calendar.current

        // Create a reference date for stable testing
        let now = Date()

        // Create a specific day in the current month
        let dayOfMonth = 15
        var currentMonthComponents = calendar.dateComponents([.year, .month], from: now)
        currentMonthComponents.day = dayOfMonth
        let currentMonthDate = calendar.date(from: currentMonthComponents)!

        // Create a due date that's very old (6 months ago)
        // but with the same day of month to maintain the pattern
        let oldDueDate = calendar.date(byAdding: .month, value: -6, to: currentMonthDate)!

        let todoItem = TodoItem(
            title: "Very Old Monthly Task",
            details: "This task is very overdue",
            dueDate: oldDueDate,
            recurrenceFrequency: .monthly,
            recurrenceType: .fixed,
            recurrenceInterval: 1,
            owner: user!
        )
        context.insert(todoItem)

        // Act
        todoItem.markAsDone(currentUser: user)

        // Assert
        XCTAssertNotNil(todoItem.dueDate)
        // The next due date should be in the future, not just one interval from the old date
        XCTAssertTrue(todoItem.dueDate! > now, "The next due date should be in the future")

        // It should be on the same day of month as the original date
        // (maintaining the pattern, but in the future)
        let oldComponents = calendar.dateComponents([.day], from: oldDueDate)
        let newComponents = calendar.dateComponents([.day], from: todoItem.dueDate!)

        XCTAssertEqual(
            oldComponents.day, newComponents.day,
            "The day of month should be preserved in the recurrence pattern")

        // Calculate what the next occurrence should be (next month after current date)
        var expectedComponents = calendar.dateComponents([.year, .month], from: now)
        expectedComponents.month = (expectedComponents.month ?? 0) + 1
        // Handle December -> January transition
        if expectedComponents.month! > 12 {
            expectedComponents.month = 1
            expectedComponents.year = (expectedComponents.year ?? 0) + 1
        }
        expectedComponents.day = dayOfMonth

        // The due date should be exactly this next occurrence
        let expectedDate = calendar.date(from: expectedComponents)!
        let actualComponents = calendar.dateComponents(
            [.year, .month, .day], from: todoItem.dueDate!)
        let expectedDateComponents = calendar.dateComponents(
            [.year, .month, .day], from: expectedDate)

        XCTAssertEqual(expectedDateComponents.year, actualComponents.year)
        XCTAssertEqual(expectedDateComponents.month, actualComponents.month)
        XCTAssertEqual(
            expectedDateComponents.day, actualComponents.day, "The day of month should match")
    }
}
