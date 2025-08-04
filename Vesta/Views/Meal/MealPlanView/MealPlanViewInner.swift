import SwiftData
import SwiftUI

struct MealPlanViewInner: View {
    @ObservedObject var viewModel: MealPlanViewModel
    var meals: [Meal]

    var body: some View {
        let filteredMeals = viewModel.filteredMeals(from: meals)

        VStack {
            MealPlanQuickFilterView(viewModel: viewModel)
                .padding(.vertical, 8)

            ZStack {
                List {
                    if let nextMeal = viewModel.nextUpcomingMeal(meals: filteredMeals) {
                        NextMealView(meal: nextMeal) {
                            viewModel.selectedMeal = nextMeal
                        }
                    }
                    Section {
                        ForEach(filteredMeals) { meal in
                            MealListItem(viewModel: viewModel, meal: meal)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    // Delete action
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
                    } header: {
                        Text(NSLocalizedString("Meal Plan", comment: "Meal plan section header"))
                            .font(.title2)
                            .foregroundColor(.primary)
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
