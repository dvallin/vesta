import SwiftData
import XCTest

@testable import Vesta

final class MealTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var user: User!
    var recipe: Recipe!
    var todoItem: TodoItem!

    override func setUp() {
        super.setUp()
        container = try! ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        context = ModelContext(container)

        // Set up the UserAuthService to return our test user
        user = Fixtures.createUser()

        // Set up test recipe and todoItem
        recipe = Fixtures.bolognese(owner: user)
        context.insert(recipe)

        todoItem = Fixtures.todoItem(
            title: "Cook Bolognese",
            details: "For dinner",
            dueDate: Date(),
            owner: user
        )
        context.insert(todoItem)
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    // MARK: - Creation Tests

    func testCreateMeal() throws {
        // Arrange & Act
        let meal = Meal(
            scalingFactor: 1.0,
            todoItem: todoItem,
            recipe: recipe,
            mealType: .dinner,
            owner: user
        )
        context.insert(meal)

        // Assert
        XCTAssertEqual(meal.scalingFactor, 1.0)
        XCTAssertEqual(meal.mealType, .dinner)
        XCTAssertEqual(meal.owner?.uid, user.uid)
        XCTAssertEqual(meal.recipe?.title, "Spaghetti Bolognese")
        XCTAssertEqual(meal.todoItem?.title, "Cook Bolognese")
        XCTAssertTrue(meal.shoppingListItems.isEmpty)
        XCTAssertTrue(meal.dirty, "New meal should be marked as dirty")
    }

    // MARK: - Property Update Tests

    func testSetScalingFactor() throws {
        // Arrange
        let meal = Meal(
            scalingFactor: 1.0,
            todoItem: todoItem,
            recipe: recipe,
            mealType: .dinner,
            owner: user
        )
        context.insert(meal)
        meal.markAsSynced()  // Reset dirty flag

        // Act
        meal.setScalingFactor(2.0, currentUser: user)

        // Assert
        XCTAssertEqual(meal.scalingFactor, 2.0)
        XCTAssertTrue(meal.dirty, "Meal should be marked as dirty after scaling factor change")
    }

    func testSetMealType() throws {
        // Arrange
        let meal = Meal(
            scalingFactor: 1.0,
            todoItem: todoItem,
            recipe: recipe,
            mealType: .dinner,
            owner: user
        )
        context.insert(meal)
        meal.markAsSynced()  // Reset dirty flag

        // Act
        meal.setMealType(.lunch, currentUser: user)

        // Assert
        XCTAssertEqual(meal.mealType, .lunch)
        XCTAssertTrue(meal.dirty, "Meal should be marked as dirty after meal type change")
    }

    func testSetDueDate() throws {
        // Arrange
        let meal = Meal(
            scalingFactor: 1.0,
            todoItem: todoItem,
            recipe: recipe,
            mealType: .dinner,
            owner: user
        )
        context.insert(meal)
        meal.markAsSynced()  // Reset dirty flag

        // Original due date
        let originalDueDate = todoItem.dueDate

        // New due date (tomorrow)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        // Act
        meal.setDueDate(tomorrow, currentUser: user)

        // Assert
        XCTAssertNotEqual(todoItem.dueDate, originalDueDate)
        XCTAssertTrue(Calendar.current.isDate(todoItem.dueDate!, inSameDayAs: tomorrow))
        XCTAssertTrue(meal.dirty, "Meal should be marked as dirty after due date change")
    }

    func testRemoveDueDate() throws {
        // Arrange
        let user = try createUser()
        let meal = Meal(
            scalingFactor: 1.0,
            todoItem: todoItem,
            recipe: recipe,
            mealType: .dinner,
            owner: user
        )
        context.insert(meal)

        // Set initial due date
        let initialDate = Date()
        meal.setDueDate(initialDate, currentUser: user)
        XCTAssertNotNil(meal.todoItem?.dueDate, "Due date should be set")
        meal.markAsSynced()  // Reset dirty flag

        // Act
        meal.removeDueDate(currentUser: user)

        // Assert
        XCTAssertNil(meal.todoItem?.dueDate, "Due date should be removed")
        XCTAssertTrue(meal.dirty, "Meal should be marked as dirty after due date removal")
    }

    func testSetDueDateWithNil() throws {
        // Arrange
        let user = try createUser()
        let meal = Meal(
            scalingFactor: 1.0,
            todoItem: todoItem,
            recipe: recipe,
            mealType: .dinner,
            owner: user
        )
        context.insert(meal)

        // Set initial due date
        let initialDate = Date()
        meal.setDueDate(initialDate, currentUser: user)
        XCTAssertNotNil(meal.todoItem?.dueDate, "Due date should be set")
        meal.markAsSynced()  // Reset dirty flag

        // Act
        meal.setDueDate(nil, currentUser: user)

        // Assert
        XCTAssertNil(meal.todoItem?.dueDate, "Due date should be nil")
        XCTAssertTrue(meal.dirty, "Meal should be marked as dirty after due date removal")
    }

    // MARK: - Meal Time Tests

    func testUpdateTodoItemDueDate() throws {
        // Arrange
        let meal = Meal(
            scalingFactor: 1.0,
            todoItem: todoItem,
            recipe: recipe,
            mealType: .dinner,
            owner: user
        )
        context.insert(meal)
        meal.markAsSynced()  // Reset dirty flag

        // Act - Change meal type to breakfast
        meal.updateTodoItemDueDate(for: .breakfast, currentUser: user)

        // Assert
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: todoItem.dueDate!)

        // Assuming breakfast is set to morning hours in DateUtils.mealTime
        XCTAssertTrue(components.hour! < 12, "Breakfast should be set to morning hours")
        XCTAssertTrue(meal.dirty, "Meal should be marked as dirty after updating due date")

        // Act - Change meal type to dinner
        meal.markAsSynced()  // Reset dirty flag
        meal.updateTodoItemDueDate(for: .dinner, currentUser: user)

        // Assert
        let dinnerComponents = calendar.dateComponents([.hour, .minute], from: todoItem.dueDate!)

        // Assuming dinner is set to evening hours in DateUtils.mealTime
        XCTAssertTrue(dinnerComponents.hour! >= 17, "Dinner should be set to evening hours")
        XCTAssertTrue(meal.dirty, "Meal should be marked as dirty after updating due date")
    }

    func testUpdateTodoItemDueDateWithSpecificDate() throws {
        // Arrange
        let meal = Meal(
            scalingFactor: 1.0,
            todoItem: todoItem,
            recipe: recipe,
            mealType: .dinner,
            owner: user
        )
        context.insert(meal)
        meal.markAsSynced()  // Reset dirty flag

        // New date (3 days from now)
        let futureDateOnly = Calendar.current.date(byAdding: .day, value: 3, to: Date())!

        // Act
        meal.updateTodoItemDueDate(for: .lunch, on: futureDateOnly, currentUser: user)

        // Assert
        XCTAssertTrue(Calendar.current.isDate(todoItem.dueDate!, inSameDayAs: futureDateOnly))

        let components = Calendar.current.dateComponents([.hour, .minute], from: todoItem.dueDate!)

        // Assuming lunch is set to midday hours in DateUtils.mealTime
        XCTAssertTrue(
            components.hour! >= 11 && components.hour! <= 14, "Lunch should be set to midday hours")
        XCTAssertTrue(meal.dirty, "Meal should be marked as dirty after updating due date")
    }

    // MARK: - Status Tests

    func testIsDone() throws {
        // Arrange
        let meal = Meal(
            scalingFactor: 1.0,
            todoItem: todoItem,
            recipe: recipe,
            mealType: .dinner,
            owner: user
        )
        context.insert(meal)

        // Assert - Initially not done
        XCTAssertFalse(meal.isDone, "Meal should not be done when todoItem is not completed")

        // Act - Complete the todoItem
        todoItem.setIsCompleted(isCompleted: true, currentUser: user)

        // Assert - Should be done now
        XCTAssertTrue(meal.isDone, "Meal should be done when todoItem is completed")

        // Act - Remove todoItem
        meal.todoItem = nil

        // Assert - Should be considered done when there's no todoItem
        XCTAssertTrue(meal.isDone, "Meal should be done when there's no todoItem")
    }

    // MARK: - Shopping List Integration Tests

    func testShoppingListIntegration() throws {
        // Arrange
        let meal = Meal(
            scalingFactor: 1.0,
            todoItem: todoItem,
            recipe: recipe,
            mealType: .dinner,
            owner: user
        )
        context.insert(meal)

        // Create shopping list items for this meal
        let item1Todo = Fixtures.todoItem(
            title: "By Pasta",
            details: "For dinner",
            dueDate: Date(),
            owner: user
        )
        let item1 = ShoppingListItem(
            name: "Pasta", quantity: 500, unit: .gram, todoItem: item1Todo, owner: user)
        context.insert(item1)

        let item2Todo = Fixtures.todoItem(
            title: "By Pasta",
            details: "For dinner",
            dueDate: Date(),
            owner: user
        )
        let item2 = ShoppingListItem(
            name: "Ground Beef", quantity: 300, unit: .gram, todoItem: item2Todo, owner: user)
        context.insert(item2)

        // Act - Add shopping list items to the meal
        meal.shoppingListItems.append(item1)
        meal.shoppingListItems.append(item2)

        // Assert - Verify shopping list items are associated with the meal
        XCTAssertEqual(meal.shoppingListItems.count, 2, "Meal should have 2 shopping list items")
        XCTAssertTrue(meal.shoppingListItems.contains(item1), "Meal should contain the pasta item")
        XCTAssertTrue(
            meal.shoppingListItems.contains(item2), "Meal should contain the ground beef item")

        // Act - Complete a shopping item
        item1Todo.setIsCompleted(isCompleted: true, currentUser: user)

        // Assert - Verify the meal is still incomplete (both shopping items need to be completed)
        XCTAssertFalse(meal.isDone, "Meal should not be done when todo item is not completed")

        // Act - Remove an item from the meal's shopping list
        meal.shoppingListItems.removeAll(where: { $0 == item1 })

        // Assert - Verify the item was removed
        XCTAssertEqual(
            meal.shoppingListItems.count, 1, "Meal should have 1 shopping list item after removal")
        XCTAssertFalse(
            meal.shoppingListItems.contains(item1), "Meal should no longer contain the pasta item")
        XCTAssertTrue(
            meal.shoppingListItems.contains(item2), "Meal should still contain the ground beef item"
        )

        // Act - Complete the meal's todo item
        todoItem.setIsCompleted(isCompleted: true, currentUser: user)

        // Assert - Verify the meal is now done
        XCTAssertTrue(meal.isDone, "Meal should be done when its todo item is completed")
    }

    // MARK: - Syncable Behavior Tests

    func testSyncableBehavior() throws {
        // Arrange
        let meal = Meal(
            scalingFactor: 1.0,
            todoItem: todoItem,
            recipe: recipe,
            mealType: .dinner,
            owner: user
        )
        context.insert(meal)

        // Assert
        XCTAssertTrue(meal.dirty, "New meal should be marked as dirty")

        // Act
        meal.markAsSynced()

        // Assert
        XCTAssertFalse(meal.dirty, "Meal should not be dirty after marked as synced")

        // Act
        meal.setScalingFactor(1.5, currentUser: user)

        // Assert
        XCTAssertTrue(meal.dirty, "Meal should be marked as dirty after modification")

        // Act
        meal.markAsSynced()

        // Assert
        XCTAssertFalse(meal.dirty, "Meal should not be dirty after marked as synced again")
    }
}
