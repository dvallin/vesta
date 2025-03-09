import SwiftData
import SwiftUI

struct MealPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var meals: [Meal]

    @StateObject var viewModel = MealPlanViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                List {
                    if let nextMeal = viewModel.nextUpcomingMeal(meals: meals) {
                        NextMealView(meal: nextMeal) {
                            viewModel.selectedMeal = nextMeal
                        }
                    }

                    ForEach(viewModel.dayGroups(for: meals)) { group in
                        DayGroupSectionView(
                            group: group,
                            onMealSelect: { meal in
                                viewModel.selectedMeal = meal
                            },
                            onDelete: { indexSet in
                                viewModel.deleteMeal(meals: meals, at: indexSet, for: group.date)
                            },
                            onMarkAsDone: { todoItem in
                                viewModel.markAsDone(todoItem)
                            }
                        )
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Meal Plan")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.isPresentingRecipeListView = true
                        }) {
                            Label("Recipes", systemImage: "book")
                        }
                    }
                }

                FloatingAddButton {
                    viewModel.isPresentingAddMealView = true
                }
            }
            .sheet(item: $viewModel.selectedMeal) { meal in
                MealDetailView(meal: meal)
            }
            .sheet(isPresented: $viewModel.isPresentingAddMealView) {
                AddMealView(selectedDate: Date())
            }
            .sheet(isPresented: $viewModel.isPresentingRecipeListView) {
                RecipeListView()
            }
            .onAppear {
                viewModel.configureContext(modelContext)
            }
        }
    }
}

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext

        let recipes = [
            Recipe(
                title: "Spaghetti Bolognese",
                details: "Classic Italian pasta dish",
                ingredients: [
                    Ingredient(name: "Ground beef", quantity: 500, unit: .gram),
                    Ingredient(name: "Spaghetti", quantity: 400, unit: .gram),
                    Ingredient(name: "Tomato sauce", quantity: 2, unit: .cup),
                ]
            ),
            Recipe(
                title: "Chicken Curry",
                details: "Spicy Indian curry",
                ingredients: [
                    Ingredient(name: "Chicken", quantity: 1, unit: .kilogram),
                    Ingredient(name: "Curry powder", quantity: 2, unit: .tablespoon),
                    Ingredient(name: "Coconut milk", quantity: 400, unit: .milliliter),
                ]
            ),
        ]

        // Insert recipes
        for recipe in recipes {
            context.insert(recipe)
        }

        // Create todo items with different dates
        let calendar = Calendar.current
        let today = Date()

        let todoItems = [
            TodoItem(
                title: "Cook Spaghetti",
                details: "Dinner",
                dueDate: calendar.date(byAdding: .day, value: 1, to: today)
            ),
            TodoItem(
                title: "Make Curry",
                details: "Lunch",
                dueDate: calendar.date(byAdding: .day, value: 2, to: today)
            ),
            TodoItem(
                title: "Weekend Pasta",
                details: "Family dinner",
                dueDate: calendar.date(byAdding: .day, value: 5, to: today)
            ),
        ]

        for todoItem in todoItems {
            context.insert(todoItem)
        }

        let meals = [
            Meal(scalingFactor: 1.0, todoItem: todoItems[0], recipe: recipes[0]),
            Meal(scalingFactor: 2.0, todoItem: todoItems[1], recipe: recipes[1]),
            Meal(scalingFactor: 1.5, todoItem: todoItems[2], recipe: recipes[0]),
        ]

        for meal in meals {
            context.insert(meal)
        }

        return MealPlanView()
            .modelContainer(container)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
