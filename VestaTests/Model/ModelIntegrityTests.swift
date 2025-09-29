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
        let user = Fixtures.createUser()
        let recipe = Recipe(title: "Test Recipe", details: "Test Details", owner: user)
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

    func testDeleteRecipeCascadeToMeals() throws {
        // Arrange
        let user = Fixtures.createUser()
        let recipe = Recipe(title: "Test Recipe", details: "Test Details", owner: user)
        let todoItem = TodoItem(title: "Test Todo", details: "Test Details", owner: user)
        let meal = Meal(scalingFactor: 1.0, todoItem: todoItem, recipe: recipe, owner: user)

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
        let user = Fixtures.createUser()
        let recipe = Recipe(title: "Test Recipe", details: "Test Details", owner: user)
        let todoItem = TodoItem(title: "Test Todo", details: "Test Details", owner: user)
        let meal = Meal(scalingFactor: 1.0, todoItem: todoItem, recipe: recipe, owner: user)
        let item = ShoppingListItem(name: "Test Item", todoItem: todoItem, owner: user)
        item.meals = [meal]

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
        let user = Fixtures.createUser()
        let recipe = Recipe(title: "Test Recipe", details: "Test Details", owner: user)
        let mealTodoItem = TodoItem(title: "Meal Todo", details: "Test Details", owner: user)
        let shoppingTodoItem = TodoItem(
            title: "Shopping Todo", details: "Test Details", owner: user)
        let shoppingListItem = ShoppingListItem(
            name: "Test Item", todoItem: shoppingTodoItem, owner: user)
        let meal = Meal(scalingFactor: 1.0, todoItem: mealTodoItem, recipe: recipe, owner: user)
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

    func testDeleteTodoItemCascadesToEventsAndNullifiesShoppingItemsAndCategories() throws {
        // Arrange
        let user = Fixtures.createUser()
        let category = TodoItemCategory(name: "Test Category")
        let todoItem = TodoItem(
            title: "Test Todo", details: "Test Details", category: category, owner: user)
        let shoppingListItem = ShoppingListItem(name: "Test Item", todoItem: todoItem, owner: user)
        let event = TodoEvent(
            eventType: .completed,
            completedAt: Date(),
            todoItem: todoItem,
            previousDueDate: nil,
            previousRescheduleDate: nil
        )
        todoItem.events.append(event)
        todoItem.shoppingListItem = shoppingListItem

        context.insert(user)
        context.insert(category)
        context.insert(todoItem)
        context.insert(shoppingListItem)

        // Act
        context.delete(todoItem)
        try context.save()

        // Assert
        let fetchCategories = FetchDescriptor<TodoItemCategory>()
        let fetchShoppingItems = FetchDescriptor<ShoppingListItem>()
        let fetchEvents = FetchDescriptor<TodoEvent>()

        let remainingCategories = try context.fetch(fetchCategories)
        let remainingShoppingItems = try context.fetch(fetchShoppingItems)
        let remainingEvents = try context.fetch(fetchEvents)

        XCTAssertEqual(remainingCategories.count, 1, "Category should not be deleted (nullify)")
        XCTAssertEqual(
            remainingShoppingItems.count, 1, "ShoppingListItem should not be deleted (nullify)")
        XCTAssertEqual(remainingEvents.count, 0, "TodoEvents should be deleted (cascade)")
        XCTAssertNil(
            shoppingListItem.todoItem, "TodoItem reference should be nullified in ShoppingListItem")
    }

    func testDeleteShoppingListItemCascadesToTodoItemAndNullifiesMeals() throws {
        // Arrange
        let user = Fixtures.createUser()
        let recipe = Recipe(title: "Test Recipe", details: "Test Details", owner: user)
        let todoItem = TodoItem(title: "Test Todo", details: "Test Details", owner: user)
        let shoppingListItem = ShoppingListItem(name: "Test Item", todoItem: todoItem, owner: user)
        let meal = Meal(scalingFactor: 1.0, todoItem: nil, recipe: recipe, owner: user)

        // Set up the many-to-many relationship
        shoppingListItem.meals.append(meal)
        meal.shoppingListItems.append(shoppingListItem)

        context.insert(user)
        context.insert(recipe)
        context.insert(todoItem)
        context.insert(shoppingListItem)
        context.insert(meal)

        // Act
        context.delete(shoppingListItem)
        try context.save()

        // Assert
        let fetchTodoItems = FetchDescriptor<TodoItem>()
        let fetchMeals = FetchDescriptor<Meal>()
        let fetchShoppingItems = FetchDescriptor<ShoppingListItem>()

        let remainingTodoItems = try context.fetch(fetchTodoItems)
        let remainingMeals = try context.fetch(fetchMeals)
        let remainingShoppingItems = try context.fetch(fetchShoppingItems)

        XCTAssertEqual(remainingTodoItems.count, 0, "TodoItem should be deleted (cascade)")
        XCTAssertEqual(remainingMeals.count, 1, "Meal should not be deleted (nullify)")
        XCTAssertEqual(remainingShoppingItems.count, 0, "ShoppingListItem should be deleted")
        XCTAssertTrue(
            meal.shoppingListItems.isEmpty, "ShoppingListItem reference should be removed from Meal"
        )
    }

    func testDeleteMealCascadesToTodoItemAndNullifiesRecipeAndShoppingListItems() throws {
        // Arrange
        let user = Fixtures.createUser()
        let recipe = Recipe(title: "Test Recipe", details: "Test Details", owner: user)
        let todoItem = TodoItem(title: "Test Todo", details: "Test Details", owner: user)
        let shoppingListItem = ShoppingListItem(name: "Test Item", todoItem: nil, owner: user)
        let meal = Meal(scalingFactor: 1.0, todoItem: todoItem, recipe: recipe, owner: user)

        // Set up relationships
        meal.shoppingListItems.append(shoppingListItem)
        shoppingListItem.meals.append(meal)

        context.insert(user)
        context.insert(recipe)
        context.insert(todoItem)
        context.insert(shoppingListItem)
        context.insert(meal)

        // Act
        context.delete(meal)
        try context.save()

        // Assert
        let fetchTodoItems = FetchDescriptor<TodoItem>()
        let fetchRecipes = FetchDescriptor<Recipe>()
        let fetchShoppingItems = FetchDescriptor<ShoppingListItem>()
        let fetchMeals = FetchDescriptor<Meal>()

        let remainingTodoItems = try context.fetch(fetchTodoItems)
        let remainingRecipes = try context.fetch(fetchRecipes)
        let remainingShoppingItems = try context.fetch(fetchShoppingItems)
        let remainingMeals = try context.fetch(fetchMeals)

        XCTAssertEqual(remainingTodoItems.count, 0, "TodoItem should be deleted (cascade)")
        XCTAssertEqual(remainingRecipes.count, 1, "Recipe should not be deleted (nullify)")
        XCTAssertEqual(
            remainingShoppingItems.count, 1, "ShoppingListItem should not be deleted (nullify)")
        XCTAssertEqual(remainingMeals.count, 0, "Meal should be deleted")
        XCTAssertTrue(
            shoppingListItem.meals.isEmpty, "Meal reference should be removed from ShoppingListItem"
        )
    }

    func testUserNoActionDeleteRules() throws {
        // Arrange
        let user = Fixtures.createUser()
        let recipe = Recipe(title: "Test Recipe", details: "Test Details", owner: user)
        let todoItem = TodoItem(title: "Test Todo", details: "Test Details", owner: user)
        let shoppingListItem = ShoppingListItem(name: "Test Item", todoItem: todoItem, owner: user)
        let meal = Meal(scalingFactor: 1.0, todoItem: nil, recipe: recipe, owner: user)
        let category = TodoItemCategory(name: "Test Category")

        context.insert(user)
        context.insert(recipe)
        context.insert(todoItem)
        context.insert(shoppingListItem)
        context.insert(meal)
        context.insert(category)

        // Act & Assert - attempting to delete user should fail due to noAction rules
        context.delete(user)

        do {
            try context.save()
            XCTFail(
                "Should not be able to delete User with related entities due to noAction delete rules"
            )
        } catch {
            // This is expected - the delete should fail
            XCTAssertTrue(true, "Delete correctly failed due to noAction delete rules")
        }
    }

    func testRecipeCascadeToIngredientsAndSteps() throws {
        // Arrange
        let user = Fixtures.createUser()
        let recipe = Recipe(title: "Test Recipe", details: "Test Details", owner: user)
        let ingredient = Ingredient(
            name: "Test Ingredient", order: 1, quantity: 1.0, unit: .cup, recipe: recipe)
        let step = RecipeStep(
            order: 1, instruction: "Test step", type: .preparation, duration: 300, recipe: recipe)

        recipe.ingredients = [ingredient]
        recipe.steps = [step]

        context.insert(user)
        context.insert(recipe)

        // Act
        context.delete(recipe)
        try context.save()

        // Assert
        let fetchIngredients = FetchDescriptor<Ingredient>()
        let fetchSteps = FetchDescriptor<RecipeStep>()

        let remainingIngredients = try context.fetch(fetchIngredients)
        let remainingSteps = try context.fetch(fetchSteps)

        XCTAssertEqual(remainingIngredients.count, 0, "Ingredients should be deleted (cascade)")
        XCTAssertEqual(remainingSteps.count, 0, "Recipe steps should be deleted (cascade)")
    }

    func testComplexCascadingDeleteChain() throws {
        // Arrange
        let user = Fixtures.createUser()
        let category = TodoItemCategory(name: "Test Category")
        let recipe = Recipe(title: "Test Recipe", details: "Test Details", owner: user)
        let ingredient = Ingredient(
            name: "Test Ingredient", order: 1, quantity: 1.0, unit: .cup, recipe: recipe)
        let step = RecipeStep(
            order: 1, instruction: "Test step", type: .preparation, duration: 300, recipe: recipe)

        // Create a meal todo item
        let mealTodoItem = TodoItem(
            title: "Cook meal", details: "Test Details", category: category, owner: user)
        let meal = Meal(scalingFactor: 1.0, todoItem: mealTodoItem, recipe: recipe, owner: user)

        // Create a shopping todo item
        let shoppingTodoItem = TodoItem(
            title: "Buy ingredients", details: "Test Details", category: category, owner: user)
        let shoppingListItem = ShoppingListItem(
            name: "Test Item", todoItem: shoppingTodoItem, owner: user)

        // Link meal and shopping item
        meal.shoppingListItems.append(shoppingListItem)
        shoppingListItem.meals.append(meal)

        // Add some events
        let event1 = TodoEvent(
            eventType: .completed, completedAt: Date(), todoItem: mealTodoItem,
            previousDueDate: nil, previousRescheduleDate: nil)
        let event2 = TodoEvent(
            eventType: .completed, completedAt: Date(), todoItem: shoppingTodoItem,
            previousDueDate: nil, previousRescheduleDate: nil)
        mealTodoItem.events.append(event1)
        shoppingTodoItem.events.append(event2)

        context.insert(user)
        context.insert(category)
        context.insert(recipe)
        context.insert(mealTodoItem)
        context.insert(shoppingTodoItem)
        context.insert(meal)
        context.insert(shoppingListItem)

        // Act - Delete the recipe
        context.delete(recipe)
        try context.save()

        // Assert
        let fetchRecipes = FetchDescriptor<Recipe>()
        let fetchIngredients = FetchDescriptor<Ingredient>()
        let fetchSteps = FetchDescriptor<RecipeStep>()
        let fetchMeals = FetchDescriptor<Meal>()
        let fetchTodoItems = FetchDescriptor<TodoItem>()
        let fetchShoppingItems = FetchDescriptor<ShoppingListItem>()
        let fetchCategories = FetchDescriptor<TodoItemCategory>()
        let fetchEvents = FetchDescriptor<TodoEvent>()

        let remainingRecipes = try context.fetch(fetchRecipes)
        let remainingIngredients = try context.fetch(fetchIngredients)
        let remainingSteps = try context.fetch(fetchSteps)
        let remainingMeals = try context.fetch(fetchMeals)
        let remainingTodoItems = try context.fetch(fetchTodoItems)
        let remainingShoppingItems = try context.fetch(fetchShoppingItems)
        let remainingCategories = try context.fetch(fetchCategories)
        let remainingEvents = try context.fetch(fetchEvents)

        // Recipe and its direct children should be deleted
        XCTAssertEqual(remainingRecipes.count, 0, "Recipe should be deleted")
        XCTAssertEqual(remainingIngredients.count, 0, "Ingredients should be deleted (cascade)")
        XCTAssertEqual(remainingSteps.count, 0, "Recipe steps should be deleted (cascade)")
        XCTAssertEqual(remainingMeals.count, 0, "Meal should be deleted (cascade)")

        // Only the meal's todo item should be deleted (because meal cascades to it)
        XCTAssertEqual(remainingTodoItems.count, 1, "Only shopping todo item should remain")
        XCTAssertEqual(
            remainingTodoItems.first?.title, "Buy ingredients", "Shopping todo item should remain")

        // Shopping list item should remain (nullify relationship with meal)
        XCTAssertEqual(remainingShoppingItems.count, 1, "Shopping list item should remain")
        XCTAssertTrue(
            shoppingListItem.meals.isEmpty, "Meal reference should be removed from shopping item")

        // Category should remain (nullify relationship)
        XCTAssertEqual(remainingCategories.count, 1, "Category should remain")

        // Only one event should remain (the shopping todo item's event)
        XCTAssertEqual(remainingEvents.count, 1, "Only shopping todo item's event should remain")
    }

    func testOrphanedEntityPrevention() throws {
        // This test ensures that the relationships are properly maintained
        // and we don't end up with orphaned entities that cause fatal errors

        // Arrange
        let user = Fixtures.createUser()
        let todoItem = TodoItem(title: "Test Todo", details: "Test Details", owner: user)
        let shoppingListItem = ShoppingListItem(name: "Test Item", todoItem: todoItem, owner: user)

        context.insert(user)
        context.insert(todoItem)
        context.insert(shoppingListItem)
        try context.save()

        // Act - Delete the todo item (this should nullify the shopping item's todoItem reference)
        context.delete(todoItem)
        try context.save()

        // Assert - Verify shopping item remains but todoItem reference is nullified
        let fetchShoppingItems = FetchDescriptor<ShoppingListItem>()
        let remainingShoppingItems = try context.fetch(fetchShoppingItems)

        XCTAssertEqual(
            remainingShoppingItems.count, 1,
            "ShoppingListItem should remain when TodoItem is deleted (nullify relationship)")
        XCTAssertNil(
            remainingShoppingItems.first?.todoItem,
            "TodoItem reference should be nullified")

        // Try to access the relationship - this should not cause a fatal error
        let fetchTodoItems = FetchDescriptor<TodoItem>()
        let remainingTodoItems = try context.fetch(fetchTodoItems)

        XCTAssertEqual(remainingTodoItems.count, 0, "No todo items should remain")

        // Verify we can still query without issues
        XCTAssertNoThrow(try context.fetch(fetchShoppingItems))
        XCTAssertNoThrow(try context.fetch(fetchTodoItems))
    }

    func testDeleteRecipeCascadesToMealsAndTodoItemsButNotShoppingListItems() throws {
        // Arrange
        let user = Fixtures.createUser()
        let recipe = Recipe(title: "Test Recipe", details: "Test Details", owner: user)
        let mealTodoItem = TodoItem(title: "Meal Todo", details: "Test Details", owner: user)
        let shoppingTodoItem = TodoItem(
            title: "Shopping Todo", details: "Test Details", owner: user)
        let shoppingListItem = ShoppingListItem(
            name: "Test Item", todoItem: shoppingTodoItem, owner: user)
        let meal = Meal(scalingFactor: 1.0, todoItem: mealTodoItem, recipe: recipe, owner: user)
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
