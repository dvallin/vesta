import SwiftData
import SwiftUI

struct MealPlanViewInner: View {
    @ObservedObject var viewModel: MealPlanViewModel
    var meals: [Meal]
    @State private var isPresentingPlanHelper = false

    var body: some View {
        let filteredMeals = viewModel.filteredMeals(from: meals)
        let (undatedMeals, mealsByDay) = viewModel.groupMealsByDay(filteredMeals)
        let allDates = viewModel.datesInFilterRange()
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
                        if !undatedMeals.isEmpty {
                            mealRows(for: undatedMeals)
                        }

                        ForEach(datesToShow, id: \.self) { date in
                            Section {
                                if let dayMeals = mealsByDay[date], !dayMeals.isEmpty {
                                    mealRows(for: dayMeals)
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
                if viewModel.filterMode != .lastWeek {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            HapticFeedbackManager.shared.generateSelectionFeedback()
                            isPresentingPlanHelper = true
                        }) {
                            Label(
                                NSLocalizedString(
                                    "Plan Helper",
                                    comment: "Plan helper button"),
                                systemImage: "wand.and.stars")
                        }
                    }
                }
            #endif
        }
        .sheet(isPresented: $isPresentingPlanHelper) {
            MealPlanHelperView(filterMode: viewModel.filterMode)
        }
    }

    @ViewBuilder
    private func mealRows(for meals: [Meal]) -> some View {
        ForEach(meals) { meal in
            MealListItem(viewModel: viewModel, meal: meal)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        withAnimation {
                            viewModel.deleteMeal(
                                meal,
                                undoAction: { meal, id in
                                    withAnimation {
                                        viewModel.undoMealDeletion(meal, id: id)
                                    }
                                })
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
    }
}
