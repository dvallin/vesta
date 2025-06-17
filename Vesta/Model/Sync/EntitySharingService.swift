import Foundation
import SwiftData
import os

/// Service responsible for managing the sharing state of entities based on user's preferences.
/// Uses entity-specific services to retrieve entities and update their sharing status.
class EntitySharingService: ObservableObject {
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.app.Vesta", category: "EntitySharing")

    private let todoItemService: TodoItemService
    private let mealService: MealService
    private let recipeService: RecipeService
    private let shoppingItemService: ShoppingListItemService

    init(
        modelContext: ModelContext,
        todoItemService: TodoItemService,
        mealService: MealService,
        recipeService: RecipeService,
        shoppingItemService: ShoppingListItemService
    ) {
        self.modelContext = modelContext
        self.todoItemService = todoItemService
        self.mealService = mealService
        self.recipeService = recipeService
        self.shoppingItemService = shoppingItemService
    }

    /// Updates the isShared flag on all entities owned by the user based on their sharing preferences
    /// - Parameter user: The user whose entities should be updated
    /// - Returns: The number of entities that were updated
    @discardableResult
    func updateEntitySharingStatus(for user: User) -> Int {
        logger.info("Updating sharing status for entities owned by user: \(user.uid)")

        var updatedCount = 0

        // Get user's sharing preferences
        let shareMeals = user.shareMeals ?? false
        let shareShoppingItems = user.shareShoppingItems ?? false
        let todoCategoriesToShare = Set(user.shareTodoItemCategories.compactMap { $0.id })

        // Update meals
        updatedCount += updateMealSharing(ownerId: user.uid, isShared: shareMeals)

        // Update recipes
        updatedCount += updateRecipeSharing(ownerId: user.uid, isShared: shareMeals)

        // Update shopping list items
        updatedCount += updateShoppingItemSharing(ownerId: user.uid, isShared: shareShoppingItems)

        // Update todo items by category
        updatedCount += updateTodoItemSharing(
            ownerId: user.uid, categoriesToShare: todoCategoriesToShare, shareMeals: shareMeals,
            shareShoppingItems: shareShoppingItems)

        // Save changes
        do {
            try modelContext.save()
            logger.info("Successfully updated sharing status for \(updatedCount) entities")
        } catch {
            logger.error("Failed to save sharing status changes: \(error.localizedDescription)")
        }

        return updatedCount
    }

    // MARK: - Private Methods

    private func updateMealSharing(ownerId: String, isShared: Bool) -> Int {
        var updatedCount = 0

        do {
            // Fetch all meals owned by this user using the service
            let meals = try mealService.fetchByOwnerId(ownerId)
            logger.debug("Processing \(meals.count) meals for sharing")

            for meal in meals {
                if meal.isShared != isShared {
                    meal.isShared = isShared
                    meal.markAsDirty()
                    updatedCount += 1
                }
            }

            logger.debug("Updated \(updatedCount) meals")
            return updatedCount
        } catch {
            logger.error("Error fetching meals: \(error.localizedDescription)")
            return 0
        }
    }

    private func updateRecipeSharing(ownerId: String, isShared: Bool) -> Int {
        var updatedCount = 0

        do {
            // Fetch all recipes owned by this user using the service
            let recipes = try recipeService.fetchByOwnerId(ownerId)
            logger.debug("Processing \(recipes.count) recipes for sharing")

            for recipe in recipes {
                if recipe.isShared != isShared {
                    recipe.isShared = isShared
                    recipe.markAsDirty()
                    updatedCount += 1
                }
            }

            logger.debug("Updated \(updatedCount) recipes")
            return updatedCount
        } catch {
            logger.error("Error fetching recipes: \(error.localizedDescription)")
            return 0
        }
    }

    private func updateShoppingItemSharing(ownerId: String, isShared: Bool) -> Int {
        var updatedCount = 0

        do {
            // Fetch all shopping items owned by this user using the service
            let items = try shoppingItemService.fetchByOwnerId(ownerId)
            logger.debug("Processing \(items.count) shopping items for sharing")

            for item in items {
                if item.isShared != isShared {
                    item.isShared = isShared
                    item.markAsDirty()
                    updatedCount += 1
                }
            }

            logger.debug("Updated \(updatedCount) shopping items")
            return updatedCount
        } catch {
            logger.error("Error fetching shopping items: \(error.localizedDescription)")
            return 0
        }
    }

    private func updateTodoItemSharing(
        ownerId: String, categoriesToShare: Set<PersistentIdentifier>, shareMeals: Bool,
        shareShoppingItems: Bool
    ) -> Int {
        var updatedCount = 0

        do {
            // Fetch all todo items owned by this user using the service
            let items = try todoItemService.fetchByOwnerId(ownerId)
            logger.debug("Processing \(items.count) todo items for sharing")

            for item in items {
                let categoryShared =
                    item.category != nil && item.category?.id != nil
                    && categoriesToShare.contains(item.category!.id)
                let mealItemShared = item.meal != nil && shareMeals
                let shoppingItemShared = item.shoppingListItem != nil && shareShoppingItems
                let shouldBeShared = categoryShared || mealItemShared || shoppingItemShared

                if item.isShared != shouldBeShared {
                    item.isShared = shouldBeShared
                    item.markAsDirty()
                    updatedCount += 1
                }
            }

            logger.debug("Updated \(updatedCount) todo items")
            return updatedCount
        } catch {
            logger.error("Error fetching todo items: \(error.localizedDescription)")
            return 0
        }
    }
}
