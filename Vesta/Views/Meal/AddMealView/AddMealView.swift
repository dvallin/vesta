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
                DatePicker(
                    NSLocalizedString("Date", comment: "Date picker label"),
                    selection: $viewModel.selectedDate, displayedComponents: .date)
                Picker(
                    NSLocalizedString("Recipe", comment: "Recipe picker label"),
                    selection: $viewModel.selectedRecipe
                ) {
                    ForEach(recipes) { recipe in
                        Text(recipe.title).tag(recipe as Recipe?)
                    }
                }
                TextField(
                    NSLocalizedString("Scaling Factor", comment: "Scaling factor input field"),
                    value: $viewModel.scalingFactor, formatter: NumberFormatter()
                )
                #if os(iOS)
                    .keyboardType(.decimalPad)
                #endif

                Picker(
                    NSLocalizedString("Meal Type", comment: "Meal type picker label"),
                    selection: $viewModel.selectedMealType
                ) {
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        Text(mealType.displayName).tag(mealType)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .navigationTitle(NSLocalizedString("Add Meal", comment: "Add meal screen title"))
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                            Task {
                                viewModel.cancel()
                            }
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(NSLocalizedString("Save", comment: "Save button")) {
                            Task {
                                viewModel.save()
                            }
                        }
                    }
                #endif
            }
            .alert(
                NSLocalizedString("Validation Error", comment: "Validation error alert title"),
                isPresented: $viewModel.showingValidationAlert
            ) {
                Button(
                    NSLocalizedString("OK", comment: "Validation error accept button"),
                    role: .cancel
                ) {}
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
