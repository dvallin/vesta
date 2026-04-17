import SwiftData
import SwiftUI

struct MealPlanViewInner: View {
    @ObservedObject var viewModel: MealPlanViewModel
    var meals: [Meal]

    private func groupMealsByDay(_ meals: [Meal]) -> [Date: [Meal]] {
        let calendar = Calendar.current
        return Dictionary(grouping: meals) { meal -> Date in
            guard let dueDate = meal.todoItem?.dueDate else {
                return Date.distantFuture
            }
            return calendar.startOfDay(for: dueDate)
        }
    }

    private func datesInFilterRange(filterMode: MealPlanFilterMode) -> [Date] {
        let calendar = Calendar.current
        let now = Date()

        let dateRange: (start: Date, end: Date)?

        switch filterMode {
        case .all:
            // For "all" mode, we don't show empty days
            return []

        case .currentWeek:
            if let interval = calendar.dateInterval(of: .weekOfYear, for: now) {
                dateRange = (interval.start, interval.end)
            } else {
                dateRange = nil
            }

        case .lastWeek:
            let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
            if let interval = calendar.dateInterval(of: .weekOfYear, for: lastWeek) {
                dateRange = (interval.start, interval.end)
            } else {
                dateRange = nil
            }

        case .nextWeek:
            let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: now) ?? now
            if let interval = calendar.dateInterval(of: .weekOfYear, for: nextWeek) {
                dateRange = (interval.start, interval.end)
            } else {
                dateRange = nil
            }
        }

        guard let range = dateRange else { return [] }

        var dates: [Date] = []
        var current = range.start
        while current < range.end {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? range.end
        }
        return dates
    }

    var body: some View {
        let filteredMeals = viewModel.filteredMeals(from: meals)
        let mealsByDay = groupMealsByDay(filteredMeals)
        let allDates = datesInFilterRange(filterMode: viewModel.filterMode)
        // For week views, use all dates; for "all" mode, use only dates with meals
        let datesToShow =
            allDates.isEmpty
            ? mealsByDay.keys.sorted()
            : allDates

        VStack {
            MealPlanQuickFilterView(viewModel: viewModel)
                .padding(.vertical, 8)

            ZStack {
                if filteredMeals.isEmpty {
                    ContentUnavailableView(
                        NSLocalizedString("No Meals Planned", comment: "Empty meal plan title"),
                        systemImage: "fork.knife",
                        description: Text(
                            NSLocalizedString(
                                "Add meals to your plan to see them here.",
                                comment: "Empty meal plan description"
                            )
                        )
                    )
                } else {
                    List {
                        if let nextMeal = viewModel.nextUpcomingMeal(meals: filteredMeals) {
                            NextMealView(meal: nextMeal) {
                                viewModel.selectedMeal = nextMeal
                            }
                        }

                        ForEach(datesToShow, id: \.self) { date in
                            Section {
                                if let dayMeals = mealsByDay[date], !dayMeals.isEmpty {
                                    ForEach(dayMeals) { meal in
                                        MealListItem(viewModel: viewModel, meal: meal)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button(role: .destructive) {
                                                    withAnimation {
                                                        viewModel.deleteMeal(
                                                            meal,
                                                            undoAction: { meal, id in
                                                                withAnimation {
                                                                    viewModel.undoMealDeletion(
                                                                        meal, id: id)
                                                                }
                                                            })
                                                    }
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                } else {
                                    HStack(spacing: 8) {
                                        Image(systemName: "fork.knife")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text(
                                            NSLocalizedString(
                                                "No meals planned",
                                                comment: "Empty day placeholder"
                                            )
                                        )
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    }
                                }
                            } header: {
                                DayHeaderView(date: date)
                            }
                        }
                    }
                }

                FloatingAddButton {
                    viewModel.presentAddMealView()
                }
            }
        }
        .navigationTitle(
            NSLocalizedString("Meal Plan", comment: "Meal plan screen title")
        )
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticFeedbackManager.shared.generateSelectionFeedback()
                        viewModel.isPresentingRecipeListView = true
                    }) {
                        Label(
                            NSLocalizedString("Recipes", comment: "Recipes button"),
                            systemImage: "book")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticFeedbackManager.shared.generateSelectionFeedback()
                        viewModel.isPresentingShoppingListGenerator = true
                    }) {
                        Label(
                            NSLocalizedString(
                                "Generate Shopping List",
                                comment: "Generate shopping list button"),
                            systemImage: "cart")
                    }
                }
            #endif
        }
    }
}
