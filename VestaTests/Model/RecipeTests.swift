import SwiftData
import XCTest

@testable import Vesta

final class RecipeTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var user: User!

    override func setUp() {
        super.setUp()
        container = try! ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        context = ModelContext(container)

        // Set up the UserAuthService to return our test user
        user = Fixtures.createUser()
        UserAuthService.shared.setCurrentUser(user: user)
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    // MARK: - Creation Tests

    func testCreateRecipe() throws {
        // Arrange & Act
        let recipe = Recipe(
            title: "Test Recipe",
            details: "Test Details",
            owner: user
        )
        context.insert(recipe)

        // Assert
        XCTAssertEqual(recipe.title, "Test Recipe")
        XCTAssertEqual(recipe.details, "Test Details")
        XCTAssertEqual(recipe.owner?.uid, user.uid)
        XCTAssertTrue(recipe.ingredients.isEmpty)
        XCTAssertTrue(recipe.steps.isEmpty)
        XCTAssertTrue(recipe.meals.isEmpty)
        XCTAssertTrue(recipe.dirty, "New recipe should be marked as dirty")
    }

    func testCreateRecipeWithIngredientsAndSteps() throws {
        // Arrange
        let ingredients = [
            Ingredient(name: "Flour", order: 1, quantity: 250, unit: .gram),
            Ingredient(name: "Sugar", order: 2, quantity: 100, unit: .gram),
        ]

        let steps = [
            RecipeStep(
                order: 1, instruction: "Mix dry ingredients", type: .preparation, duration: 300),
            RecipeStep(order: 2, instruction: "Bake in oven", type: .cooking, duration: 1800),
        ]

        // Act
        let recipe = Recipe(
            title: "Cake",
            details: "Simple cake recipe",
            ingredients: ingredients,
            steps: steps,
            owner: user
        )
        context.insert(recipe)

        // Assert
        XCTAssertEqual(recipe.title, "Cake")
        XCTAssertEqual(recipe.details, "Simple cake recipe")
        XCTAssertEqual(recipe.ingredients.count, 2)
        XCTAssertEqual(recipe.steps.count, 2)
        XCTAssertTrue(recipe.dirty, "New recipe should be marked as dirty")

        // Verify ingredients are linked to recipe
        for ingredient in recipe.ingredients {
            XCTAssertEqual(ingredient.recipe?.id, recipe.id)
        }

        // Verify steps are linked to recipe
        for step in recipe.steps {
            XCTAssertEqual(step.recipe?.id, recipe.id)
        }
    }

    // MARK: - Property Update Tests

    func testSetTitle() throws {
        // Arrange
        let recipe = Fixtures.bolognese(owner: user)
        context.insert(recipe)
        recipe.markAsSynced()  // Reset dirty flag

        // Act
        recipe.setTitle("Updated Bolognese")

        // Assert
        XCTAssertEqual(recipe.title, "Updated Bolognese")
        XCTAssertTrue(recipe.dirty, "Recipe should be marked as dirty after title change")
    }

    func testSetDetails() throws {
        // Arrange
        let recipe = Fixtures.bolognese(owner: user)
        context.insert(recipe)
        recipe.markAsSynced()  // Reset dirty flag

        // Act
        recipe.setDetails("New detailed instructions")

        // Assert
        XCTAssertEqual(recipe.details, "New detailed instructions")
        XCTAssertTrue(recipe.dirty, "Recipe should be marked as dirty after details change")
    }

    // MARK: - Ingredient Management Tests

    func testAddIngredient() throws {
        // Arrange
        let recipe = Fixtures.curry(owner: user)
        context.insert(recipe)
        recipe.markAsSynced()  // Reset dirty flag
        let initialCount = recipe.ingredients.count

        // Act
        recipe.addIngredient(name: "Garlic", quantity: 3, unit: .piece)

        // Assert
        XCTAssertEqual(recipe.ingredients.count, initialCount + 1)
        XCTAssertTrue(recipe.ingredients.contains { $0.name == "Garlic" })
        XCTAssertEqual(recipe.ingredients.last?.order, initialCount + 1)
        XCTAssertTrue(recipe.dirty, "Recipe should be marked as dirty after adding ingredient")
    }

    func testRemoveIngredient() throws {
        // Arrange
        let recipe = Fixtures.bolognese(owner: user)
        context.insert(recipe)
        recipe.markAsSynced()  // Reset dirty flag
        let initialCount = recipe.ingredients.count
        let ingredientToRemove = recipe.ingredients.first!

        // Act
        recipe.removeIngredient(ingredientToRemove)

        // Assert
        XCTAssertEqual(recipe.ingredients.count, initialCount - 1)
        XCTAssertFalse(recipe.ingredients.contains { $0.id == ingredientToRemove.id })
        XCTAssertTrue(recipe.dirty, "Recipe should be marked as dirty after removing ingredient")
    }

    func testMoveIngredient() throws {
        // Arrange
        let recipe = Fixtures.bolognese(owner: user)
        context.insert(recipe)
        recipe.markAsSynced()  // Reset dirty flag

        // Get the initial order
        let initialIngredients = recipe.sortedIngredients
        let firstIngredient = initialIngredients[0]

        // Act - move the first ingredient to the end
        recipe.moveIngredient(from: IndexSet(integer: 0), to: recipe.ingredients.count)

        // Assert
        let newIngredients = recipe.sortedIngredients
        XCTAssertEqual(
            newIngredients.last?.id, firstIngredient.id, "The first ingredient should now be last")
        XCTAssertTrue(recipe.dirty, "Recipe should be marked as dirty after moving ingredient")

        // Verify all orders are sequential and start from 1
        for (index, ingredient) in newIngredients.enumerated() {
            XCTAssertEqual(ingredient.order, index + 1, "Ingredient order should be sequential")
        }
    }

    // MARK: - Step Management Tests

    func testAddStep() throws {
        // Arrange
        let recipe = Fixtures.curry(owner: user)
        context.insert(recipe)
        recipe.markAsSynced()  // Reset dirty flag
        let initialCount = recipe.steps.count

        // Act
        recipe.addStep(instruction: "Serve hot", type: .preparation, duration: 60)

        // Assert
        XCTAssertEqual(recipe.steps.count, initialCount + 1)
        XCTAssertTrue(recipe.steps.contains { $0.instruction == "Serve hot" })
        XCTAssertEqual(recipe.steps.last?.order, initialCount + 1)
        XCTAssertTrue(recipe.dirty, "Recipe should be marked as dirty after adding step")
    }

    func testRemoveStep() throws {
        // Arrange
        let recipe = Fixtures.bolognese(owner: user)
        context.insert(recipe)
        recipe.markAsSynced()  // Reset dirty flag
        let initialCount = recipe.steps.count
        let stepToRemove = recipe.steps.first!

        // Act
        recipe.removeStep(stepToRemove)

        // Assert
        XCTAssertEqual(recipe.steps.count, initialCount - 1)
        XCTAssertFalse(recipe.steps.contains { $0.id == stepToRemove.id })
        XCTAssertTrue(recipe.dirty, "Recipe should be marked as dirty after removing step")
    }

    func testMoveStep() throws {
        // Arrange
        let recipe = Fixtures.bolognese(owner: user)
        context.insert(recipe)
        recipe.markAsSynced()  // Reset dirty flag

        // Get the initial order
        let initialSteps = recipe.sortedSteps
        let firstStep = initialSteps[0]

        // Act - move the first step to the end
        recipe.moveStep(from: IndexSet(integer: 0), to: recipe.steps.count)

        // Assert
        let newSteps = recipe.sortedSteps
        XCTAssertEqual(newSteps.last?.id, firstStep.id, "The first step should now be last")
        XCTAssertTrue(recipe.dirty, "Recipe should be marked as dirty after moving step")

        // Verify all orders are sequential and start from 1
        for (index, step) in newSteps.enumerated() {
            XCTAssertEqual(step.order, index + 1, "Step order should be sequential")
        }
    }

    // MARK: - Duration Calculation Tests

    func testDurationCalculations() throws {
        // Arrange
        let recipe = Recipe(
            title: "Duration Test",
            details: "Testing durations",
            owner: user
        )
        context.insert(recipe)

        // Add steps with different types and durations
        recipe.addStep(instruction: "Prepare ingredients", type: .preparation, duration: 600)  // 10 minutes
        recipe.addStep(instruction: "Mix ingredients", type: .preparation, duration: 300)  // 5 minutes
        recipe.addStep(instruction: "Cook on stove", type: .cooking, duration: 1200)  // 20 minutes
        recipe.addStep(instruction: "Bake in oven", type: .cooking, duration: 1800)  // 30 minutes
        recipe.addStep(instruction: "Let rest", type: .maturing, duration: 3600)  // 60 minutes

        // Act & Assert
        XCTAssertEqual(recipe.preparationDuration, 900, "Preparation duration should be 15 minutes")
        XCTAssertEqual(recipe.cookingDuration, 3000, "Cooking duration should be 50 minutes")
        XCTAssertEqual(recipe.maturingDuration, 3600, "Maturing duration should be 60 minutes")
        XCTAssertEqual(recipe.totalDuration, 7500, "Total duration should be 125 minutes")
    }

    func testDurationWithNilDurations() throws {
        // Arrange
        let recipe = Recipe(
            title: "Nil Duration Test",
            details: "Testing with nil durations",
            owner: user
        )
        context.insert(recipe)

        // Add steps with some nil durations
        recipe.addStep(instruction: "Prepare ingredients", type: .preparation, duration: 600)
        recipe.addStep(instruction: "Mix ingredients", type: .preparation, duration: nil)
        recipe.addStep(instruction: "Cook on stove", type: .cooking, duration: 1200)

        // Act & Assert
        XCTAssertEqual(
            recipe.preparationDuration, 600,
            "Preparation duration should only count non-nil durations")
        XCTAssertEqual(recipe.cookingDuration, 1200, "Cooking duration should be correct")
        XCTAssertEqual(
            recipe.totalDuration, 1800, "Total duration should sum all non-nil durations")
    }

    // MARK: - Syncable Behavior Tests

    func testSyncableBehavior() throws {
        // Arrange
        let recipe = Recipe(
            title: "Sync Test",
            details: "Testing syncing behavior",
            owner: user
        )
        context.insert(recipe)

        // Assert
        XCTAssertTrue(recipe.dirty, "New recipe should be marked as dirty")

        // Act
        recipe.markAsSynced()

        // Assert
        XCTAssertFalse(recipe.dirty, "Recipe should not be dirty after marked as synced")

        // Act - modify recipe
        recipe.setTitle("Updated Sync Test")

        // Assert
        XCTAssertTrue(recipe.dirty, "Recipe should be marked as dirty after modification")

        // Act
        recipe.markAsSynced()

        // Assert
        XCTAssertFalse(recipe.dirty, "Recipe should not be dirty after marked as synced again")
    }
}
