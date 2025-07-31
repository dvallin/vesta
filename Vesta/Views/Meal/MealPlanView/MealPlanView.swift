import SwiftData
import SwiftUI

struct MealPlanView: View {
    @EnvironmentObject private var auth: UserAuthService
    @Environment(\.modelContext) private var modelContext
    @Query<Meal>(
        filter: #Predicate { meal in meal.deletedAt == nil }
    ) private var meals: [Meal]

    @StateObject var viewModel = MealPlanViewModel()

    var body: some View {
        let activeSortedMeals = viewModel.activeSortedMeals(from: meals)
        NavigationView {
            ZStack {
                List {
                    if let nextMeal = viewModel.nextUpcomingMeal(
                        meals: activeSortedMeals)
                    {
                        NextMealView(meal: nextMeal) {
                            viewModel.selectedMeal = nextMeal
                        }
                    }
                    Section {
                        ForEach(activeSortedMeals) { meal in
                            Button(action: {
                                viewModel.selectMeal(meal)
                            }) {
                                MealListItem(meal: meal) {
                                    if meal.todoItem != nil {
                                        withAnimation {
                                            viewModel.markMealAsDone(meal)
                                        }
                                    }
                                }
                            }
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
        .sheet(item: $viewModel.selectedMeal) { meal in
            MealDetailView(meal: meal)
        }
        .sheet(isPresented: $viewModel.isPresentingAddMealView) {
            AddMealView()
        }
        .sheet(isPresented: $viewModel.isPresentingRecipeListView) {
            RecipeListView()
        }
        .sheet(isPresented: $viewModel.isPresentingShoppingListGenerator) {
            ShoppingListGeneratorView(meals: activeSortedMeals)
        }
        .toast(messages: $viewModel.toastMessages)
        .onAppear {
            viewModel.configureContext(modelContext, auth)
        }
        .navigationTitle(
            NSLocalizedString("Meal Plan", comment: "Meal plan screen title")
        )
        #if os(iOS)
            .listStyle(InsetGroupedListStyle())
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

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext

        let user = Fixtures.createUser()
        let recipes = [
            Fixtures.bolognese(owner: user),
            Fixtures.curry(owner: user),
            Recipe(title: "Apple Pie", details: "Classic dessert", owner: user),
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
                dueDate: calendar.date(byAdding: .day, value: 1, to: today),
                owner: user
            ),
            TodoItem(
                title: "Make Curry",
                details: "Lunch",
                dueDate: calendar.date(byAdding: .day, value: 2, to: today),
                owner: user
            ),
            TodoItem(
                title: "Bake Apple Pie",
                details: "Dessert",
                dueDate: calendar.date(byAdding: .day, value: 1, to: today),
                owner: user
            ),
        ]

        for todoItem in todoItems {
            context.insert(todoItem)
        }

        let meals = [
            Meal(
                scalingFactor: 1.0, todoItem: todoItems[0], recipe: recipes[0], mealType: .dinner,
                owner: user),
            Meal(
                scalingFactor: 2.0, todoItem: todoItems[1], recipe: recipes[1], mealType: .lunch,
                owner: user),
            Meal(
                scalingFactor: 1.5, todoItem: todoItems[2], recipe: recipes[2], mealType: .dinner,
                owner: user),
        ]

        for meal in meals {
            context.insert(meal)
        }

        let authService = UserAuthService(modelContext: context)
        return MealPlanView()
            .modelContainer(container)
            .environmentObject(authService)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
