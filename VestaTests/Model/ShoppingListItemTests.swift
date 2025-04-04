import SwiftData
import XCTest

@testable import Vesta

final class ShoppingListItemTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var user: User!

    override func setUp() {
        super.setUp()
        container = try! ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        context = ModelContext(container)

        // Set up the UserManager to return our test user
        user = Fixtures.createUser()
        UserManager.shared.setCurrentUser(user: user)
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    // MARK: - Creation Tests

    func testCreateShoppingListItem() throws {
        // Arrange
        let todoItem = Fixtures.todoItem(
            title: "Buy Flour",
            details: "For baking",
            owner: user
        )
        context.insert(todoItem)

        // Act
        let shoppingListItem = ShoppingListItem(
            name: "Flour",
            quantity: 500,
            unit: .gram,
            todoItem: todoItem,
            owner: user
        )
        context.insert(shoppingListItem)

        // Assert
        XCTAssertEqual(shoppingListItem.name, "Flour")
        XCTAssertEqual(shoppingListItem.quantity, 500)
        XCTAssertEqual(shoppingListItem.unit, .gram)
        XCTAssertEqual(shoppingListItem.owner?.uid, user.uid)
        XCTAssertEqual(shoppingListItem.todoItem?.id, todoItem.id)
        XCTAssertTrue(shoppingListItem.meals.isEmpty)
        XCTAssertTrue(shoppingListItem.dirty, "New shopping list item should be marked as dirty")
    }

    func testCreateShoppingListItemWithMeals() throws {
        // Arrange
        let todoItem = Fixtures.todoItem(
            title: "Buy Ingredients",
            details: "For recipes",
            owner: user
        )
        context.insert(todoItem)

        let recipe = Fixtures.bolognese(owner: user)
        context.insert(recipe)

        let mealTodoItem = Fixtures.todoItem(
            title: "Make Bolognese",
            details: "For dinner",
            owner: user
        )
        context.insert(mealTodoItem)

        let meal = Meal(
            scalingFactor: 1.0,
            todoItem: mealTodoItem,
            recipe: recipe,
            owner: user
        )
        context.insert(meal)

        // Act
        let shoppingListItem = ShoppingListItem(
            name: "Ground Beef",
            quantity: 300,
            unit: .gram,
            todoItem: todoItem,
            owner: user
        )
        context.insert(shoppingListItem)

        // Now add the relationship from one side only
        meal.shoppingListItems.append(shoppingListItem)

        // Assert
        XCTAssertEqual(shoppingListItem.name, "Ground Beef")
        XCTAssertEqual(shoppingListItem.quantity, 300)
        XCTAssertEqual(shoppingListItem.unit, .gram)
        XCTAssertEqual(shoppingListItem.owner?.uid, user.uid)
        XCTAssertEqual(shoppingListItem.todoItem?.id, todoItem.id)
        XCTAssertEqual(shoppingListItem.meals.count, 1)
        XCTAssertEqual(shoppingListItem.meals.first?.id, meal.id)
        XCTAssertTrue(shoppingListItem.dirty, "New shopping list item should be marked as dirty")
    }

    // MARK: - Property Tests

    func testIsPurchasedProperty() throws {
        // Arrange - Create items with different completion states
        let todoItemIncomplete = Fixtures.todoItem(
            title: "Buy Milk",
            details: "From grocery store",
            isCompleted: false,
            owner: user
        )
        context.insert(todoItemIncomplete)

        let todoItemComplete = Fixtures.todoItem(
            title: "Buy Eggs",
            details: "From grocery store",
            isCompleted: true,
            owner: user
        )
        context.insert(todoItemComplete)

        let shoppingItemIncomplete = ShoppingListItem(
            name: "Milk",
            quantity: 1,
            unit: .liter,
            todoItem: todoItemIncomplete,
            owner: user
        )
        context.insert(shoppingItemIncomplete)

        let shoppingItemComplete = ShoppingListItem(
            name: "Eggs",
            quantity: 12,
            unit: .piece,
            todoItem: todoItemComplete,
            owner: user
        )
        context.insert(shoppingItemComplete)

        // Act & Assert
        XCTAssertFalse(shoppingItemIncomplete.isPurchased, "Item should not be marked as purchased")
        XCTAssertTrue(shoppingItemComplete.isPurchased, "Item should be marked as purchased")

        // Additional test for when todoItem is nil
        let shoppingItemNoTodo = ShoppingListItem(
            name: "Bread",
            quantity: 1,
            unit: .piece,
            todoItem: nil,
            owner: user
        )
        context.insert(shoppingItemNoTodo)
        shoppingItemNoTodo.todoItem = nil

        XCTAssertTrue(
            shoppingItemNoTodo.isPurchased, "Item with no todo should be considered purchased")
    }

    // MARK: - Property Update Tests

    func testSetQuantity() throws {
        // Arrange
        let todoItem = Fixtures.todoItem(title: "Buy Sugar", details: "For baking", owner: user)
        context.insert(todoItem)

        let shoppingListItem = ShoppingListItem(
            name: "Sugar",
            quantity: 200,
            unit: .gram,
            todoItem: todoItem,
            owner: user
        )
        context.insert(shoppingListItem)
        shoppingListItem.markAsSynced()  // Reset dirty flag

        // Act
        shoppingListItem.setQuantity(newQuantity: 500)

        // Assert
        XCTAssertEqual(shoppingListItem.quantity, 500)
        XCTAssertTrue(
            shoppingListItem.dirty, "Item should be marked as dirty after quantity change")
    }

    func testSetQuantityToNil() throws {
        // Arrange
        let todoItem = Fixtures.todoItem(title: "Buy Spices", details: "For cooking", owner: user)
        context.insert(todoItem)

        let shoppingListItem = ShoppingListItem(
            name: "Cinnamon",
            quantity: 50,
            unit: .gram,
            todoItem: todoItem,
            owner: user
        )
        context.insert(shoppingListItem)
        shoppingListItem.markAsSynced()  // Reset dirty flag

        // Act
        shoppingListItem.setQuantity(newQuantity: nil)

        // Assert
        XCTAssertNil(shoppingListItem.quantity)
        XCTAssertTrue(
            shoppingListItem.dirty, "Item should be marked as dirty after quantity change")
    }

    func testSetUnit() throws {
        // Arrange
        let todoItem = Fixtures.todoItem(title: "Buy Oil", details: "For cooking", owner: user)
        context.insert(todoItem)

        let shoppingListItem = ShoppingListItem(
            name: "Olive Oil",
            quantity: 500,
            unit: .milliliter,
            todoItem: todoItem,
            owner: user
        )
        context.insert(shoppingListItem)
        shoppingListItem.markAsSynced()  // Reset dirty flag

        // Act
        shoppingListItem.setUnit(newUnit: .liter)

        // Assert
        XCTAssertEqual(shoppingListItem.unit, .liter)
        XCTAssertTrue(shoppingListItem.dirty, "Item should be marked as dirty after unit change")
    }

    func testSetUnitToNil() throws {
        // Arrange
        let todoItem = Fixtures.todoItem(title: "Buy Vegetables", details: "For salad", owner: user)
        context.insert(todoItem)

        let shoppingListItem = ShoppingListItem(
            name: "Lettuce",
            quantity: 1,
            unit: .piece,
            todoItem: todoItem,
            owner: user
        )
        context.insert(shoppingListItem)
        shoppingListItem.markAsSynced()  // Reset dirty flag

        // Act
        shoppingListItem.setUnit(newUnit: nil)

        // Assert
        XCTAssertNil(shoppingListItem.unit)
        XCTAssertTrue(shoppingListItem.dirty, "Item should be marked as dirty after unit change")
    }

    // MARK: - Meal Relationship Tests

    func testAddingMealToShoppingListItem() throws {
        // Arrange
        let todoItem = Fixtures.todoItem(title: "Buy Tomatoes", details: "For sauce", owner: user)
        context.insert(todoItem)

        let shoppingListItem = ShoppingListItem(
            name: "Tomatoes",
            quantity: 6,
            unit: .piece,
            todoItem: todoItem,
            owner: user
        )
        context.insert(shoppingListItem)

        let recipe = Fixtures.bolognese(owner: user)
        context.insert(recipe)

        let mealTodoItem = Fixtures.todoItem(
            title: "Make Pasta",
            details: "For lunch",
            owner: user
        )
        context.insert(mealTodoItem)

        let meal = Meal(
            scalingFactor: 1.0,
            todoItem: mealTodoItem,
            recipe: recipe,
            owner: user
        )
        context.insert(meal)

        // Act
        shoppingListItem.meals.append(meal)

        // Assert
        XCTAssertEqual(shoppingListItem.meals.count, 1)
        XCTAssertEqual(shoppingListItem.meals.first?.id, meal.id)
    }

    func testRemovingMealFromShoppingListItem() throws {
        // Arrange
        let todoItem = Fixtures.todoItem(
            title: "Buy Ingredients", details: "For recipes", owner: user)
        context.insert(todoItem)

        let recipe = Fixtures.bolognese(owner: user)
        context.insert(recipe)

        let mealTodoItem = Fixtures.todoItem(
            title: "Make Bolognese",
            details: "For dinner",
            owner: user
        )
        context.insert(mealTodoItem)

        let meal = Meal(
            scalingFactor: 1.0,
            todoItem: mealTodoItem,
            recipe: recipe,
            owner: user
        )
        context.insert(meal)

        let shoppingListItem = ShoppingListItem(
            name: "Ground Beef",
            quantity: 300,
            unit: .gram,
            todoItem: todoItem,
            owner: user
        )
        shoppingListItem.meals = [meal]
        context.insert(shoppingListItem)

        // Act
        shoppingListItem.meals.removeAll()

        // Assert
        XCTAssertTrue(shoppingListItem.meals.isEmpty)
    }

    // MARK: - Syncable Behavior Tests

    func testSyncableBehavior() throws {
        // Arrange
        let todoItem = Fixtures.todoItem(title: "Buy Cheese", details: "For pizza", owner: user)
        context.insert(todoItem)

        let shoppingListItem = ShoppingListItem(
            name: "Mozzarella",
            quantity: 200,
            unit: .gram,
            todoItem: todoItem,
            owner: user
        )
        context.insert(shoppingListItem)

        // Assert
        XCTAssertTrue(shoppingListItem.dirty, "New shopping list item should be marked as dirty")

        // Act
        shoppingListItem.markAsSynced()

        // Assert
        XCTAssertFalse(shoppingListItem.dirty, "Item should not be dirty after marked as synced")
        XCTAssertGreaterThanOrEqual(
            shoppingListItem.lastModified, Date().addingTimeInterval(-5),
            "Last modified should be updated"
        )

        // Act - modify item
        shoppingListItem.setQuantity(newQuantity: 300)

        // Assert
        XCTAssertTrue(shoppingListItem.dirty, "Item should be marked as dirty after modification")

        // Act
        shoppingListItem.markAsSynced()

        // Assert
        XCTAssertFalse(
            shoppingListItem.dirty, "Item should not be dirty after marked as synced again")
    }
}
