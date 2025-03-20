import SwiftData
import SwiftUI

struct MealDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: MealDetailViewModel

    init(meal: Meal) {
        _viewModel = StateObject(wrappedValue: MealDetailViewModel(meal: meal))
    }

    var body: some View {
        VStack {
            if let recipe = viewModel.meal.recipe {
                ReadOnlyRecipeDetailView(
                    recipe: recipe, scalingFactor: viewModel.meal.scalingFactor
                )
            }
            HStack {
                Text(NSLocalizedString("Scaling Factor:", comment: "Scaling factor label"))
                TextField(
                    NSLocalizedString("Scaling Factor", comment: "Scaling factor input field"),
                    value: $viewModel.meal.scalingFactor,
                    formatter: NumberFormatter()
                )
                #if os(iOS)
                    .keyboardType(.decimalPad)
                #endif
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()

            HStack {
                Text(NSLocalizedString("Meal Type:", comment: "Meal type label"))
                Picker(
                    NSLocalizedString("Meal Type", comment: "Meal type picker label"),
                    selection: $viewModel.meal.mealType
                ) {
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        Text(mealType.displayName).tag(mealType)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: viewModel.meal.mealType) { newMealType, _ in
                    viewModel.updateTodoItemDueDate(for: newMealType)
                }
            }
            .padding(.horizontal)

            HStack {
                Text(NSLocalizedString("Due Date:", comment: "Due date label"))
                DatePicker(
                    "",
                    selection: Binding(
                        get: { viewModel.meal.todoItem?.dueDate ?? Date() },
                        set: { newValue in
                            viewModel.meal.updateDueDate(newValue)
                        }
                    ),
                    displayedComponents: .date
                )
            }
            .padding()
        }
        .navigationTitle(NSLocalizedString("Meal Details", comment: "Meal details screen title"))
        .toolbar {
            #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Save", comment: "Save button")) {
                        viewModel.save()
                    }
                }
            #endif
        }
        .onAppear {
            viewModel.configureEnvironment(modelContext)
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
            Ingredient(name: "Spaghetti", order: 1, quantity: 500, unit: .gram, recipe: recipe),
            Ingredient(name: "Ground Beef", order: 2, quantity: 400, unit: .gram, recipe: recipe),
            Ingredient(name: "Tomato Sauce", order: 3, quantity: 2, unit: .cup, recipe: recipe),
            Ingredient(name: "Onion", order: 4, quantity: 1, unit: .piece, recipe: recipe),
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
