import SwiftData
import XCTest

@testable import Vesta

final class ModelIntegrityTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() {
        super.setUp()
        let container = try! ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        context = ModelContext(container)
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }


    func testDeleteRecipeCascadeToIngredients() throws {
        // Arrange
        let recipe = Recipe(title: "Test Recipe", details: "Test Details", owner: Fixtures.defaultUser)
        let ingredient = Ingredient(
            name: "Test Ingredient", order: 1, quantity: 1.0, unit: .cup, recipe: recipe)
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
        let todoItem = TodoItem(title: "Test Todo", details: "Test Details", owner: Fixtures.defaultUser)

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
        let recipe = Recipe(title: "Test Recipe", details: "Test Details", owner: Fixtures.defaultUser)
        let meal = Meal(
            scalingFactor: 1.0, todoItem: TodoItem(title: "Test Todo", details: "Test Details", owner: Fixtures.defaultUser),
            recipe: recipe, owner: Fixtures.defaultUser)

        context.insert(recipe)
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
        let recipe = Recipe(title: "Test Recipe", details: "Test Details", owner: Fixtures.defaultUser)
        let todoItem = TodoItem(title: "Test Todo", details: "Test Details", owner: Fixtures.defaultUser)
        let meal = Meal(scalingFactor: 1.0, todoItem: todoItem, recipe: recipe, owner: Fixtures.defaultUser)
        _ = ShoppingListItem(
            name: "Test Item", todoItem: todoItem, meals: [meal], owner: Fixtures.defaultUser)

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

    func testDeleteMealCascadesToTodoItemButNotRecipeOrShoppingListItems() throws {
        // Arrange
        let recipe = Recipe(title: "Test Recipe", details: "Test Details", owner: Fixtures.defaultUser)
        let mealTodoItem = TodoItem(title: "Meal Todo", details: "Test Details", owner: Fixtures.defaultUser)
        let shoppingTodoItem = TodoItem(title: "Shopping Todo", details: "Test Details", owner: Fixtures.defaultUser)
        let shoppingListItem = ShoppingListItem(name: "Test Item", todoItem: shoppingTodoItem, owner: Fixtures.defaultUser)
        let meal = Meal(scalingFactor: 1.0, todoItem: mealTodoItem, recipe: recipe, owner: Fixtures.defaultUser)
        meal.shoppingListItems.append(shoppingListItem)
        shoppingListItem.meals.append(meal)

        context.insert(recipe)
        context.insert(mealTodoItem)
        context.insert(shoppingTodoItem)
        context.insert(shoppingListItem)
        context.insert(meal)

        // Act
        context.delete(meal)
        try context.save()

        // Assert
        let fetchTodoItems = FetchDescriptor<TodoItem>()
        let fetchRecipes = FetchDescriptor<Recipe>()
        let fetchShoppingListItems = FetchDescriptor<ShoppingListItem>()
        let fetchMeals = FetchDescriptor<Meal>()

        let remainingTodoItems = try context.fetch(fetchTodoItems)
        let remainingRecipes = try context.fetch(fetchRecipes)
        let remainingShoppingListItems = try context.fetch(fetchShoppingListItems)
        let remainingMeals = try context.fetch(fetchMeals)

        XCTAssertEqual(remainingTodoItems.count, 1, "Only meal's TodoItem should be deleted")
        XCTAssertEqual(
            remainingTodoItems.first?.title, "Shopping Todo", "Shopping TodoItem should remain")
        XCTAssertEqual(
            remainingRecipes.count, 1, "Recipe should not be deleted when its Meal is deleted")
        XCTAssertEqual(
            remainingShoppingListItems.count, 1,
            "ShoppingListItem should not be deleted when its Meal is deleted")
        XCTAssertEqual(remainingMeals.count, 0, "Meal should be deleted")
        XCTAssertTrue(
            shoppingListItem.meals.isEmpty, "Meal should be removed from ShoppingListItem")
    }

    func testDeleteRecipeCascadesToMealsAndTodoItemsButNotShoppingListItems() throws {
        // Arrange
        let recipe = Recipe(title: "Test Recipe", details: "Test Details", owner: Fixtures.defaultUser)
        let mealTodoItem = TodoItem(title: "Meal Todo", details: "Test Details", owner: Fixtures.defaultUser)
        let shoppingTodoItem = TodoItem(title: "Shopping Todo", details: "Test Details", owner: Fixtures.defaultUser)
        let shoppingListItem = ShoppingListItem(name: "Test Item", todoItem: shoppingTodoItem, owner: Fixtures.defaultUser)
        let meal = Meal(scalingFactor: 1.0, todoItem: mealTodoItem, recipe: recipe, owner: Fixtures.defaultUser)
        meal.shoppingListItems.append(shoppingListItem)
        shoppingListItem.meals.append(meal)

        context.insert(recipe)
        context.insert(shoppingTodoItem)
        context.insert(shoppingListItem)
        context.insert(meal)

        // Act
        context.delete(recipe)
        try context.save()

        // Assert
        let fetchTodoItems = FetchDescriptor<TodoItem>()
        let fetchRecipes = FetchDescriptor<Recipe>()
        let fetchShoppingListItems = FetchDescriptor<ShoppingListItem>()
        let fetchMeals = FetchDescriptor<Meal>()

        let remainingTodoItems = try context.fetch(fetchTodoItems)
        let remainingRecipes = try context.fetch(fetchRecipes)
        let remainingShoppingListItems = try context.fetch(fetchShoppingListItems)
        let remainingMeals = try context.fetch(fetchMeals)

        XCTAssertEqual(remainingTodoItems.count, 1, "Only meal's TodoItem should be deleted")
        XCTAssertEqual(
            remainingTodoItems.first?.title, "Shopping Todo", "Shopping TodoItem should remain")
        XCTAssertEqual(remainingRecipes.count, 0, "Recipe should be deleted")
        XCTAssertEqual(
            remainingShoppingListItems.count, 1,
            "ShoppingListItem should not be deleted when its Recipe is deleted")
        XCTAssertEqual(remainingMeals.count, 0, "Meal should be deleted when its Recipe is deleted")
        XCTAssertTrue(
            shoppingListItem.meals.isEmpty, "Meal should be removed from ShoppingListItem")
    }
}
