import SwiftData
import SwiftUI

struct MealPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var meals: [Meal]

    @State private var selectedMeal: Meal?
    @State private var isPresentingAddMealView = false
    @State private var selectedDateForNewMeal: Date?
    @State private var isPresentingRecipeListView = false

    var body: some View {
        NavigationView {
            List {
                ForEach(weeks, id: \.self) { week in
                    weekSection(for: week)
                }
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
        .sheet(item: $selectedMeal) { meal in
            MealDetailView(meal: meal)
        }
        .sheet(isPresented: $isPresentingAddMealView) {
            AddMealView(selectedDate: selectedDateForNewMeal ?? Date())
        }
        .sheet(isPresented: $isPresentingRecipeListView) {
            RecipeListView()
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

            if !isDateInPast(date) {
                Button {
                    selectedDateForNewMeal = date
                    isPresentingAddMealView = true
                } label: {
                    Label("Add Meal", systemImage: "plus.circle.fill")
                }
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
