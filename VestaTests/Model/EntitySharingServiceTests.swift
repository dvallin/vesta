import Foundation
import XCTest
@testable import Vesta
import SwiftData

final class EntitySharingServiceTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var user: User!
    var sharingService: EntitySharingService!
    
    var todoItemService: TodoItemService!
    var recipeService: RecipeService!
    var mealService: MealService!
    var shoppingItemService: ShoppingListItemService!
    var todoItemCategoryService: TodoItemCategoryService!
    
    override func setUp() {
        super.setUp()
        container = try! ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        context = ModelContext(container)
        
        // Set up services
        todoItemService = TodoItemService(modelContext: context)
        recipeService = RecipeService(modelContext: context)
        mealService = MealService(modelContext: context)
        shoppingItemService = ShoppingListItemService(modelContext: context)
        todoItemCategoryService = TodoItemCategoryService(modelContext: context)
        
        // Create user for testing
        user = User(uid: "test-user-123", email: "test@example.com")
        context.insert(user)
        
        // Create sharing service
        sharingService = EntitySharingService(
            modelContext: context,
            todoItemService: todoItemService,
            mealService: mealService,
            recipeService: recipeService,
            shoppingItemService: shoppingItemService
        )
        
        // Set up test data
        createTestData()
    }
    
    override func tearDown() {
        container = nil
        context = nil
        user = nil
        sharingService = nil
        super.tearDown()
    }
    
    // Test meal sharing
    func testMealSharing() throws {
        // Initially nothing should be shared
        XCTAssertFalse(areMealsShared(), "Meals should not be shared initially")
        
        // Update user preferences to share meals
        user.shareMeals = true
        
        // Apply sharing preferences
        let updatedCount = sharingService.updateEntitySharingStatus(for: user)
        
        // Verify meals are shared
        XCTAssertTrue(areMealsShared(), "Meals should be shared after updating preferences")
        XCTAssertGreaterThan(updatedCount, 0, "Some entities should have been updated")
    }
    
    // Test shopping item sharing
    func testShoppingItemSharing() throws {
        // Initially nothing should be shared
        XCTAssertFalse(areShoppingItemsShared(), "Shopping items should not be shared initially")
        
        // Update user preferences to share shopping items
        user.shareShoppingItems = true
        
        // Apply sharing preferences
        let updatedCount = sharingService.updateEntitySharingStatus(for: user)
        
        // Verify shopping items are shared
        XCTAssertTrue(areShoppingItemsShared(), "Shopping items should be shared after updating preferences")
        XCTAssertGreaterThan(updatedCount, 0, "Some entities should have been updated")
    }
    
    // Test todo item category sharing
    func testTodoCategorySharing() throws {
        // Create a category
        let workCategory = TodoItemCategory(name: "Work", color: "#FF0000")
        context.insert(workCategory)
        
        // Create a todo item with that category
        let todoItem = TodoItem(title: "Test Task", details: "Details", owner: user)
        todoItem.category = workCategory
        context.insert(todoItem)
        
        // Initially nothing should be shared
        XCTAssertFalse(isTodoItemShared(todoItem), "Todo item should not be shared initially")
        
        // Update user preferences to share this category
        user.shareTodoItemCategories = [workCategory]
        
        // Apply sharing preferences
        let updatedCount = sharingService.updateEntitySharingStatus(for: user)
        
        // Verify todo item with this category is shared
        XCTAssertTrue(isTodoItemShared(todoItem), "Todo item with shared category should be shared")
        XCTAssertGreaterThan(updatedCount, 0, "Some entities should have been updated")
    }
    
    // MARK: - Helper Methods
    
    private func createTestData() {
        // Create test meals
        let meal1 = Meal(scalingFactor: 1.0, todoItem: nil, recipe: nil, mealType: .breakfast, owner: user)
        let meal2 = Meal(scalingFactor: 1.0, todoItem: nil, recipe: nil, mealType: .lunch, owner: user)
        context.insert(meal1)
        context.insert(meal2)
        
        // Create test recipes
        let recipe1 = Recipe(title: "Test Recipe", details: "Test details", owner: user)
        context.insert(recipe1)
        
        // Create test shopping items
        let item1 = ShoppingListItem(name: "Test Item 1", quantity: 1.0, unit: .piece, owner: user)
        let item2 = ShoppingListItem(name: "Test Item 2", quantity: 2.0, unit: .piece, owner: user)
        context.insert(item1)
        context.insert(item2)
        
        // Save test data
        try? context.save()
    }
    
    private func areMealsShared() -> Bool {
        let descriptor = FetchDescriptor<Meal>(
            predicate: #Predicate<Meal> { meal in meal.owner?.uid == user.uid }
        )
        
        guard let meals = try? context.fetch(descriptor), !meals.isEmpty else { return false }
        
        // Check if all meals are shared
        return meals.allSatisfy { $0.isShared }
    }
    
    private func areRecipesShared() -> Bool {
        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate<Recipe> { recipe in recipe.owner?.uid == user.uid }
        )
        
        guard let recipes = try? context.fetch(descriptor), !recipes.isEmpty else { return false }
        
        // Check if all recipes are shared
        return recipes.allSatisfy { $0.isShared }
    }
    
    private func areShoppingItemsShared() -> Bool {
        let descriptor = FetchDescriptor<ShoppingListItem>(
            predicate: #Predicate<ShoppingListItem> { item in item.owner?.uid == user.uid }
        )
        
        guard let items = try? context.fetch(descriptor), !items.isEmpty else { return false }
        
        // Check if all shopping items are shared
        return items.allSatisfy { $0.isShared }
    }
    
    private func isTodoItemShared(_ item: TodoItem) -> Bool {
        let descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate<TodoItem> { $0.id == item.id }
        )
        
        guard let items = try? context.fetch(descriptor), let item = items.first else { return false }
        
        return item.isShared
    }
}