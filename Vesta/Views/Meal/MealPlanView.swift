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
                    if let nextMeal = viewModel.nextUpcomingMeal {
                        Section(header: Text("Next Meal")) {
                            Button(action: {
                                viewModel.selectedMeal = nextMeal
                            }) {
                                VStack(alignment: .leading) {
                                    Text(nextMeal.recipe.title)
                                        .font(.headline)
                                    if let dueDate = nextMeal.todoItem.dueDate {
                                        Text(dueDate, style: .date)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Text(
                                        "Scaling Factor: \(nextMeal.scalingFactor, specifier: "%.2f")"
                                    )
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                }
                            }
                            .listRowBackground(Color.accentColor.opacity(0.2))
                        }
                    }

                    ForEach(viewModel.weeks, id: \.self) { week in
                        weekSection(for: week)
                    }
                }

                FloatingAddButton {
                    viewModel.isPresentingAddMealView = true
                }
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
        .navigationTitle("Meal Plan")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.isPresentingRecipeListView = true
                }) {
                    Label("Recipes", systemImage: "book")
                }
            }
        }
        .onAppear {
            viewModel.configureContext(modelContext)
            viewModel.meals = meals
        }
    }
}

// MARK: - Smaller “Sub-Views” or Helper Functions

extension MealPlanView {
    @ViewBuilder
    private func weekSection(for week: [Date]) -> some View {
        if let firstDate = week.first {
            Section(header: Text("Week \(viewModel.weekNumber(for: firstDate))")) {
                ForEach(week, id: \.self) { date in
                    daySection(for: date)
                }
            }
        }
    }

    @ViewBuilder
    private func daySection(for date: Date) -> some View {
        Section(header: Text(date, style: .date)) {
            ForEach(viewModel.mealsForDate(date)) { meal in
                Button(action: {
                    viewModel.selectedMeal = meal
                }) {
                    VStack(alignment: .leading) {
                        Text(meal.recipe.title)
                            .font(.headline)
                        Text("Scaling Factor: \(meal.scalingFactor, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete { indexSet in
                viewModel.deleteMeal(at: indexSet, for: date)
            }
        }
    }
}

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext

        // Create sample recipes
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

        // Insert todo items
        for todoItem in todoItems {
            context.insert(todoItem)
        }

        // Create meals linking recipes and todo items
        let meals = [
            Meal(scalingFactor: 1.0, todoItem: todoItems[0], recipe: recipes[0]),
            Meal(scalingFactor: 2.0, todoItem: todoItems[1], recipe: recipes[1]),
            Meal(scalingFactor: 1.5, todoItem: todoItems[2], recipe: recipes[0]),
        ]

        // Insert meals
        for meal in meals {
            context.insert(meal)
        }

        return MealPlanView()
            .modelContainer(container)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
