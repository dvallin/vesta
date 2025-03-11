import SwiftData
import SwiftUI

struct AddMealView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var recipes: [Recipe]

    @StateObject var viewModel: AddMealViewModel

    init(selectedDate: Date) {
        _viewModel = StateObject(wrappedValue: AddMealViewModel(selectedDate: selectedDate))
    }

    var body: some View {
        NavigationView {
            Form {
                DatePicker("Date", selection: $viewModel.selectedDate, displayedComponents: .date)
                Picker("Recipe", selection: $viewModel.selectedRecipe) {
                    ForEach(recipes) { recipe in
                        Text(recipe.title).tag(recipe as Recipe?)
                    }
                }
                TextField(
                    "Scaling Factor", value: $viewModel.scalingFactor, formatter: NumberFormatter()
                )
                #if os(iOS)
                    .keyboardType(.decimalPad)
                #endif

                Picker("Meal Type", selection: $viewModel.selectedMealType) {
                    Text("Breakfast").tag(MealType.breakfast)
                    Text("Lunch").tag(MealType.lunch)
                    Text("Dinner").tag(MealType.dinner)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .navigationTitle("Add Meal")
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            Task {
                                viewModel.cancel()
                            }
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            Task {
                                viewModel.save()
                            }
                        }
                    }
                #endif
            }
            .alert("Validation Error", isPresented: $viewModel.showingValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.validationMessage)
            }
        }
        .onAppear {
            viewModel.configureEnvironment(modelContext, dismiss)
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
