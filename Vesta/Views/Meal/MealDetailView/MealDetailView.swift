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
            ReadOnlyRecipeDetailView(
                recipe: viewModel.meal.recipe, scalingFactor: viewModel.meal.scalingFactor
            )
            HStack {
                Text("Scaling Factor:")
                TextField(
                    "Scaling Factor", value: $viewModel.meal.scalingFactor,
                    formatter: NumberFormatter()
                )
                #if os(iOS)
                    .keyboardType(.decimalPad)
                #endif
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()

            HStack {
                Text("Meal Type:")
                Picker("Meal Type", selection: $viewModel.meal.mealType) {
                    Text("Breakfast").tag(MealType.breakfast)
                    Text("Lunch").tag(MealType.lunch)
                    Text("Dinner").tag(MealType.dinner)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: viewModel.meal.mealType) { newMealType, _ in
                    viewModel.updateTodoItemDueDate(for: newMealType)
                }
            }
        }
        .navigationTitle("Meal Details")
        .toolbar {
            #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
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
