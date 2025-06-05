import OSLog
import SwiftData
import XCTest

@testable import Vesta

class RecipeEntityProcessorTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var processor: RecipeEntityProcessor!
    var recipeService: RecipeService!
    var userService: UserService!
    var mealService: MealService!
    var logger: Logger!
    var currentUser: User!

    override func setUp() async throws {
        container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        context = ModelContext(container)

        logger = Logger(subsystem: "dev.vegardskjefstad.Vesta.Tests", category: "Tests")
        userService = UserService(modelContext: context)
        recipeService = RecipeService(modelContext: context)
        mealService = MealService(modelContext: context)

        processor = RecipeEntityProcessor(
            modelContext: context,
            logger: logger,
            recipes: recipeService,
            users: userService,
            meals: mealService
        )

        currentUser = Fixtures.createUser()
        context.insert(currentUser)
        try context.save()
    }

    override func tearDown() async throws {
        // Clear relationship references before batch deletion to prevent constraint violations
        let recipes = try context.fetch(FetchDescriptor<Recipe>())
        for recipe in recipes {
            recipe.meals = []
            recipe.ingredients.forEach { context.delete($0) }
            recipe.steps.forEach { context.delete($0) }
        }
        try context.save()

        // Delete entities in an order that respects relationship constraints
        try await container.mainContext.delete(model: RecipeStep.self)
        try await container.mainContext.delete(model: Ingredient.self)
        try await container.mainContext.delete(model: Recipe.self)
        try await container.mainContext.delete(model: Meal.self)
        try await container.mainContext.delete(model: User.self)
    }

    // MARK: - Tests

    func testProcessNewRecipe() async throws {
        // Prepare test data
        let uid = UUID().uuidString
        let recipeData: [String: Any] = [
            "uid": uid,
            "title": "Pancakes",
            "details": "Delicious breakfast pancakes",
            "isShared": true,
        ]

        // Process the entity
        try await processor.process(entities: [recipeData], currentUser: currentUser)

        // Verify results
        let recipe = try recipeService.fetchUnique(withUID: uid)
        XCTAssertNotNil(recipe, "Recipe should be created")
        XCTAssertEqual(recipe?.uid, uid)
        XCTAssertEqual(recipe?.title, "Pancakes")
        XCTAssertEqual(recipe?.details, "Delicious breakfast pancakes")
        XCTAssertEqual(recipe?.isShared, true)
        XCTAssertNil(recipe?.owner)
        XCTAssertTrue(recipe?.meals.isEmpty ?? false)
        XCTAssertTrue(recipe?.ingredients.isEmpty ?? false)
        XCTAssertTrue(recipe?.steps.isEmpty ?? false)
    }

    func testProcessNewRecipeWithOwner() async throws {
        // Prepare test data
        let uid = UUID().uuidString
        let owner = Fixtures.createUser()
        owner.uid = "test-owner-1"
        context.insert(owner)
        try context.save()

        let recipeData: [String: Any] = [
            "uid": uid,
            "title": "Pancakes",
            "details": "Delicious breakfast pancakes",
            "ownerId": "test-owner-1",
        ]

        // Process the entity
        try await processor.process(entities: [recipeData], currentUser: currentUser)

        // Verify results
        let recipe = try recipeService.fetchUnique(withUID: uid)
        XCTAssertNotNil(recipe, "Recipe should be created")
        XCTAssertEqual(recipe?.owner?.uid, "test-owner-1")
    }

    func testProcessNewRecipeWithIngredients() async throws {
        // Prepare test data
        let uid = UUID().uuidString
        let recipeData: [String: Any] = [
            "uid": uid,
            "title": "Pancakes",
            "details": "Delicious breakfast pancakes",
            "ingredients": [
                [
                    "name": "Flour",
                    "order": 1,
                    "quantity": 200.0,
                    "unit": "gram",
                ],
                [
                    "name": "Milk",
                    "order": 2,
                    "quantity": 300.0,
                    "unit": "milliliter",
                ],
                [
                    "name": "Eggs",
                    "order": 3,
                    "quantity": 2.0,
                    "unit": "piece",
                ],
            ],
        ]

        // Process the entity
        try await processor.process(entities: [recipeData], currentUser: currentUser)

        // Verify results
        let recipe = try recipeService.fetchUnique(withUID: uid)
        XCTAssertNotNil(recipe, "Recipe should be created")
        XCTAssertEqual(recipe?.ingredients.count, 3)

        let sortedIngredients = recipe?.sortedIngredients ?? []
        XCTAssertEqual(sortedIngredients[0].name, "Flour")
        XCTAssertEqual(sortedIngredients[0].quantity, 200)
        XCTAssertEqual(sortedIngredients[0].unit, .gram)

        XCTAssertEqual(sortedIngredients[1].name, "Milk")
        XCTAssertEqual(sortedIngredients[1].quantity, 300)
        XCTAssertEqual(sortedIngredients[1].unit, .milliliter)

        XCTAssertEqual(sortedIngredients[2].name, "Eggs")
        XCTAssertEqual(sortedIngredients[2].quantity, 2)
        XCTAssertEqual(sortedIngredients[2].unit, .piece)
    }

    func testProcessNewRecipeWithSteps() async throws {
        // Prepare test data
        let uid = UUID().uuidString
        let recipeData: [String: Any] = [
            "uid": uid,
            "title": "Pancakes",
            "details": "Delicious breakfast pancakes",
            "steps": [
                [
                    "order": 1,
                    "instruction": "Mix dry ingredients",
                    "type": "preparation",
                    "duration": 300.0,
                ],
                [
                    "order": 2,
                    "instruction": "Add wet ingredients and mix well",
                    "type": "preparation",
                    "duration": 180.0,
                ],
                [
                    "order": 3,
                    "instruction": "Cook on medium heat",
                    "type": "cooking",
                    "duration": 600.0,
                ],
            ],
        ]

        // Process the entity
        try await processor.process(entities: [recipeData], currentUser: currentUser)

        // Verify results
        let recipe = try recipeService.fetchUnique(withUID: uid)
        XCTAssertNotNil(recipe, "Recipe should be created")
        XCTAssertEqual(recipe?.steps.count, 3)

        let sortedSteps = recipe?.sortedSteps ?? []
        XCTAssertEqual(sortedSteps[0].instruction, "Mix dry ingredients")
        XCTAssertEqual(sortedSteps[0].type, .preparation)
        XCTAssertEqual(sortedSteps[0].duration, 300)

        XCTAssertEqual(sortedSteps[1].instruction, "Add wet ingredients and mix well")
        XCTAssertEqual(sortedSteps[1].type, .preparation)
        XCTAssertEqual(sortedSteps[1].duration, 180)

        XCTAssertEqual(sortedSteps[2].instruction, "Cook on medium heat")
        XCTAssertEqual(sortedSteps[2].type, .cooking)
        XCTAssertEqual(sortedSteps[2].duration, 600)
    }

    func testProcessRecipeWithMeals() async throws {
        // Prepare test data
        let uid = UUID().uuidString

        // Create meals that will be referenced
        let meal1 = Fixtures.breakfast(owner: currentUser)
        meal1.uid = "meal-1"
        let meal2 = Fixtures.dinner(owner: currentUser)
        meal2.uid = "meal-2"

        context.insert(meal1)
        context.insert(meal2)
        try context.save()

        let recipeData: [String: Any] = [
            "uid": uid,
            "title": "Pancakes",
            "details": "Delicious breakfast pancakes",
            "mealIds": ["meal-1", "meal-2"],
        ]

        // Process the entity
        try await processor.process(entities: [recipeData], currentUser: currentUser)

        // Verify results
        let recipe = try recipeService.fetchUnique(withUID: uid)
        XCTAssertNotNil(recipe, "Recipe should be created")
        XCTAssertEqual(recipe?.meals.count, 2)
        XCTAssertTrue(recipe?.meals.contains(where: { $0.uid == "meal-1" }) ?? false)
        XCTAssertTrue(recipe?.meals.contains(where: { $0.uid == "meal-2" }) ?? false)
    }

    func testUpdateExistingRecipe() async throws {
        // Insert an existing recipe
        let recipe = Fixtures.curry(owner: currentUser)
        recipe.uid = "existing-recipe"
        context.insert(recipe)
        try context.save()

        // Prepare update data
        let recipeData: [String: Any] = [
            "uid": "existing-recipe",
            "title": "Updated Curry",
            "details": "Updated curry recipe with more spices",
            "isShared": true,
        ]

        // Process the entity
        try await processor.process(entities: [recipeData], currentUser: currentUser)

        // Verify results
        let updatedRecipe = try recipeService.fetchUnique(withUID: "existing-recipe")
        XCTAssertNotNil(updatedRecipe)
        XCTAssertEqual(updatedRecipe?.title, "Updated Curry")
        XCTAssertEqual(updatedRecipe?.details, "Updated curry recipe with more spices")
        XCTAssertEqual(updatedRecipe?.isShared, true)
    }

    func testUpdateRecipeWithChangedIngredients() async throws {
        // Insert an existing recipe
        let recipe = Recipe(
            title: "Original Recipe", details: "Original details", owner: currentUser)
        recipe.uid = "existing-recipe"
        recipe.addIngredient(
            name: "Original Ingredient", quantity: 100, unit: .gram, currentUser: currentUser)
        context.insert(recipe)
        try context.save()

        // Prepare update data with new ingredients
        let recipeData: [String: Any] = [
            "uid": "existing-recipe",
            "title": "Updated Recipe",
            "details": "Updated details",
            "ingredients": [
                [
                    "name": "New Ingredient 1",
                    "order": 1,
                    "quantity": 200.0,
                    "unit": "gram",
                ],
                [
                    "name": "New Ingredient 2",
                    "order": 2,
                    "quantity": 300.0,
                    "unit": "milliliter",
                ],
            ],
        ]

        // Process the entity
        try await processor.process(entities: [recipeData], currentUser: currentUser)

        // Verify results
        let updatedRecipe = try recipeService.fetchUnique(withUID: "existing-recipe")
        XCTAssertNotNil(updatedRecipe)
        XCTAssertEqual(updatedRecipe?.title, "Updated Recipe")
        XCTAssertEqual(updatedRecipe?.ingredients.count, 2)

        let sortedIngredients = updatedRecipe?.sortedIngredients ?? []
        XCTAssertEqual(sortedIngredients[0].name, "New Ingredient 1")
        XCTAssertEqual(sortedIngredients[1].name, "New Ingredient 2")
        XCTAssertFalse(sortedIngredients.contains(where: { $0.name == "Original Ingredient" }))
    }

    func testUpdateRecipeWithChangedSteps() async throws {
        // Insert an existing recipe
        let recipe = Recipe(
            title: "Original Recipe", details: "Original details", owner: currentUser)
        recipe.uid = "existing-recipe"
        recipe.addStep(
            instruction: "Original step", type: .preparation, duration: 100,
            currentUser: currentUser)
        context.insert(recipe)
        try context.save()

        // Prepare update data with new steps
        let recipeData: [String: Any] = [
            "uid": "existing-recipe",
            "title": "Updated Recipe",
            "details": "Updated details",
            "steps": [
                [
                    "order": 1,
                    "instruction": "New Step 1",
                    "type": "preparation",
                    "duration": 200.0,
                ],
                [
                    "order": 2,
                    "instruction": "New Step 2",
                    "type": "cooking",
                    "duration": 300.0,
                ],
            ],
        ]

        // Process the entity
        try await processor.process(entities: [recipeData], currentUser: currentUser)

        // Verify results
        let updatedRecipe = try recipeService.fetchUnique(withUID: "existing-recipe")
        XCTAssertNotNil(updatedRecipe)
        XCTAssertEqual(updatedRecipe?.title, "Updated Recipe")
        XCTAssertEqual(updatedRecipe?.steps.count, 2)

        let sortedSteps = updatedRecipe?.sortedSteps ?? []
        XCTAssertEqual(sortedSteps[0].instruction, "New Step 1")
        XCTAssertEqual(sortedSteps[1].instruction, "New Step 2")
        XCTAssertFalse(sortedSteps.contains(where: { $0.instruction == "Original step" }))
    }

    func testUpdateRecipeWithChangedMeals() async throws {
        // Create meals
        let meal1 = Fixtures.breakfast(owner: currentUser)
        meal1.uid = "meal-1"
        let meal2 = Fixtures.lunch(owner: currentUser)
        meal2.uid = "meal-2"
        let meal3 = Fixtures.dinner(owner: currentUser)
        meal3.uid = "meal-3"

        // Insert an existing recipe with meals
        let recipe = Fixtures.curry(owner: currentUser)
        recipe.uid = "existing-recipe"
        recipe.meals = [meal1, meal2]

        context.insert(meal1)
        context.insert(meal2)
        context.insert(meal3)
        context.insert(recipe)
        try context.save()

        // Prepare update data with changed meals (remove meal1, keep meal2, add meal3)
        let recipeData: [String: Any] = [
            "uid": "existing-recipe",
            "title": "Curry",
            "details": "Spicy Indian curry",
            "mealIds": ["meal-2", "meal-3"],
        ]

        // Process the entity
        try await processor.process(entities: [recipeData], currentUser: currentUser)

        // Verify results
        let updatedRecipe = try recipeService.fetchUnique(withUID: "existing-recipe")
        XCTAssertNotNil(updatedRecipe)
        XCTAssertEqual(updatedRecipe?.meals.count, 2)
        XCTAssertFalse(updatedRecipe?.meals.contains(where: { $0.uid == "meal-1" }) ?? true)
        XCTAssertTrue(updatedRecipe?.meals.contains(where: { $0.uid == "meal-2" }) ?? false)
        XCTAssertTrue(updatedRecipe?.meals.contains(where: { $0.uid == "meal-3" }) ?? false)
    }

    func testRemoveMealsFromRecipe() async throws {
        // Create meals
        let meal1 = Fixtures.breakfast(owner: currentUser)
        meal1.uid = "meal-1"
        let meal2 = Fixtures.lunch(owner: currentUser)
        meal2.uid = "meal-2"

        // Insert an existing recipe with meals
        let recipe = Fixtures.curry(owner: currentUser)
        recipe.uid = "existing-recipe"
        recipe.meals = [meal1, meal2]

        context.insert(meal1)
        context.insert(meal2)
        context.insert(recipe)
        try context.save()

        // Prepare update data without meals
        let recipeData: [String: Any] = [
            "uid": "existing-recipe",
            "title": "Curry",
            "details": "Spicy Indian curry",
                // No mealIds means remove all meals
        ]

        // Process the entity
        try await processor.process(entities: [recipeData], currentUser: currentUser)

        // Verify results
        let updatedRecipe = try recipeService.fetchUnique(withUID: "existing-recipe")
        XCTAssertNotNil(updatedRecipe)
        XCTAssertTrue(updatedRecipe?.meals.isEmpty ?? false)
    }

    func testProcessRecipeWithoutUID() async throws {
        // Prepare test data without UID
        let recipeData: [String: Any] = [
            "title": "No UID Recipe",
            "details": "This recipe has no UID",
        ]

        // Count recipes before processing
        let recipesBefore = try context.fetch(FetchDescriptor<Recipe>())
        let countBefore = recipesBefore.count

        // Process the entity
        try await processor.process(entities: [recipeData], currentUser: currentUser)

        // Count recipes after processing
        let recipesAfter = try context.fetch(FetchDescriptor<Recipe>())
        let countAfter = recipesAfter.count

        // Verify no recipe was created
        XCTAssertEqual(countBefore, countAfter, "No recipe should be created when UID is missing")
    }

    func testProcessRecipeWithMissingRequiredProperties() async throws {
        // Prepare test data with missing required properties
        let recipeData: [String: Any] = [
            "uid": UUID().uuidString
            // Missing title and details
        ]

        // Count recipes before processing
        let recipesBefore = try context.fetch(FetchDescriptor<Recipe>())
        let countBefore = recipesBefore.count

        // Process the entity
        try await processor.process(entities: [recipeData], currentUser: currentUser)

        // Count recipes after processing
        let recipesAfter = try context.fetch(FetchDescriptor<Recipe>())
        let countAfter = recipesAfter.count

        // Verify no recipe was created
        XCTAssertEqual(
            countBefore, countAfter,
            "No recipe should be created when required properties are missing")
    }

    func testNonExistentReferences() async throws {
        // Prepare test data with non-existent references
        let uid = UUID().uuidString
        let recipeData: [String: Any] = [
            "uid": uid,
            "title": "Test Recipe",
            "details": "Recipe details",
            "ownerId": "non-existent-user",
            "mealIds": ["non-existent-meal"],
        ]

        // Process the entity
        try await processor.process(entities: [recipeData], currentUser: currentUser)

        // Verify results
        let recipe = try recipeService.fetchUnique(withUID: uid)
        XCTAssertNotNil(recipe, "Recipe should be created despite non-existent references")
        XCTAssertNil(recipe?.owner, "Owner should not be set when reference is non-existent")
        XCTAssertTrue(
            recipe?.meals.isEmpty ?? false,
            "Meals should be empty when references are non-existent")
    }

    func testProcessMultipleRecipes() async throws {
        // Prepare test data
        let uid1 = UUID().uuidString
        let uid2 = UUID().uuidString

        let recipeData1: [String: Any] = [
            "uid": uid1,
            "title": "First Recipe",
            "details": "Details for first recipe",
        ]

        let recipeData2: [String: Any] = [
            "uid": uid2,
            "title": "Second Recipe",
            "details": "Details for second recipe",
        ]

        // Process the entities
        try await processor.process(entities: [recipeData1, recipeData2], currentUser: currentUser)

        // Verify results
        let recipe1 = try recipeService.fetchUnique(withUID: uid1)
        let recipe2 = try recipeService.fetchUnique(withUID: uid2)

        XCTAssertNotNil(recipe1, "First recipe should be created")
        XCTAssertNotNil(recipe2, "Second recipe should be created")
        XCTAssertEqual(recipe1?.title, "First Recipe")
        XCTAssertEqual(recipe2?.title, "Second Recipe")
    }
}
