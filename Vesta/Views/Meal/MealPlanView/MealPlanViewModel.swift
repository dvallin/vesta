import SwiftData
import SwiftUI

struct DayGroup: Identifiable {
    let id = UUID()
    let date: Date
    let meals: [Meal]
    let weekTitle: String?
}

class MealPlanViewModel: ObservableObject {
    private var modelContext: ModelContext?

    @Published var selectedMeal: Meal?
    @Published var isPresentingAddMealView = false
    @Published var isPresentingRecipeListView = false

    func configureContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func dayGroups(for meals: [Meal]) -> [DayGroup] {
        var groups: [DayGroup] = []
        for week in weeksWithMeals(for: meals) {
            let sortedDays = week.keys.sorted()
            for (index, day) in sortedDays.enumerated() {
                let weekHeader: String? =
                    (index == 0)
                    ? "Week \(weekNumber(for: day))"
                    : nil
                groups.append(DayGroup(date: day, meals: week[day] ?? [], weekTitle: weekHeader))
            }
        }
        return groups.sorted(by: { $0.date < $1.date })
    }

    func weeksWithMeals(for meals: [Meal]) -> [[Date: [Meal]]] {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        )!
        let dates = (0..<14).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startOfWeek)
        }
        let mealsByDate = Dictionary(grouping: meals) { meal in
            calendar.startOfDay(for: meal.todoItem.dueDate ?? Date())
        }
        let weeks = stride(from: 0, to: dates.count, by: 7).map {
            Array(dates[$0..<min($0 + 7, dates.count)])
        }
        return weeks.map { week in
            week.reduce(into: [Date: [Meal]]()) { result, date in
                if let mealsForDate = mealsByDate[date], !mealsForDate.isEmpty {
                    result[date] = mealsForDate
                }
            }
        }
    }

    func weekNumber(for date: Date) -> Int {
        Calendar.current.component(.weekOfYear, from: date)
    }

    func mealsForDate(meals: [Meal], in date: Date) -> [Meal] {
        let calendar = Calendar.current
        return meals.filter { meal in
            guard let dueDate = meal.todoItem.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }
    }

    func nextUpcomingMeal(meals: [Meal]) -> Meal? {
        let now = Date()
        return meals.filter { meal in
            guard let dueDate = meal.todoItem.dueDate else { return false }
            return dueDate > now
        }.min { a, b in
            guard let dateA = a.todoItem.dueDate, let dateB = b.todoItem.dueDate else {
                return false
            }
            return dateA < dateB
        }
    }

    func deleteMeal(meals: [Meal], at offsets: IndexSet, for date: Date) {
        withAnimation {
            let mealsForDate = mealsForDate(meals: meals, in: date)
            offsets.map { mealsForDate[$0] }.forEach { meal in
                modelContext?.delete(meal)
            }
            saveContext()
        }
    }

    func markAsDone(_ todoItem: TodoItem) {
        todoItem.markAsDone(modelContext: modelContext!)
        saveContext()
    }

    func isDateInPast(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.compare(date, to: Date(), toGranularity: .day) == .orderedAscending
    }

    private func saveContext() {
        do {
            try modelContext!.save()
        } catch {
            // Error handling as needed.
        }
    }
}
