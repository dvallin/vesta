import Foundation
import OSLog
import SwiftData

class RecipeEntityProcessor: BaseEntityProcessor, EntityProcessor {
    var recipes: RecipeService
    var users: UserService
    var meals: MealService

    init(
        modelContext: ModelContext,
        logger: Logger,
        recipes: RecipeService,
        users: UserService,
        meals: MealService
    ) {
        self.recipes = recipes
        self.users = users
        self.meals = meals
        super.init(modelContext: modelContext, logger: logger)
    }

    @MainActor
    func process(entities: [[String: Any]], currentUser: User) async throws {
        self.logger.info("Processing \(entities.count) Recipe entities")

        for data in entities {
            guard let uid = data["uid"] as? String else {
                self.logger.warning("Skipping Recipe entity without UID")
                continue
            }

            // Check if entity exists or create a new one
            let recipe: Recipe
            if let existingRecipe = try recipes.fetchUnique(withUID: uid) {
                recipe = existingRecipe
                self.logger.debug("Found existing Recipe with UID: \(uid)")
            } else {
                guard let title = data["title"] as? String,
                    let details = data["details"] as? String
                else {
                    self.logger.warning("Skipping Recipe without required title or details: \(uid)")
                    continue
                }

                recipe = Recipe(
                    title: title,
                    details: details,
                    owner: nil  // Will be updated based on references
                )
                recipe.uid = uid
                recipe.dirty = false  // Fresh from server
                modelContext.insert(recipe)
                self.logger.debug("Created new Recipe with UID: \(uid), title: \(title)")
            }

            // Update properties using the Recipe's update method
            recipe.update(from: data)
            self.logger.debug("Updated properties for Recipe: \(uid)")

            // Update owner if available
            if let ownerId = data["ownerId"] as? String {
                if ownerId != recipe.owner?.uid {
                    if let owner = try? users.fetchUnique(withUID: ownerId) {
                        recipe.owner = owner
                        self.logger.debug("Set owner \(ownerId) for Recipe: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find owner with UID \(ownerId) for Recipe: \(uid)")
                    }
                }
            } else if recipe.owner != nil {
                self.logger.debug("Removing owner from Recipe: \(uid)")
                recipe.owner = nil
            }

            // Process meal references
            if let mealIds = data["mealIds"] as? [String], !mealIds.isEmpty {
                self.logger.debug("Processing \(mealIds.count) meal references for Recipe: \(uid)")

                let currentMealIds = Set(recipe.meals.compactMap { $0.uid })
                let newMealIds = Set(mealIds).subtracting(currentMealIds)

                if !newMealIds.isEmpty {
                    if let newMeals = try? meals.fetchMany(withUIDs: Array(newMealIds)) {
                        recipe.meals.append(contentsOf: newMeals)
                        self.logger.debug("Added \(newMeals.count) new meals to Recipe: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find any of the \(newMealIds.count) new meals for Recipe: \(uid)"
                        )
                    }
                }

                // Remove meals that are no longer associated with this recipe
                let initialCount = recipe.meals.count
                recipe.meals.removeAll { meal in
                    guard let mealUid = meal.uid else { return false }
                    return !mealIds.contains(mealUid)
                }
                let removedCount = initialCount - recipe.meals.count
                if removedCount > 0 {
                    self.logger.debug("Removed \(removedCount) meals from Recipe: \(uid)")
                }
            } else if !recipe.meals.isEmpty {
                self.logger.debug("Clearing all \(recipe.meals.count) meals from Recipe: \(uid)")
                recipe.meals.removeAll()
            }

            recipe.markAsSynced()
            self.logger.debug("Successfully processed Recipe: \(uid)")
        }
    }
}
