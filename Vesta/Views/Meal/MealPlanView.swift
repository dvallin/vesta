import SwiftData
import SwiftUI

struct MealPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var meals: [Meal]

    @State private var selectedMeal: Meal?
    @State private var isPresentingAddMealView = false
    @State private var isPresentingRecipeListView = false

    var body: some View {
        NavigationView {
            ZStack {
                List {
                    if let nextMeal = nextUpcomingMeal {
                        Section(header: Text("Next Meal")) {
                            Button(action: {
                                selectedMeal = nextMeal
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

                    ForEach(weeks, id: \.self) { week in
                        weekSection(for: week)
                    }
                }

                FloatingAddButton {
                    isPresentingAddMealView = true
                }
            }
        }
        .sheet(item: $selectedMeal) { meal in
            MealDetailView(meal: meal)
        }
        .sheet(isPresented: $isPresentingAddMealView) {
            AddMealView(selectedDate: Date())
        }
        .sheet(isPresented: $isPresentingRecipeListView) {
            RecipeListView()
        }
        .navigationTitle("Meal Plan")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isPresentingRecipeListView = true
                }) {
                    Label("Recipes", systemImage: "book")
                }
            }
        }
    }
}

// MARK: - Smaller “Sub-Views” or Helper Functions

extension MealPlanView {
    @ViewBuilder
    private func weekSection(for week: [Date]) -> some View {
        if let firstDate = week.first {
            Section(header: Text("Week \(weekNumber(for: firstDate))")) {
                ForEach(week, id: \.self) { date in
                    daySection(for: date)
                }
            }
        }
    }

    @ViewBuilder
    private func daySection(for date: Date) -> some View {
        Section(header: Text(date, style: .date)) {
            ForEach(mealsForDate(date)) { meal in
                Button(action: {
                    selectedMeal = meal
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
                deleteMeal(at: indexSet, for: date)
            }
        }
    }
}

// MARK: - Supporting Methods and Computed Properties

extension MealPlanView {
    private var weeks: [[Date]] {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        )!
        let dates = (0..<14).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startOfWeek)
        }
        return stride(from: 0, to: dates.count, by: 7).map {
            Array(dates[$0..<min($0 + 7, dates.count)])
        }
    }

    private func weekNumber(for date: Date) -> Int {
        Calendar.current.component(.weekOfYear, from: date)
    }

    private func mealsForDate(_ date: Date) -> [Meal] {
        let calendar = Calendar.current
        return meals.filter { meal in
            guard let dueDate = meal.todoItem.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }
    }

    private var nextUpcomingMeal: Meal? {
        let now = Date()
        return
            meals
            .filter { meal in
                guard let dueDate = meal.todoItem.dueDate else { return false }
                return dueDate > now
            }
            .min { a, b in
                guard let dateA = a.todoItem.dueDate,
                    let dateB = b.todoItem.dueDate
                else { return false }
                return dateA < dateB
            }
    }

    private func deleteMeal(at offsets: IndexSet, for date: Date) {
        withAnimation {
            let mealsForDate = mealsForDate(date)
            offsets.map { mealsForDate[$0] }.forEach { meal in
                modelContext.delete(meal)
            }
        }
    }

    private func isDateInPast(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.compare(date, to: Date(), toGranularity: .day) == .orderedAscending
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
