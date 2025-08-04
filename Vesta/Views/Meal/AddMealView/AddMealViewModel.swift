import SwiftData
import SwiftUI

struct RecipeSections {
    let recent: [Recipe]
    let notPlanned: [Recipe]
    let frequent: [Recipe]
    let all: [Recipe]

    var hasRecentRecipes: Bool { !recent.isEmpty }
    var hasNotPlannedRecipes: Bool { !notPlanned.isEmpty }
    var hasFrequentRecipes: Bool { !frequent.isEmpty }
}

class AddMealViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private var dismiss: DismissAction?
    private var auth: UserAuthService?
    private var categoryService: TodoItemCategoryService?

    @Published var showingErrorAlert = false
    @Published var errorMessage = ""
    @Published var recipeSections = RecipeSections(
        recent: [], notPlanned: [], frequent: [], all: [])

    func configureEnvironment(
        _ context: ModelContext, _ dismiss: DismissAction, _ auth: UserAuthService
    ) {
        self.modelContext = context
        self.categoryService = TodoItemCategoryService(modelContext: context)
        self.auth = auth
        self.dismiss = dismiss
    }

    func organizeRecipes(_ recipes: [Recipe], _ meals: [Meal]) {
        let now = Date()
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now

        // Get all upcoming meals
        let upcomingMeals = getUpcomingMeals(meals: meals, until: nextWeek)
        let plannedRecipeUIDs = Set(upcomingMeals.compactMap { $0.recipe?.uid })

        // Recent recipes (used in last week but not planned ahead)
        let recent = recipes.filter { recipe in
            let recentlyUsed = recipe.meals.contains { meal in
                guard let todoItem = meal.todoItem,
                    let dueDate = todoItem.dueDate
                else { return false }
                return dueDate >= oneWeekAgo && dueDate <= now && meal.isDone
            }
            return recentlyUsed && !plannedRecipeUIDs.contains(recipe.uid)
        }

        // Not planned (not in upcoming meals)
        let notPlanned = recipes.filter { !plannedRecipeUIDs.contains($0.uid) }

        // Most frequent (by completed meal count, limited to top 5)
        let frequent =
            recipes
            .map { recipe in
                let completedMealCount = recipe.meals.filter { $0.isDone }.count
                return (recipe: recipe, count: completedMealCount)
            }
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0.recipe }

        recipeSections = RecipeSections(
            recent: recent,
            notPlanned: notPlanned,
            frequent: frequent,
            all: recipes
        )
    }

    private func getUpcomingMeals(meals: [Meal], until date: Date) -> [Meal] {
        let now = Date()
        return meals.filter { meal in
            guard
                meal.deletedAt == nil,
                let dueDate = meal.todoItem?.dueDate
            else { return false }
            return dueDate > now && dueDate <= date
        }
    }

    func getRecipeStatus(_ recipe: Recipe) -> RecipeStatus {
        let now = Date()
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now

        // Check if already planned
        let hasUpcomingMeal = recipe.meals.contains { meal in
            guard let todoItem = meal.todoItem,
                let dueDate = todoItem.dueDate
            else { return false }
            return dueDate > now && dueDate <= nextWeek && !meal.isDone
        }

        if hasUpcomingMeal {
            return .planned
        }

        // Check if recently made
        let wasRecentlyMade = recipe.meals.contains { meal in
            guard let todoItem = meal.todoItem,
                let dueDate = todoItem.dueDate
            else { return false }
            return dueDate >= oneWeekAgo && dueDate <= now && meal.isDone
        }

        if wasRecentlyMade {
            return .recent
        }

        return .normal
    }

    @MainActor
    func createMeal(with recipe: Recipe) async {
        guard let currentUser = auth?.currentUser else {
            showError(NSLocalizedString("User not authenticated", comment: "Authentication error"))
            return
        }

        guard let context = modelContext else {
            showError(
                NSLocalizedString(
                    "Environment not configured", comment: "Environment configuration error"))
            return
        }

        do {
            let mealCategory = categoryService?.fetchOrCreate(
                named: NSLocalizedString("Meals", comment: "Category name for meal todo items")
            )

            let todoItem = TodoItem.create(
                title: recipe.title,
                details: recipe.details,
                dueDate: nil,
                ignoreTimeComponent: false,
                category: mealCategory,
                owner: currentUser
            )

            let meal = Meal(
                scalingFactor: 1.0,
                todoItem: todoItem,
                recipe: recipe,
                mealType: .dinner,
                owner: currentUser
            )

            context.insert(todoItem)
            context.insert(meal)
            try context.save()

            HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)
            dismiss?()
        } catch {
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .error)
            showError(
                String(
                    format: NSLocalizedString(
                        "Error creating meal: %@", comment: "Error creating meal message"),
                    error.localizedDescription))
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showingErrorAlert = true
    }
}

enum RecipeStatus {
    case normal
    case planned
    case recent
}
