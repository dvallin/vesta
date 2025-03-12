import SwiftData
import SwiftUI

class ShoppingListGeneratorViewModel: ObservableObject {
    struct IngredientSelection: Identifiable {
        let id = UUID()
        let ingredient: Ingredient
        let meals: [Meal]
        var isSelected: Bool
        var quantity: Double
        var earliestDueDate: Date
        var unit: Unit?
    }

    @Published var ingredientSelections: [IngredientSelection] = []

    func prepareMealsForShoppingList(_ meals: [Meal]) {
        let eligibleMeals = meals.filter { meal in
            guard let dueDate = meal.todoItem.dueDate else { return false }
            return dueDate > Date() && !meal.todoItem.isCompleted && meal.shoppingListItems.isEmpty
        }

        let groupedIngredients = Dictionary(
            grouping: eligibleMeals.flatMap { meal in
                meal.recipe.ingredients.map { ($0, meal) }
            }
        ) { $0.0.name }

        ingredientSelections = groupedIngredients.map { name, ingredientMealPairs in
            let firstIngredient = ingredientMealPairs[0].0
            let totalQuantity = ingredientMealPairs.reduce(0.0) { sum, pair in
                sum + (pair.0.quantity ?? 0) * pair.1.scalingFactor
            }
            let earliestDueDate =
                ingredientMealPairs.compactMap { $0.1.todoItem.dueDate }.min() ?? Date()

            return IngredientSelection(
                ingredient: firstIngredient,
                meals: ingredientMealPairs.map { $0.1 },
                isSelected: true,
                quantity: totalQuantity,
                earliestDueDate: earliestDueDate,
                unit: firstIngredient.unit
            )
        }.sorted { l, r in l.earliestDueDate < r.earliestDueDate }
    }

    func generateShoppingList(modelContext: ModelContext) {
        for selection in ingredientSelections where selection.isSelected {
            let todoItem = TodoItem(
                title: "buy \(selection.ingredient.name)",
                details: "Buy for: "
                    + selection.meals.map { $0.recipe.title }.joined(separator: ", "),
                dueDate: selection.earliestDueDate
            )
            modelContext.insert(todoItem)

            let shoppingListItem = ShoppingListItem(
                name: selection.ingredient.name,
                quantity: selection.quantity,
                unit: selection.unit,
                todoItem: todoItem,
                meals: selection.meals
            )
            modelContext.insert(shoppingListItem)
        }
    }
}
