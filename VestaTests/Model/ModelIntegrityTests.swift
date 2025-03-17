import SwiftData
import XCTest

@testable import Vesta

final class ModelIntegrityTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() {
        super.setUp()
        // Create an in-memory container for testing
        let schema = Schema([
            TodoItem.self,
            TodoItemEvent.self,
            Meal.self,
            Recipe.self,
            Ingredient.self,
            ShoppingListItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            context = ModelContext(container)
        } catch {
            XCTFail("Failed to create container: \(error)")
        }
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    func testDeleteTodoItemCascadeToMeal() throws {
        // Arrange
        let recipe = Recipe(title: "Test Recipe", details: "Test Details")
        let todoItem = TodoItem(title: "Test Todo", details: "Test Details")
        let meal = Meal(scalingFactor: 1.0, todoItem: todoItem, recipe: recipe)

        context.insert(recipe)
        context.insert(todoItem)

        // Act
        context.delete(todoItem)
        try context.save()

        // Assert
        let fetchDescriptor = FetchDescriptor<Meal>()
        let remainingMeals = try context.fetch(fetchDescriptor)
        XCTAssertEqual(
            remainingMeals.count, 0, "Meal should be deleted when its TodoItem is deleted")
    }

    func testDeleteTodoItemCascadeToShoppingListItem() throws {
        // Arrange
        let todoItem = TodoItem(title: "Test Todo", details: "Test Details")
        let shoppingListItem = ShoppingListItem(name: "Test Item", todoItem: todoItem)

        context.insert(todoItem)

        // Act
        context.delete(todoItem)
        try context.save()

        // Assert
        let fetchDescriptor = FetchDescriptor<ShoppingListItem>()
        let remainingItems = try context.fetch(fetchDescriptor)
        XCTAssertEqual(
            remainingItems.count, 0,
            "ShoppingListItem should be deleted when its TodoItem is deleted")
    }

    func testDeleteRecipeCascadeToIngredients() throws {
        // Arrange
        let recipe = Recipe(title: "Test Recipe", details: "Test Details")
        let ingredient = Ingredient(
            name: "Test Ingredient", quantity: 1.0, unit: .cup, recipe: recipe)
        recipe.ingredients = [ingredient]

        context.insert(recipe)

        // Act
        context.delete(recipe)
        try context.save()

        // Assert
        let fetchDescriptor = FetchDescriptor<Ingredient>()
        let remainingIngredients = try context.fetch(fetchDescriptor)
        XCTAssertEqual(
            remainingIngredients.count, 0,
            "Ingredients should be deleted when their Recipe is deleted")
    }

    func testDeleteTodoItemCascadeToEvents() throws {
        // Arrange
        let todoItem = TodoItem(title: "Test Todo", details: "Test Details")

        context.insert(todoItem)

        // Act
        context.delete(todoItem)
        try context.save()

        // Assert
        let fetchDescriptor = FetchDescriptor<TodoItemEvent>()
        let remainingEvents = try context.fetch(fetchDescriptor)
        XCTAssertEqual(
            remainingEvents.count, 0, "Events should be deleted when their TodoItem is deleted")
    }

    func testDeleteRecipeCascadeToMeals() throws {
        // Arrange
        let recipe = Recipe(title: "Test Recipe", details: "Test Details")
        let todoItem = TodoItem(title: "Test Todo", details: "Test Details")
        let meal = Meal(scalingFactor: 1.0, todoItem: todoItem, recipe: recipe)

        context.insert(recipe)
        context.insert(todoItem)
        context.insert(meal)

        // Act
        context.delete(recipe)
        try context.save()

        // Assert
        let fetchDescriptor = FetchDescriptor<Meal>()
        let remainingMeals = try context.fetch(fetchDescriptor)
        XCTAssertEqual(remainingMeals.count, 0, "Meal should be deleted when its Recipe is deleted")
    }

    func testComplexDeletionChain() throws {
        // Arrange
        let recipe = Recipe(title: "Test Recipe", details: "Test Details")
        let todoItem = TodoItem(title: "Test Todo", details: "Test Details")
        let meal = Meal(scalingFactor: 1.0, todoItem: todoItem, recipe: recipe)
        _ = ShoppingListItem(
            name: "Test Item", todoItem: todoItem, meals: [meal])

        context.insert(recipe)
        context.insert(todoItem)

        // Act
        context.delete(todoItem)
        try context.save()

        // Assert
        let mealsFetch = FetchDescriptor<Meal>()
        let shoppingItemsFetch = FetchDescriptor<ShoppingListItem>()

        let remainingMeals = try context.fetch(mealsFetch)
        let remainingShoppingItems = try context.fetch(shoppingItemsFetch)

        XCTAssertEqual(remainingMeals.count, 0, "Meal should be deleted")
        XCTAssertEqual(remainingShoppingItems.count, 0, "ShoppingListItem should be deleted")
    }
}
