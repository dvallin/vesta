import OSLog
import SwiftData
import XCTest

@testable import Vesta

class ShoppingListItemEntityProcessorTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var processor: ShoppingListItemEntityProcessor!
    var shoppingListItemService: ShoppingListItemService!
    var userService: UserService!
    var todoItemService: TodoItemService!
    var mealService: MealService!
    var logger: Logger!
    var currentUser: User!

    override func setUp() async throws {
        container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        context = ModelContext(container)

        logger = Logger(subsystem: "dev.vegardskjefstad.Vesta.Tests", category: "Tests")
        userService = UserService(modelContext: context)
        shoppingListItemService = ShoppingListItemService(modelContext: context)
        todoItemService = TodoItemService(modelContext: context)
        mealService = MealService(modelContext: context)

        processor = ShoppingListItemEntityProcessor(
            modelContext: context,
            logger: logger,
            shoppingItems: shoppingListItemService,
            users: userService,
            todoItems: todoItemService,
            meals: mealService
        )

        currentUser = Fixtures.createUser()
        context.insert(currentUser)
        try context.save()
    }

    override func tearDown() async throws {
        // Clear relationship references before batch deletion to prevent constraint violations
        let items = try context.fetch(FetchDescriptor<ShoppingListItem>())
        for item in items {
            item.todoItem = nil
            item.meals = []
        }
        try context.save()

        // Delete entities in an order that respects relationship constraints
        try await container.mainContext.delete(model: ShoppingListItem.self)
        try await container.mainContext.delete(model: TodoItem.self)
        try await container.mainContext.delete(model: Meal.self)
        try await container.mainContext.delete(model: User.self)
    }

    // MARK: - Tests

    func testProcessNewShoppingListItem() async throws {
        // Prepare test data
        let uid = UUID().uuidString
        let shoppingItemData: [String: Any] = [
            "uid": uid,
            "name": "Bananas",
            "quantity": 5.0,
            "unit": "piece",
            "isShared": true,
        ]

        // Process the entity
        try await processor.process(entities: [shoppingItemData], currentUser: currentUser)

        // Verify results
        let item = try shoppingListItemService.fetchUnique(withUID: uid)
        XCTAssertNotNil(item, "ShoppingListItem should be created")
        XCTAssertEqual(item?.uid, uid)
        XCTAssertEqual(item?.name, "Bananas")
        XCTAssertEqual(item?.quantity, 5.0)
        XCTAssertEqual(item?.unit, .piece)
        XCTAssertEqual(item?.isShared, true)
        XCTAssertNil(item?.owner)
        XCTAssertNil(item?.todoItem)
        XCTAssertTrue(item?.meals.isEmpty ?? false)
    }

    func testProcessNewShoppingListItemWithOwner() async throws {
        // Prepare test data
        let uid = UUID().uuidString
        let owner = Fixtures.createUser()
        owner.uid = "test-owner-1"
        context.insert(owner)
        try context.save()

        let shoppingItemData: [String: Any] = [
            "uid": uid,
            "name": "Milk",
            "quantity": 1.0,
            "unit": "liter",
            "ownerId": "test-owner-1",
        ]

        // Process the entity
        try await processor.process(entities: [shoppingItemData], currentUser: currentUser)

        // Verify results
        let item = try shoppingListItemService.fetchUnique(withUID: uid)
        XCTAssertNotNil(item, "ShoppingListItem should be created")
        XCTAssertEqual(item?.owner?.uid, "test-owner-1")
    }

    func testProcessNewShoppingListItemWithTodoItem() async throws {
        // Prepare test data
        let uid = UUID().uuidString
        let todoItem = Fixtures.todoItem(
            title: "Buy groceries", details: "For dinner", owner: currentUser)
        todoItem.uid = "test-todo-1"
        context.insert(todoItem)
        try context.save()

        let shoppingItemData: [String: Any] = [
            "uid": uid,
            "name": "Cheese",
            "todoItemId": "test-todo-1",
        ]

        // Process the entity
        try await processor.process(entities: [shoppingItemData], currentUser: currentUser)

        // Verify results
        let item = try shoppingListItemService.fetchUnique(withUID: uid)
        XCTAssertNotNil(item, "ShoppingListItem should be created")
        XCTAssertEqual(item?.todoItem?.uid, "test-todo-1")
    }

    func testProcessNewShoppingListItemWithMeals() async throws {
        // Prepare test data
        let uid = UUID().uuidString
        let meal1 = Fixtures.dinner(scalingFactor: 1.0, owner: currentUser)
        meal1.uid = "meal-1"
        let meal2 = Fixtures.lunch(scalingFactor: 1.0, owner: currentUser)
        meal2.uid = "meal-2"
        context.insert(meal1)
        context.insert(meal2)
        try context.save()

        let shoppingItemData: [String: Any] = [
            "uid": uid,
            "name": "Tomatoes",
            "mealIds": ["meal-1", "meal-2"],
        ]

        // Process the entity
        try await processor.process(entities: [shoppingItemData], currentUser: currentUser)

        // Verify results
        let item = try shoppingListItemService.fetchUnique(withUID: uid)
        XCTAssertNotNil(item, "ShoppingListItem should be created")
        XCTAssertEqual(item?.meals.count, 2)
        XCTAssertTrue(item?.meals.contains(where: { $0.uid == "meal-1" }) ?? false)
        XCTAssertTrue(item?.meals.contains(where: { $0.uid == "meal-2" }) ?? false)
    }

    func testUpdateExistingShoppingListItem() async throws {
        // Insert an existing shopping list item
        let shoppingItem = Fixtures.shoppingListItem(
            name: "Apples", quantity: 3.0, owner: currentUser)
        shoppingItem.uid = "existing-item"
        context.insert(shoppingItem)
        try context.save()

        // Prepare update data
        let shoppingItemData: [String: Any] = [
            "uid": "existing-item",
            "name": "Green Apples",
            "quantity": 6.0,
            "unit": "piece",
            "isShared": true,
        ]

        // Process the entity
        try await processor.process(entities: [shoppingItemData], currentUser: currentUser)

        // Verify results
        let updatedItem = try shoppingListItemService.fetchUnique(withUID: "existing-item")
        XCTAssertNotNil(updatedItem)
        XCTAssertEqual(updatedItem?.name, "Green Apples")
        XCTAssertEqual(updatedItem?.quantity, 6.0)
        XCTAssertEqual(updatedItem?.unit, .piece)
        XCTAssertEqual(updatedItem?.isShared, true)
    }

    func testUpdateShoppingListItemWithChangedRelationships() async throws {
        // Create initial shopping item with relationships
        let todoItem1 = Fixtures.todoItem(
            title: "Buy groceries", details: "For dinner", owner: currentUser)
        todoItem1.uid = "todo-1"
        let meal1 = Fixtures.dinner(scalingFactor: 1.0, owner: currentUser)
        meal1.uid = "meal-1"
        let meal2 = Fixtures.lunch(scalingFactor: 1.0, owner: currentUser)
        meal2.uid = "meal-2"

        let shoppingItem = Fixtures.shoppingListItem(
            name: "Potatoes",
            quantity: 1.0,
            unit: .kilogram,
            todoItem: todoItem1,
            owner: currentUser
        )
        shoppingItem.uid = "existing-item"
        shoppingItem.meals.append(meal1)
        shoppingItem.meals.append(meal2)

        context.insert(todoItem1)
        context.insert(meal1)
        context.insert(meal2)
        context.insert(shoppingItem)
        try context.save()

        // Create new relationships
        let todoItem2 = Fixtures.todoItem(
            title: "Buy more groceries", details: "For tomorrow", owner: currentUser)
        todoItem2.uid = "todo-2"
        let meal3 = Fixtures.breakfast(scalingFactor: 1.0, owner: currentUser)
        meal3.uid = "meal-3"

        context.insert(todoItem2)
        context.insert(meal3)
        try context.save()

        // Prepare update data with changed relationships
        let shoppingItemData: [String: Any] = [
            "uid": "existing-item",
            "name": "Potatoes",
            "todoItemId": "todo-2",
            "mealIds": ["meal-2", "meal-3"],  // Keep meal-2 but replace meal-1 with meal-3
        ]

        // Process the entity
        try await processor.process(entities: [shoppingItemData], currentUser: currentUser)

        // Verify results
        let updatedItem = try shoppingListItemService.fetchUnique(withUID: "existing-item")
        XCTAssertNotNil(updatedItem)
        XCTAssertEqual(updatedItem?.todoItem?.uid, "todo-2")
        XCTAssertEqual(updatedItem?.meals.count, 2)
        XCTAssertTrue(updatedItem?.meals.contains(where: { $0.uid == "meal-2" }) ?? false)
        XCTAssertTrue(updatedItem?.meals.contains(where: { $0.uid == "meal-3" }) ?? false)
        XCTAssertFalse(updatedItem?.meals.contains(where: { $0.uid == "meal-1" }) ?? true)
    }

    func testRemoveRelationshipsFromShoppingListItem() async throws {
        // Create initial shopping item with relationships
        let todoItem = Fixtures.todoItem(
            title: "Buy groceries", details: "For dinner", owner: currentUser)
        todoItem.uid = "todo-1"
        let meal = Fixtures.dinner(scalingFactor: 1.0, owner: currentUser)
        meal.uid = "meal-1"

        let shoppingItem = Fixtures.shoppingListItem(
            name: "Carrots",
            todoItem: todoItem,
            owner: currentUser
        )
        shoppingItem.uid = "existing-item"
        shoppingItem.meals.append(meal)

        context.insert(todoItem)
        context.insert(meal)
        context.insert(shoppingItem)
        try context.save()

        // Prepare update data with removed relationships
        let shoppingItemData: [String: Any] = [
            "uid": "existing-item",
            "name": "Carrots",
                // No todoItemId or mealIds means remove these relationships
        ]

        // Process the entity
        try await processor.process(entities: [shoppingItemData], currentUser: currentUser)

        // Verify results
        let updatedItem = try shoppingListItemService.fetchUnique(withUID: "existing-item")
        XCTAssertNotNil(updatedItem)
        XCTAssertNil(updatedItem?.todoItem)
        XCTAssertTrue(updatedItem?.meals.isEmpty ?? false)
    }

    func testProcessShoppingListItemWithoutUID() async throws {
        // Prepare test data without UID
        let shoppingItemData: [String: Any] = [
            "name": "Eggs",
            "quantity": 12.0,
        ]

        // Count items before processing
        let itemsBefore = try context.fetch(FetchDescriptor<ShoppingListItem>())
        let countBefore = itemsBefore.count

        // Process the entity
        try await processor.process(entities: [shoppingItemData], currentUser: currentUser)

        // Count items after processing
        let itemsAfter = try context.fetch(FetchDescriptor<ShoppingListItem>())
        let countAfter = itemsAfter.count

        // Verify no item was created
        XCTAssertEqual(
            countBefore, countAfter, "No ShoppingListItem should be created when UID is missing")
    }

    func testProcessShoppingListItemWithMissingRequiredProperties() async throws {
        // Prepare test data with missing required properties
        let shoppingItemData: [String: Any] = [
            "uid": UUID().uuidString
            // Missing name
        ]

        // Count items before processing
        let itemsBefore = try context.fetch(FetchDescriptor<ShoppingListItem>())
        let countBefore = itemsBefore.count

        // Process the entity
        try await processor.process(entities: [shoppingItemData], currentUser: currentUser)

        // Count items after processing
        let itemsAfter = try context.fetch(FetchDescriptor<ShoppingListItem>())
        let countAfter = itemsAfter.count

        // Verify no item was created
        XCTAssertEqual(
            countBefore, countAfter,
            "No ShoppingListItem should be created when required properties are missing")
    }

    func testNonExistentReferences() async throws {
        // Prepare test data with non-existent references
        let uid = UUID().uuidString
        let shoppingItemData: [String: Any] = [
            "uid": uid,
            "name": "Pasta",
            "ownerId": "non-existent-user",
            "todoItemId": "non-existent-todo",
            "mealIds": ["non-existent-meal"],
        ]

        // Process the entity
        try await processor.process(entities: [shoppingItemData], currentUser: currentUser)

        // Verify results
        let item = try shoppingListItemService.fetchUnique(withUID: uid)
        XCTAssertNotNil(item, "ShoppingListItem should be created despite non-existent references")
        XCTAssertNil(item?.owner, "Owner should not be set when reference is non-existent")
        XCTAssertNil(item?.todoItem, "TodoItem should not be set when reference is non-existent")
        XCTAssertTrue(
            item?.meals.isEmpty ?? false,
            "Meals should be empty when references are non-existent")
    }

    func testProcessMultipleShoppingListItems() async throws {
        // Prepare test data
        let uid1 = UUID().uuidString
        let uid2 = UUID().uuidString

        let shoppingItemData1: [String: Any] = [
            "uid": uid1,
            "name": "Bread",
            "quantity": 1.0,
        ]

        let shoppingItemData2: [String: Any] = [
            "uid": uid2,
            "name": "Butter",
            "quantity": 250.0,
            "unit": "gram",
        ]

        // Process the entities
        try await processor.process(
            entities: [shoppingItemData1, shoppingItemData2], currentUser: currentUser)

        // Verify results
        let item1 = try shoppingListItemService.fetchUnique(withUID: uid1)
        let item2 = try shoppingListItemService.fetchUnique(withUID: uid2)

        XCTAssertNotNil(item1, "First shopping list item should be created")
        XCTAssertNotNil(item2, "Second shopping list item should be created")
        XCTAssertEqual(item1?.name, "Bread")
        XCTAssertEqual(item2?.name, "Butter")
        XCTAssertEqual(item2?.quantity, 250.0)
        XCTAssertEqual(item2?.unit, .gram)
    }
}
