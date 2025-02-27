import SwiftData
import SwiftUI

struct AddMealView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var recipes: [Recipe]

    @State private var selectedRecipe: Recipe?
    @State private var selectedDate: Date
    @State private var scalingFactor: Double = 1.0

    init(selectedDate: Date) {
        _selectedDate = State(initialValue: selectedDate)
    }

    var body: some View {
        NavigationView {
            Form {
                DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                Picker("Recipe", selection: $selectedRecipe) {
                    ForEach(recipes) { recipe in
                        Text(recipe.title).tag(recipe as Recipe?)
                    }
                }
                TextField("Scaling Factor", value: $scalingFactor, formatter: NumberFormatter())
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Add Meal")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        do {
                            if let recipe = selectedRecipe {
                                let todoItem = TodoItem(
                                    title: recipe.title, details: recipe.details,
                                    dueDate: selectedDate)
                                let meal = Meal(
                                    scalingFactor: scalingFactor, todoItem: todoItem, recipe: recipe
                                )
                                modelContext.insert(todoItem)
                                modelContext.insert(meal)
                                try modelContext.save()
                                dismiss()
                            }
                        } catch {
                            // show validation issue
                        }
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

        // Create sample recipes with ingredients
        let spaghettiRecipe = Recipe(
            title: "Spaghetti Bolognese",
            details: "Classic Italian pasta dish",
            ingredients: [
                Ingredient(name: "Spaghetti", quantity: 500, unit: .gram),
                Ingredient(name: "Ground Beef", quantity: 400, unit: .gram),
                Ingredient(name: "Tomato Sauce", quantity: 2, unit: .cup),
            ]
        )

        let curryRecipe = Recipe(
            title: "Chicken Curry",
            details: "Spicy Indian curry",
            ingredients: [
                Ingredient(name: "Chicken", quantity: 1, unit: .kilogram),
                Ingredient(name: "Curry Powder", quantity: 2, unit: .tablespoon),
                Ingredient(name: "Coconut Milk", quantity: 400, unit: .milliliter),
            ]
        )

        // Insert recipes into the context
        for recipe in [spaghettiRecipe, curryRecipe] {
            context.insert(recipe)
        }

        return AddMealView(selectedDate: Date())
            .modelContainer(container)

    } catch {
        return Text("Failed to create ModelContainer")
    }
}
