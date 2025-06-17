import Foundation
import OSLog
import SwiftData

class MealEntityProcessor: BaseEntityProcessor, EntityProcessor {
    var meals: MealService
    var users: UserService
    var todoItems: TodoItemService
    var recipes: RecipeService
    var shoppingItems: ShoppingListItemService

    init(
        modelContext: ModelContext,
        logger: Logger,
        meals: MealService,
        users: UserService,
        todoItems: TodoItemService,
        recipes: RecipeService,
        shoppingItems: ShoppingListItemService
    ) {
        self.meals = meals
        self.users = users
        self.todoItems = todoItems
        self.recipes = recipes
        self.shoppingItems = shoppingItems
        super.init(modelContext: modelContext, logger: logger)
    }

    @MainActor
    func process(entities: [[String: Any]], currentUser: User) async throws {
        self.logger.info("Processing \(entities.count) Meal entities")

        for data in entities {
            guard let uid = data["uid"] as? String else {
                self.logger.warning("Skipping Meal entity without UID")
                continue
            }

            // Check if entity exists or create a new one
            let meal: Meal
            if let existingMeal = try meals.fetchUnique(withUID: uid) {
                meal = existingMeal
                self.logger.debug("Found existing Meal with UID: \(uid)")
            } else {
                guard let scalingFactor = data["scalingFactor"] as? Double,
                    let mealTypeRaw = data["mealType"] as? String,
                    let mealType = MealType(rawValue: mealTypeRaw)
                else {
                    self.logger.warning("Skipping Meal without required properties: \(uid)")
                    continue
                }

                meal = Meal(
                    scalingFactor: scalingFactor,
                    todoItem: nil,  // Will be updated later based on references
                    recipe: nil,  // Will be updated later based on references
                    mealType: mealType,
                    owner: nil  // Will be updated later based on references
                )
                meal.uid = uid
                modelContext.insert(meal)
                self.logger.debug("Created new Meal with UID: \(uid), type: \(mealType.rawValue)")
            }

            // Update properties
            meal.update(from: data)
            self.logger.debug("Updated properties for Meal: \(uid)")

            // Update owner if available
            if let ownerId = data["ownerId"] as? String {
                if ownerId != meal.owner?.uid {
                    if let owner = try? users.fetchUnique(withUID: ownerId) {
                        meal.owner = owner
                        self.logger.debug("Set owner \(ownerId) for Meal: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find owner with UID \(ownerId) for Meal: \(uid)")
                    }
                }
            } else if meal.owner != nil {
                self.logger.debug("Removing owner from Meal: \(uid)")
                meal.owner = nil
            }

            // Process recipe reference if available
            if let recipeUID = data["recipeId"] as? String {
                if recipeUID != meal.recipe?.uid {
                    if let recipe = try? recipes.fetchUnique(withUID: recipeUID) {
                        meal.recipe = recipe
                        self.logger.debug("Set recipe \(recipeUID) for Meal: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find recipe with UID \(recipeUID) for Meal: \(uid)")
                    }
                }
            } else if meal.recipe != nil {
                self.logger.debug("Removing recipe from Meal: \(uid)")
                meal.recipe = nil
            }

            // Process todoItem reference if available
            if let todoItemUID = data["todoItemId"] as? String {
                if todoItemUID != meal.todoItem?.uid {
                    if let todoItem = try? todoItems.fetchUnique(withUID: todoItemUID) {
                        meal.todoItem = todoItem
                        self.logger.debug("Set todoItem \(todoItemUID) for Meal: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find todoItem with UID \(todoItemUID) for Meal: \(uid)")
                    }
                }
            } else if meal.todoItem != nil {
                self.logger.debug("Removing todoItem from Meal: \(uid)")
                meal.todoItem = nil
            }

            // Process shopping list items
            if let shoppingItemIds = data["shoppingListItemIds"] as? [String],
                !shoppingItemIds.isEmpty
            {
                self.logger.debug(
                    "Processing \(shoppingItemIds.count) shopping list items for Meal: \(uid)")

                let currentItemIds = Set(meal.shoppingListItems.compactMap { $0.uid })
                let newItemIds = Set(shoppingItemIds).subtracting(currentItemIds)

                if !newItemIds.isEmpty {
                    if let newItems = try? shoppingItems.fetchMany(
                        withUIDs: Array(newItemIds)
                    ) {
                        meal.shoppingListItems.append(contentsOf: newItems)
                        self.logger.debug(
                            "Added \(newItems.count) new shopping items to Meal: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find any of the \(newItemIds.count) new shopping items for Meal: \(uid)"
                        )
                    }
                }

                // Remove items that are no longer associated with this meal
                let initialCount = meal.shoppingListItems.count
                meal.shoppingListItems.removeAll { item in
                    return !shoppingItemIds.contains(item.uid)
                }
                let removedCount = initialCount - meal.shoppingListItems.count
                if removedCount > 0 {
                    self.logger.debug("Removed \(removedCount) shopping items from Meal: \(uid)")
                }
            } else if !meal.shoppingListItems.isEmpty {
                self.logger.debug(
                    "Clearing all \(meal.shoppingListItems.count) shopping items from Meal: \(uid)")
                meal.shoppingListItems.removeAll()
            }

            meal.markAsSynced()
            self.logger.debug("Successfully processed Meal: \(uid)")
        }
    }
}
