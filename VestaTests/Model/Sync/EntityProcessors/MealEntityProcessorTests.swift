import OSLog
import SwiftData
import XCTest

@testable import Vesta

class MealEntityProcessorTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var processor: MealEntityProcessor!
    var mealService: MealService!
    var userService: UserService!
    var todoItemService: TodoItemService!
    var recipeService: RecipeService!
    var shoppingListItemService: ShoppingListItemService!
    var logger: Logger!
    var currentUser: User!

    override func setUp() async throws {
        container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        context = ModelContext(container)

        logger = Logger(subsystem: "dev.vegardskjefstad.Vesta.Tests", category: "Tests")
        userService = UserService(modelContext: context)
        mealService = MealService(modelContext: context)
        todoItemService = TodoItemService(modelContext: context)
        recipeService = RecipeService(modelContext: context)
        shoppingListItemService = ShoppingListItemService(modelContext: context)

        processor = MealEntityProcessor(
            modelContext: context,
            logger: logger,
            meals: mealService,
            users: userService,
            todoItems: todoItemService,
            recipes: recipeService,
            shoppingItems: shoppingListItemService
        )

        currentUser = Fixtures.createUser()
        context.insert(currentUser)
        try context.save()
    }

    override func tearDown() async throws {
        // Clear relationship references before batch deletion to prevent constraint violations
        let meals = try context.fetch(FetchDescriptor<Meal>())
        for meal in meals {
            meal.recipe = nil
            meal.todoItem = nil
            meal.shoppingListItems = []
        }
        try context.save()

        // Delete entities in an order that respects relationship constraints
        try await container.mainContext.delete(model: Recipe.self)
        try await container.mainContext.delete(model: Meal.self)
        try await container.mainContext.delete(model: TodoItem.self)
        try await container.mainContext.delete(model: ShoppingListItem.self)
        try await container.mainContext.delete(model: User.self)
    }

    // MARK: - Tests

    func testProcessNewMeal() async throws {
        // Prepare test data
        let uid = UUID().uuidString
        let mealData: [String: Any] = [
            "uid": uid,
            "scalingFactor": 2.0,
            "mealType": "dinner",
            "isShared": true,
        ]

        // Process the entity
        try await processor.process(entities: [mealData], currentUser: currentUser)

        // Verify results
        let meal = try mealService.fetchUnique(withUID: uid)
        XCTAssertNotNil(meal, "Meal should be created")
        XCTAssertEqual(meal?.uid, uid)
        XCTAssertEqual(meal?.scalingFactor, 2.0)
        XCTAssertEqual(meal?.mealType, .dinner)
        XCTAssertEqual(meal?.isShared, true)
        XCTAssertNil(meal?.owner)
        XCTAssertNil(meal?.recipe)
        XCTAssertNil(meal?.todoItem)
        XCTAssertTrue(meal?.shoppingListItems.isEmpty ?? false)
    }

    func testProcessNewMealWithOwner() async throws {
        // Prepare test data
        let uid = UUID().uuidString
        let owner = Fixtures.createUser()
        owner.uid = "test-owner-1"
        context.insert(owner)
        try context.save()

        let mealData: [String: Any] = [
            "uid": uid,
            "scalingFactor": 1.5,
            "mealType": "breakfast",
            "ownerId": "test-owner-1",
        ]

        // Process the entity
        try await processor.process(entities: [mealData], currentUser: currentUser)

        // Verify results
        let meal = try mealService.fetchUnique(withUID: uid)
        XCTAssertNotNil(meal, "Meal should be created")
        XCTAssertEqual(meal?.owner?.uid, "test-owner-1")
    }

    func testProcessNewMealWithRecipe() async throws {
        // Prepare test data
        let uid = UUID().uuidString
        let recipe = Fixtures.bolognese(owner: currentUser)
        recipe.uid = "test-recipe-1"
        context.insert(recipe)
        try context.save()

        let mealData: [String: Any] = [
            "uid": uid,
            "scalingFactor": 1.0,
            "mealType": "dinner",
            "recipeId": "test-recipe-1",
        ]

        // Process the entity
        try await processor.process(entities: [mealData], currentUser: currentUser)

        // Verify results
        let meal = try mealService.fetchUnique(withUID: uid)
        XCTAssertNotNil(meal, "Meal should be created")
        XCTAssertEqual(meal?.recipe?.uid, "test-recipe-1")
    }

    func testProcessNewMealWithTodoItem() async throws {
        // Prepare test data
        let uid = UUID().uuidString
        let todoItem = Fixtures.todoItem(
            title: "Cook dinner", details: "For tonight", owner: currentUser)
        todoItem.uid = "test-todo-1"
        context.insert(todoItem)
        try context.save()

        let mealData: [String: Any] = [
            "uid": uid,
            "scalingFactor": 1.0,
            "mealType": "dinner",
            "todoItemId": "test-todo-1",
        ]

        // Process the entity
        try await processor.process(entities: [mealData], currentUser: currentUser)

        // Verify results
        let meal = try mealService.fetchUnique(withUID: uid)
        XCTAssertNotNil(meal, "Meal should be created")
        XCTAssertEqual(meal?.todoItem?.uid, "test-todo-1")
    }

    func testProcessNewMealWithShoppingItems() async throws {
        // Prepare test data
        let uid = UUID().uuidString
        let shoppingItem1 = Fixtures.shoppingListItem(name: "Pasta", owner: currentUser)
        shoppingItem1.uid = "shop-item-1"
        let shoppingItem2 = Fixtures.shoppingListItem(name: "Tomato Sauce", owner: currentUser)
        shoppingItem2.uid = "shop-item-2"
        context.insert(shoppingItem1)
        context.insert(shoppingItem2)
        try context.save()

        let mealData: [String: Any] = [
            "uid": uid,
            "scalingFactor": 1.0,
            "mealType": "dinner",
            "shoppingListItemIds": ["shop-item-1", "shop-item-2"],
        ]

        // Process the entity
        try await processor.process(entities: [mealData], currentUser: currentUser)

        // Verify results
        let meal = try mealService.fetchUnique(withUID: uid)
        XCTAssertNotNil(meal, "Meal should be created")
        XCTAssertEqual(meal?.shoppingListItems.count, 2)
        XCTAssertTrue(meal?.shoppingListItems.contains(where: { $0.uid == "shop-item-1" }) ?? false)
        XCTAssertTrue(meal?.shoppingListItems.contains(where: { $0.uid == "shop-item-2" }) ?? false)
    }

    func testUpdateExistingMeal() async throws {
        // Insert an existing meal
        let meal = Fixtures.dinner(scalingFactor: 1.0, owner: currentUser)
        meal.uid = "existing-meal"
        context.insert(meal)
        try context.save()

        // Prepare update data
        let mealData: [String: Any] = [
            "uid": "existing-meal",
            "scalingFactor": 2.5,
            "mealType": "breakfast",
            "isShared": true,
        ]

        // Process the entity
        try await processor.process(entities: [mealData], currentUser: currentUser)

        // Verify results
        let updatedMeal = try mealService.fetchUnique(withUID: "existing-meal")
        XCTAssertNotNil(updatedMeal)
        XCTAssertEqual(updatedMeal?.scalingFactor, 2.5)
        XCTAssertEqual(updatedMeal?.mealType, .breakfast)  // This won't actually change since update() doesn't update mealType
        XCTAssertEqual(updatedMeal?.isShared, true)
    }

    func testUpdateMealWithChangedRelationships() async throws {
        // Create initial meal with relationships
        let recipe1 = Fixtures.bolognese(owner: currentUser)
        recipe1.uid = "recipe-1"
        let todoItem1 = Fixtures.todoItem(
            title: "Cook pasta", details: "For dinner", owner: currentUser)
        todoItem1.uid = "todo-1"
        let shoppingItem1 = Fixtures.shoppingListItem(name: "Spaghetti", owner: currentUser)
        shoppingItem1.uid = "shop-1"
        let shoppingItem2 = Fixtures.shoppingListItem(name: "Ground beef", owner: currentUser)
        shoppingItem2.uid = "shop-2"

        let meal = Fixtures.dinner(
            scalingFactor: 1.0,
            recipe: recipe1,
            todoItem: todoItem1,
            owner: currentUser
        )
        meal.uid = "existing-meal"
        meal.shoppingListItems.append(shoppingItem1)
        meal.shoppingListItems.append(shoppingItem2)

        context.insert(recipe1)
        context.insert(todoItem1)
        context.insert(shoppingItem1)
        context.insert(shoppingItem2)
        context.insert(meal)
        try context.save()

        // Create new relationships
        let recipe2 = Fixtures.curry(owner: currentUser)
        recipe2.uid = "recipe-2"
        let todoItem2 = Fixtures.todoItem(
            title: "Cook curry", details: "For lunch", owner: currentUser)
        todoItem2.uid = "todo-2"
        let shoppingItem3 = Fixtures.shoppingListItem(name: "Chicken", owner: currentUser)
        shoppingItem3.uid = "shop-3"

        context.insert(recipe2)
        context.insert(todoItem2)
        context.insert(shoppingItem3)
        try context.save()

        // Prepare update data with changed relationships
        let mealData: [String: Any] = [
            "uid": "existing-meal",
            "scalingFactor": 1.0,
            "mealType": "dinner",
            "recipeId": "recipe-2",
            "todoItemId": "todo-2",
            "shoppingListItemIds": ["shop-2", "shop-3"],  // Keep shop-2 but replace shop-1 with shop-3
        ]

        // Process the entity
        try await processor.process(entities: [mealData], currentUser: currentUser)

        // Verify results
        let updatedMeal = try mealService.fetchUnique(withUID: "existing-meal")
        XCTAssertNotNil(updatedMeal)
        XCTAssertEqual(updatedMeal?.recipe?.uid, "recipe-2")
        XCTAssertEqual(updatedMeal?.todoItem?.uid, "todo-2")
        XCTAssertEqual(updatedMeal?.shoppingListItems.count, 2)
        XCTAssertTrue(
            updatedMeal?.shoppingListItems.contains(where: { $0.uid == "shop-2" }) ?? false)
        XCTAssertTrue(
            updatedMeal?.shoppingListItems.contains(where: { $0.uid == "shop-3" }) ?? false)
        XCTAssertFalse(
            updatedMeal?.shoppingListItems.contains(where: { $0.uid == "shop-1" }) ?? true)
    }

    func testRemoveRelationshipsFromMeal() async throws {
        // Create initial meal with relationships
        let recipe = Fixtures.bolognese(owner: currentUser)
        recipe.uid = "recipe-1"
        let todoItem = Fixtures.todoItem(
            title: "Cook pasta", details: "For dinner", owner: currentUser)
        todoItem.uid = "todo-1"
        let shoppingItem1 = Fixtures.shoppingListItem(name: "Spaghetti", owner: currentUser)
        shoppingItem1.uid = "shop-1"

        let meal = Fixtures.dinner(
            scalingFactor: 1.0,
            recipe: recipe,
            todoItem: todoItem,
            owner: currentUser
        )
        meal.uid = "existing-meal"
        meal.shoppingListItems.append(shoppingItem1)

        context.insert(recipe)
        context.insert(todoItem)
        context.insert(shoppingItem1)
        context.insert(meal)
        try context.save()

        // Prepare update data with removed relationships
        let mealData: [String: Any] = [
            "uid": "existing-meal",
            "scalingFactor": 1.0,
            "mealType": "dinner",
                // No recipeId, todoItemId, or shoppingListItemIds means remove these relationships
        ]

        // Process the entity
        try await processor.process(entities: [mealData], currentUser: currentUser)

        // Verify results
        let updatedMeal = try mealService.fetchUnique(withUID: "existing-meal")
        XCTAssertNotNil(updatedMeal)
        XCTAssertNil(updatedMeal?.recipe)
        XCTAssertNil(updatedMeal?.todoItem)
        XCTAssertTrue(updatedMeal?.shoppingListItems.isEmpty ?? false)
    }

    func testProcessMealWithoutUID() async throws {
        // Prepare test data without UID
        let mealData: [String: Any] = [
            "scalingFactor": 1.0,
            "mealType": "dinner",
        ]

        // Count meals before processing
        let mealsBefore = try context.fetch(FetchDescriptor<Meal>())
        let countBefore = mealsBefore.count

        // Process the entity
        try await processor.process(entities: [mealData], currentUser: currentUser)

        // Count meals after processing
        let mealsAfter = try context.fetch(FetchDescriptor<Meal>())
        let countAfter = mealsAfter.count

        // Verify no meal was created
        XCTAssertEqual(countBefore, countAfter, "No meal should be created when UID is missing")
    }

    func testProcessMealWithMissingRequiredProperties() async throws {
        // Prepare test data with missing required properties
        let mealData: [String: Any] = [
            "uid": UUID().uuidString
            // Missing scalingFactor and mealType
        ]

        // Count meals before processing
        let mealsBefore = try context.fetch(FetchDescriptor<Meal>())
        let countBefore = mealsBefore.count

        // Process the entity
        try await processor.process(entities: [mealData], currentUser: currentUser)

        // Count meals after processing
        let mealsAfter = try context.fetch(FetchDescriptor<Meal>())
        let countAfter = mealsAfter.count

        // Verify no meal was created
        XCTAssertEqual(
            countBefore, countAfter,
            "No meal should be created when required properties are missing")
    }

    func testNonExistentReferences() async throws {
        // Prepare test data with non-existent references
        let uid = UUID().uuidString
        let mealData: [String: Any] = [
            "uid": uid,
            "scalingFactor": 1.0,
            "mealType": "dinner",
            "ownerId": "non-existent-user",
            "recipeId": "non-existent-recipe",
            "todoItemId": "non-existent-todo",
            "shoppingListItemIds": ["non-existent-shopping-item"],
        ]

        // Process the entity
        try await processor.process(entities: [mealData], currentUser: currentUser)

        // Verify results
        let meal = try mealService.fetchUnique(withUID: uid)
        XCTAssertNotNil(meal, "Meal should be created despite non-existent references")
        XCTAssertNil(meal?.owner, "Owner should not be set when reference is non-existent")
        XCTAssertNil(meal?.recipe, "Recipe should not be set when reference is non-existent")
        XCTAssertNil(meal?.todoItem, "TodoItem should not be set when reference is non-existent")
        XCTAssertTrue(
            meal?.shoppingListItems.isEmpty ?? false,
            "ShoppingListItems should be empty when references are non-existent")
    }

    func testProcessMultipleMeals() async throws {
        // Prepare test data
        let uid1 = UUID().uuidString
        let uid2 = UUID().uuidString

        let mealData1: [String: Any] = [
            "uid": uid1,
            "scalingFactor": 1.0,
            "mealType": "breakfast",
        ]

        let mealData2: [String: Any] = [
            "uid": uid2,
            "scalingFactor": 2.0,
            "mealType": "lunch",
        ]

        // Process the entities
        try await processor.process(entities: [mealData1, mealData2], currentUser: currentUser)

        // Verify results
        let meal1 = try mealService.fetchUnique(withUID: uid1)
        let meal2 = try mealService.fetchUnique(withUID: uid2)

        XCTAssertNotNil(meal1, "First meal should be created")
        XCTAssertNotNil(meal2, "Second meal should be created")
        XCTAssertEqual(meal1?.mealType, .breakfast)
        XCTAssertEqual(meal2?.mealType, .lunch)
    }
}
