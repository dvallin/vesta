import SwiftData
import SwiftUI

struct MigrationManager {

    static func validateModel(in context: ModelContext, currentUser: User) {
        validateRelationshipIntegrity(in: context)
    }

    static func validateRelationshipIntegrity(in context: ModelContext) {
        print("🔍 Starting relationship integrity validation...")

        validateTodoItemRelationships(in: context)
        validateMealRelationships(in: context)
        validateShoppingListItemRelationships(in: context)
        validateRecipeRelationships(in: context)

        print("✅ Relationship integrity validation completed")
    }

    static func validateTodoItemRelationships(in context: ModelContext) {
        let todoDescriptor = FetchDescriptor<TodoItem>()
        do {
            let todoItems = try context.fetch(todoDescriptor)

            for todoItem in todoItems {
                if let meal = todoItem.meal {
                    if meal.todoItem != todoItem {
                        print("⚠️ Meal \(meal.uid) has incorrect todoItem back-reference")
                    }
                }
                if let shoppingListItem = todoItem.shoppingListItem {
                    if shoppingListItem.todoItem != todoItem {
                        print(
                            "⚠️ ShoppingListItem \(shoppingListItem.uid) has incorrect todoItem back-reference"
                        )
                    }
                }
            }

        } catch {
            print("Error validating TodoItem relationships: \(error)")
        }
    }

    static func validateMealRelationships(in context: ModelContext) {
        let mealDescriptor = FetchDescriptor<Meal>()
        do {
            let meals = try context.fetch(mealDescriptor)

            for meal in meals {
                if let todoItem = meal.todoItem {
                    if todoItem.meal != meal {
                        print(
                            "⚠️ TodoItem \(todoItem.uid) has incorrect meal back-reference")
                    }
                }
                if let recipe = meal.recipe {
                    if !recipe.meals.contains(where: { $0 === meal }) {
                        print(
                            "⚠️ Recipe \(recipe.uid) doesn't contain meal \(meal.uid) in its meals array"
                        )
                    }
                }
                for shoppingListItem in meal.shoppingListItems {
                    if !shoppingListItem.meals.contains(where: { $0 === meal }) {
                        print(
                            "⚠️ ShoppingListItem \(shoppingListItem.uid) doesn't contain meal \(meal.uid)"
                        )
                    }
                }
            }

        } catch {
            print("Error validating Meal relationships: \(error)")
        }
    }

    static func validateShoppingListItemRelationships(in context: ModelContext) {
        let shoppingDescriptor = FetchDescriptor<ShoppingListItem>()
        do {
            let shoppingListItems = try context.fetch(shoppingDescriptor)

            for shoppingListItem in shoppingListItems {
                if let todoItem = shoppingListItem.todoItem {
                    if todoItem.shoppingListItem != shoppingListItem {
                        print(
                            "⚠️ TodoItem \(todoItem.uid) has incorrect shoppingListItem back-reference"
                        )
                    }
                }

                for meal in shoppingListItem.meals {
                    if !meal.shoppingListItems.contains(where: { $0 === shoppingListItem }) {
                        print(
                            "⚠️ Meal \(meal.uid) doesn't contain shoppingListItem \(shoppingListItem.uid)"
                        )
                    }
                }
            }

        } catch {
            print("Error validating ShoppingListItem relationships: \(error)")
        }
    }

    static func validateRecipeRelationships(in context: ModelContext) {
        let recipeDescriptor = FetchDescriptor<Recipe>()
        do {
            let recipes = try context.fetch(recipeDescriptor)

            for recipe in recipes {
                for meal in recipe.meals {
                    if meal.recipe != recipe {
                        print("⚠️ Meal \(meal.uid) has incorrect recipe back-reference")
                    }
                }
                for ingredient in recipe.ingredients {
                    if ingredient.recipe != recipe {
                        print(
                            "⚠️ Ingredient \(ingredient.name) has incorrect recipe back-reference"
                        )
                    }
                }
                for step in recipe.steps {
                    if step.recipe != recipe {
                        print(
                            "⚠️ RecipeStep \(step.instruction) has incorrect recipe back-reference"
                        )
                    }
                }
            }
        } catch {
            print("Error validating Recipe relationships: \(error)")
        }
    }
}
