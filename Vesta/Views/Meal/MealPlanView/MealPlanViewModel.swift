import SwiftData
import SwiftUI

class MealPlanViewModel: ObservableObject {
    private var modelContext: ModelContext?

    @Published var selectedMeal: Meal?
    @Published var isPresentingAddMealView = false
    @Published var isPresentingRecipeListView = false

    @Published var meals: [Meal] = []

    func configureContext(_ context: ModelContext) {
        self.modelContext = context
    }

    var weeks: [[Date]] {
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

    func weekNumber(for date: Date) -> Int {
        Calendar.current.component(.weekOfYear, from: date)
    }

    func mealsForDate(_ date: Date) -> [Meal] {
        let calendar = Calendar.current
        return meals.filter { meal in
            guard let dueDate = meal.todoItem.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }
    }

    var nextUpcomingMeal: Meal? {
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

    func deleteMeal(at offsets: IndexSet, for date: Date) {
        withAnimation {
            let mealsForDate = mealsForDate(date)
            offsets.map { mealsForDate[$0] }.forEach { meal in
                modelContext?.delete(meal)
            }
        }
    }

    func isDateInPast(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.compare(date, to: Date(), toGranularity: .day) == .orderedAscending
    }
}
