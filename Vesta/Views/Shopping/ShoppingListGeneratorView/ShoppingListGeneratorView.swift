import SwiftData
import SwiftUI

struct ShoppingListGeneratorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = ShoppingListGeneratorViewModel()
    let meals: [Meal]

    var body: some View {
        NavigationView {
            List {
                ForEach($viewModel.ingredientSelections) { $selection in
                    IngredientSelectionRow(selection: $selection)
                }
            }
            .navigationTitle("Generate Shopping List")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        viewModel.generateShoppingList(modelContext: modelContext)
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.prepareMealsForShoppingList(meals)
        }
    }
}

#Preview("Shopping List Generator") {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext

        // Create sample recipes with ingredients
        let recipe1 = Recipe(title: "Spaghetti Carbonara", details: "Classic Italian pasta dish")
        let recipe2 = Recipe(title: "Chicken Stir Fry", details: "Quick and easy stir fry")

        // Add ingredients to recipes
        let ingredients1 = [
            Ingredient(name: "Spaghetti", quantity: 500, unit: .gram, recipe: recipe1),
            Ingredient(name: "Eggs", quantity: 4, unit: .piece, recipe: recipe1),
            Ingredient(name: "Parmesan", quantity: 100, unit: .gram, recipe: recipe1),
        ]
        recipe1.ingredients = ingredients1

        let ingredients2 = [
            Ingredient(name: "Chicken", quantity: 500, unit: .gram, recipe: recipe2),
            Ingredient(name: "Bell Peppers", quantity: 2, unit: .piece, recipe: recipe2),
            Ingredient(name: "Soy Sauce", quantity: 30, unit: .milliliter, recipe: recipe2),
        ]
        recipe2.ingredients = ingredients2

        // Create todo items for meals
        let todoItem1 = TodoItem(
            title: "Make Carbonara", details: "Dinner", dueDate: Date().addingTimeInterval(86400))
        let todoItem2 = TodoItem(
            title: "Make Stir Fry", details: "Lunch", dueDate: Date().addingTimeInterval(172800))

        // Create meals
        let meals = [
            Meal(scalingFactor: 1.0, todoItem: todoItem1, recipe: recipe1, mealType: .dinner),
            Meal(scalingFactor: 1.5, todoItem: todoItem2, recipe: recipe2, mealType: .lunch),
        ]

        // Insert everything into context
        for meal in meals {
            context.insert(meal)
        }

        return ShoppingListGeneratorView(meals: meals)
            .modelContainer(container)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}

#Preview("Empty") {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        return ShoppingListGeneratorView(meals: [])
            .modelContainer(container)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}

#Preview("Large Dataset") {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext

        // Create multiple recipes with ingredients
        let recipes = (1...5).map { i in
            let recipe = Recipe(title: "Recipe \(i)", details: "Details for recipe \(i)")
            recipe.ingredients = (1...4).map { j in
                Ingredient(
                    name: "Ingredient \(j) for Recipe \(i)",
                    quantity: Double(j * 100),
                    unit: Unit.allCases[j % Unit.allCases.count],
                    recipe: recipe
                )
            }
            return recipe
        }

        // Create meals for each recipe
        let meals = recipes.enumerated().map { index, recipe in
            let todoItem = TodoItem(
                title: "Cook \(recipe.title)",
                details: "Meal \(index + 1)",
                dueDate: Date().addingTimeInterval(Double(86400 * (index + 1)))
            )
            return Meal(
                scalingFactor: Double(index + 1) * 0.5,
                todoItem: todoItem,
                recipe: recipe,
                mealType: [.breakfast, .lunch, .dinner][index % 3]
            )
        }

        // Insert everything into context
        for meal in meals {
            context.insert(meal)
        }

        return ShoppingListGeneratorView(meals: meals)
            .modelContainer(container)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
