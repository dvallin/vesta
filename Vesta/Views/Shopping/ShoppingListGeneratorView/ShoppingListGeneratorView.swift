import SwiftData
import SwiftUI

struct ShoppingListGeneratorView: View {
    @EnvironmentObject private var userService: UserManager
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
            .navigationTitle(
                NSLocalizedString(
                    "Generate Shopping List",
                    comment: "Navigation title for shopping list generator")
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("Generate", comment: "Generate button")) {
                        viewModel.generateShoppingList()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.configureContext(modelContext, userService)
            viewModel.prepareMealsForShoppingList(meals)
        }
    }
}

#Preview("Shopping List Generator") {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext

        // Create sample recipes with ingredients
        let user = Fixtures.createUser()
        let recipe1 = Fixtures.bolognese(owner: user)
        let recipe2 = Fixtures.curry(owner: user)

        // Create todo items for meals
        let todoItem1 = TodoItem(
            title: "Make Carbonara", details: "Dinner", dueDate: Date().addingTimeInterval(86400),
            owner: user)
        let todoItem2 = TodoItem(
            title: "Make Stir Fry", details: "Lunch", dueDate: Date().addingTimeInterval(172800),
            owner: user)

        // Create meals
        let meals = [
            Meal(
                scalingFactor: 1.0, todoItem: todoItem1, recipe: recipe1, mealType: .dinner,
                owner: user),
            Meal(
                scalingFactor: 1.5, todoItem: todoItem2, recipe: recipe2, mealType: .lunch,
                owner: user),
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
            let recipe = Recipe(
                title: "Recipe \(i)", details: "Details for recipe \(i)",
                owner: Fixtures.createUser())
            recipe.ingredients = (1...4).map { j in
                Ingredient(
                    name: "Ingredient \(j) for Recipe \(i)",
                    order: j,
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
                dueDate: Date().addingTimeInterval(Double(86400 * (index + 1))),
                owner: Fixtures.createUser()
            )
            return Meal(
                scalingFactor: Double(index + 1) * 0.5,
                todoItem: todoItem,
                recipe: recipe,
                mealType: [.breakfast, .lunch, .dinner][index % 3],
                owner: Fixtures.createUser()
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
