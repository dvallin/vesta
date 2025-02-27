import SwiftData
import SwiftUI

struct MealDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var meal: Meal

    var body: some View {
        VStack {
            RecipeDetailView(recipe: meal.recipe)
            HStack {
                Text("Scaling Factor:")
                TextField(
                    "Scaling Factor", value: $meal.scalingFactor, formatter: NumberFormatter()
                )
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()
        }
        .navigationTitle("Meal Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    do {
                        try modelContext.save()
                    } catch {
                        // show validation issue
                    }
                }
            }
        }
    }
}

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext

        // Create sample recipe with ingredients
        let recipe = Recipe(
            title: "Spaghetti Bolognese",
            details: "Classic Italian pasta dish with meat sauce"
        )
        let ingredients = [
            Ingredient(name: "Spaghetti", quantity: 500, unit: .gram, recipe: recipe),
            Ingredient(name: "Ground Beef", quantity: 400, unit: .gram, recipe: recipe),
            Ingredient(name: "Tomato Sauce", quantity: 2, unit: .cup, recipe: recipe),
            Ingredient(name: "Onion", quantity: 1, unit: .piece, recipe: recipe),
        ]
        recipe.ingredients = ingredients

        // Create todo item
        let todoItem = TodoItem(
            title: "Cook Spaghetti Bolognese",
            details: "Make dinner",
            dueDate: Date().addingTimeInterval(3600)
        )

        // Create meal
        let meal = Meal(
            scalingFactor: 1.0,
            todoItem: todoItem,
            recipe: recipe
        )

        // Insert objects into context
        context.insert(recipe)
        context.insert(todoItem)
        context.insert(meal)

        return NavigationView {
            MealDetailView(meal: meal)
        }
        .modelContainer(container)

    } catch {
        return Text("Failed to create ModelContainer")
    }
}
