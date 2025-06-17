import Foundation
import OSLog
import SwiftData
import XCTest

@testable import Vesta

class TodoItemEntityProcessorTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var processor: TodoItemEntityProcessor!
    var todoItemService: TodoItemService!
    var userService: UserService!
    var mealService: MealService!
    var shoppingListItemService: ShoppingListItemService!
    var todoItemCategoryService: TodoItemCategoryService!
    var logger: Logger!
    var currentUser: User!

    override func setUp() async throws {
        container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        context = ModelContext(container)

        logger = Logger()
        todoItemService = TodoItemService(modelContext: context)
        userService = UserService(modelContext: context)
        mealService = MealService(modelContext: context)
        shoppingListItemService = ShoppingListItemService(modelContext: context)
        todoItemCategoryService = TodoItemCategoryService(modelContext: context)

        processor = TodoItemEntityProcessor(
            modelContext: context,
            logger: logger,
            todoItems: todoItemService,
            users: userService,
            meals: mealService,
            shoppingItems: shoppingListItemService,
            todoItemCategories: todoItemCategoryService
        )

        // Create a current user for testing
        currentUser = User(
            uid: "current-user-123", email: "test@example.com", displayName: "Test User")
        context.insert(currentUser)
    }

    override func tearDown() async throws {
        try await container.mainContext.delete(model: User.self)
        try await container.mainContext.delete(model: TodoItem.self)
        try await container.mainContext.delete(model: Meal.self)
        try await container.mainContext.delete(model: ShoppingListItem.self)
        try await container.mainContext.delete(model: TodoItemCategory.self)
    }

    @MainActor
    func testProcessNewTodoItem() async throws {
        // Given a new todo item entity data
        let todoUID = "todo-123"
        let todoData: [String: Any] = [
            "uid": todoUID,
            "title": "Test Todo",
            "details": "Todo details",
            "isCompleted": false,
            "priority": 2,
            "ignoreTimeComponent": true,
        ]

        // When we process the entity
        try await processor.process(entities: [todoData], currentUser: currentUser)

        // Then a new todo item should be created
        let todoItems = try fetchAllTodoItems()
        XCTAssertEqual(todoItems.count, 1)

        // Verify the todo item properties
        let todoItem = todoItems[0]
        XCTAssertEqual(todoItem.uid, todoUID)
        XCTAssertEqual(todoItem.title, "Test Todo")
        XCTAssertEqual(todoItem.details, "Todo details")
        XCTAssertEqual(todoItem.isCompleted, false)
        XCTAssertEqual(todoItem.priority, 2)
        XCTAssertEqual(todoItem.ignoreTimeComponent, true)
        XCTAssertNil(todoItem.owner)
        XCTAssertNil(todoItem.dueDate)
        XCTAssertNil(todoItem.recurrenceFrequency)
        XCTAssertNil(todoItem.recurrenceType)
        XCTAssertNil(todoItem.recurrenceInterval)
        XCTAssertFalse(todoItem.dirty)
    }

    @MainActor
    func testProcessNewTodoItemWithOwner() async throws {
        // Given a user
        let owner = User(uid: "owner-123", email: "owner@example.com", displayName: "Owner")
        context.insert(owner)

        // And a new todo item entity data with owner
        let todoUID = "todo-with-owner-123"
        let todoData: [String: Any] = [
            "uid": todoUID,
            "title": "Owned Todo",
            "details": "This todo has an owner",
            "ownerId": owner.uid,
        ]

        // When we process the entity
        try await processor.process(entities: [todoData], currentUser: currentUser)

        // Then a new todo item should be created with the owner set
        let todoItem = try todoItemService.fetchUnique(withUID: todoUID)
        XCTAssertNotNil(todoItem)
        XCTAssertEqual(todoItem?.owner?.uid, owner.uid)
        XCTAssertEqual(todoItem?.owner?.displayName, "Owner")
    }

    @MainActor
    func testUpdateExistingTodoItem() async throws {
        // Given an existing todo item
        let todoItem = Fixtures.todoItem(
            title: "Original Title",
            details: "Original Details",
            owner: currentUser
        )
        todoItem.uid = "existing-todo-123"
        todoItem.markAsSynced()  // Clear dirty flag
        context.insert(todoItem)

        // And updated entity data
        let updatedData: [String: Any] = [
            "uid": todoItem.uid,
            "title": "Updated Title",
            "details": "Updated Details",
            "isCompleted": true,
            "priority": 1,
            "ownerId": currentUser.uid,
        ]

        // When we process the entity
        try await processor.process(entities: [updatedData], currentUser: currentUser)

        // Then the todo item should be updated
        let updatedTodo = try todoItemService.fetchUnique(withUID: todoItem.uid)
        XCTAssertNotNil(updatedTodo)
        XCTAssertEqual(updatedTodo?.title, "Updated Title")
        XCTAssertEqual(updatedTodo?.details, "Updated Details")
        XCTAssertEqual(updatedTodo?.isCompleted, true)
        XCTAssertEqual(updatedTodo?.priority, 1)
        XCTAssertEqual(updatedTodo?.owner?.uid, currentUser.uid)
        XCTAssertFalse(updatedTodo!.dirty)
    }

    @MainActor
    func testProcessTodoItemWithCategory() async throws {
        // Given a new todo item entity data with a category
        let todoUID = "todo-with-category-123"
        let todoData: [String: Any] = [
            "uid": todoUID,
            "title": "Categorized Todo",
            "details": "This todo has a category",
            "categoryName": "Work",
        ]

        // When we process the entity
        try await processor.process(entities: [todoData], currentUser: currentUser)

        // Then a new todo item should be created with the category
        let todoItem = try todoItemService.fetchUnique(withUID: todoUID)
        XCTAssertNotNil(todoItem)
        XCTAssertEqual(todoItem?.category?.name, "Work")

        // And the category should be created if it didn't exist
        let categories = try fetchAllTodoItemCategories()
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories[0].name, "Work")
    }

    @MainActor
    func testProcessTodoItemWithMeal() async throws {
        // Create a fixture for meal
        // Given a meal
        let meal = createTestMeal(name: "Test Dinner", owner: currentUser)
        meal.uid = "meal-123"
        context.insert(meal)

        // And a new todo item entity data with a meal reference
        let todoUID = "todo-with-meal-123"
        let todoData: [String: Any] = [
            "uid": todoUID,
            "title": "Meal Todo",
            "details": "This todo is linked to a meal",
            "mealId": meal.uid,
        ]

        // When we process the entity
        try await processor.process(entities: [todoData], currentUser: currentUser)

        // Then a new todo item should be created with the meal reference
        let todoItem = try todoItemService.fetchUnique(withUID: todoUID)
        XCTAssertNotNil(todoItem)
        XCTAssertEqual(todoItem?.meal?.uid, meal.uid)
    }

    @MainActor
    func testProcessTodoItemWithShoppingListItem() async throws {
        // Given a shopping list item
        let shoppingItem = createTestShoppingListItem(name: "Test Item", owner: currentUser)
        shoppingItem.uid = "shopping-123"
        context.insert(shoppingItem)

        // And a new todo item entity data with a shopping item reference
        let todoUID = "todo-with-shopping-123"
        let todoData: [String: Any] = [
            "uid": todoUID,
            "title": "Shopping Todo",
            "details": "This todo is linked to a shopping item",
            "shoppingListItemId": shoppingItem.uid,
        ]

        // When we process the entity
        try await processor.process(entities: [todoData], currentUser: currentUser)

        // Then a new todo item should be created with the shopping item reference
        let todoItem = try todoItemService.fetchUnique(withUID: todoUID)
        XCTAssertNotNil(todoItem)
        XCTAssertEqual(todoItem?.shoppingListItem?.uid, shoppingItem.uid)
        XCTAssertEqual(todoItem?.shoppingListItem?.name, "Test Item")
    }

    @MainActor
    func testProcessTodoItemWithRecurrence() async throws {
        // Given a new todo item entity data with recurrence settings
        let todoUID = "recurring-todo-123"
        let todoData: [String: Any] = [
            "uid": todoUID,
            "title": "Recurring Todo",
            "details": "This todo recurs weekly",
            "recurrenceFrequency": "weekly",
            "recurrenceType": "fixed",
            "recurrenceInterval": 2,
        ]

        // When we process the entity
        try await processor.process(entities: [todoData], currentUser: currentUser)

        // Then a new todo item should be created with recurrence settings
        let todoItem = try todoItemService.fetchUnique(withUID: todoUID)
        XCTAssertNotNil(todoItem)
        XCTAssertEqual(todoItem?.recurrenceFrequency, .weekly)
        XCTAssertEqual(todoItem?.recurrenceType, .fixed)
        XCTAssertEqual(todoItem?.recurrenceInterval, 2)
    }

    @MainActor
    func testRemoveRelationships() async throws {
        // Given an existing todo item with all relationships
        let owner = User(uid: "owner-to-remove", email: "owner@example.com", displayName: "Owner")

        let meal = createTestMeal(name: "Meal to Remove", owner: owner)
        meal.uid = "meal-to-remove"

        let shoppingItem = createTestShoppingListItem(name: "Shopping Item to Remove", owner: owner)
        shoppingItem.uid = "shopping-to-remove"

        let category = todoItemCategoryService.fetchOrCreate(named: "Category to Remove")

        context.insert(owner)
        context.insert(meal)
        context.insert(shoppingItem)

        let todoItem = Fixtures.todoItem(
            title: "Todo with Relationships",
            details: "All relationships will be removed",
            category: category,
            owner: owner
        )
        todoItem.uid = "relationships-todo-123"
        todoItem.meal = meal
        todoItem.shoppingListItem = shoppingItem
        todoItem.markAsSynced()
        context.insert(todoItem)

        // And updated entity data without relationships
        let updatedData: [String: Any] = [
            "uid": todoItem.uid,
            "title": "Todo without Relationships",
            "details": "All relationships have been removed",
        ]

        // When we process the entity
        try await processor.process(entities: [updatedData], currentUser: currentUser)

        // Then the todo item should have all relationships removed
        let updatedTodo = try todoItemService.fetchUnique(withUID: todoItem.uid)
        XCTAssertNotNil(updatedTodo)
        XCTAssertNil(updatedTodo?.owner)
        XCTAssertNil(updatedTodo?.meal)
        XCTAssertNil(updatedTodo?.shoppingListItem)
        XCTAssertNil(updatedTodo?.category)
    }

    @MainActor
    func testProcessTodoItemWithoutUID() async throws {
        // Given a todo item entity data without UID
        let todoData: [String: Any] = [
            "title": "Invalid Todo",
            "details": "This should be skipped",
        ]

        // When we process the entity
        try await processor.process(entities: [todoData], currentUser: currentUser)

        // Then no todo item should be created
        let todoItems = try fetchAllTodoItems()
        XCTAssertEqual(todoItems.count, 0)
    }

    @MainActor
    func testProcessTodoItemWithMissingRequiredProperties() async throws {
        // Given a new todo item entity data with UID but missing required title/details
        let todoData: [String: Any] = [
            "uid": "missing-required-props-123"
        ]

        // When we process the entity
        try await processor.process(entities: [todoData], currentUser: currentUser)

        // Then no todo item should be created
        let todoItems = try fetchAllTodoItems()
        XCTAssertEqual(todoItems.count, 0)
    }

    @MainActor
    func testChangeCategory() async throws {
        // Given a todo item with a category
        let originalCategory = todoItemCategoryService.fetchOrCreate(named: "Original Category")

        let todoItem = Fixtures.todoItem(
            title: "Categorized Todo",
            details: "Has a category",
            category: originalCategory,
            owner: currentUser
        )
        todoItem.uid = "change-category-123"
        todoItem.markAsSynced()
        context.insert(todoItem)

        // And updated entity data with a different category
        let updatedData: [String: Any] = [
            "uid": todoItem.uid,
            "title": "Categorized Todo",
            "details": "Has a category",
            "categoryName": "New Category",
        ]

        // When we process the entity
        try await processor.process(entities: [updatedData], currentUser: currentUser)

        // Then the todo item should have the new category
        let updatedTodo = try todoItemService.fetchUnique(withUID: todoItem.uid)
        XCTAssertNotNil(updatedTodo)
        XCTAssertEqual(updatedTodo?.category?.name, "New Category")

        // And both categories should exist
        let categories = try fetchAllTodoItemCategories()
        XCTAssertEqual(categories.count, 2)
        XCTAssertTrue(categories.contains { $0.name == "Original Category" })
        XCTAssertTrue(categories.contains { $0.name == "New Category" })
    }

    @MainActor
    func testMultipleTodoItems() async throws {
        // Given multiple todo item entities
        let todoData1: [String: Any] = [
            "uid": "multi-todo-1",
            "title": "First Todo",
            "details": "First details",
        ]

        let todoData2: [String: Any] = [
            "uid": "multi-todo-2",
            "title": "Second Todo",
            "details": "Second details",
        ]

        // When we process the entities
        try await processor.process(entities: [todoData1, todoData2], currentUser: currentUser)

        // Then both todo items should be created
        let todoItems = try fetchAllTodoItems()
        XCTAssertEqual(todoItems.count, 2)

        // Verify the first todo item
        let firstTodo = try todoItemService.fetchUnique(withUID: "multi-todo-1")
        XCTAssertEqual(firstTodo?.title, "First Todo")

        // Verify the second todo item
        let secondTodo = try todoItemService.fetchUnique(withUID: "multi-todo-2")
        XCTAssertEqual(secondTodo?.title, "Second Todo")
    }

    // Helper methods for fetching entities
    private func fetchAllTodoItems() throws -> [TodoItem] {
        let descriptor = FetchDescriptor<TodoItem>()
        return try context.fetch(descriptor)
    }

    private func fetchAllTodoItemCategories() throws -> [TodoItemCategory] {
        let descriptor = FetchDescriptor<TodoItemCategory>()
        return try context.fetch(descriptor)
    }

    // Helper methods for creating test entities
    private func createTestMeal(name: String, owner: User) -> Meal {
        let todoItem = Fixtures.todoItem(
            title: "\(name) Todo",
            details: "Todo for \(name)",
            owner: owner
        )

        let meal = Meal(
            scalingFactor: 1.0,
            todoItem: todoItem,
            recipe: nil,
            mealType: .dinner,
            owner: owner
        )
        return meal
    }

    private func createTestShoppingListItem(name: String, owner: User) -> ShoppingListItem {
        let todoItem = Fixtures.todoItem(
            title: "Buy \(name)",
            details: "Shopping todo for \(name)",
            owner: owner
        )

        return ShoppingListItem(
            name: name,
            quantity: 1,
            unit: nil,
            todoItem: todoItem,
            owner: owner
        )
    }
}
