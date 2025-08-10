import SwiftData
import SwiftUI

class AddMealViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private var dismiss: DismissAction?
    private var auth: UserAuthService?
    private var categoryService: TodoItemCategoryService?

    @Published var showingErrorAlert = false
    @Published var errorMessage = ""

    func configureEnvironment(
        _ context: ModelContext, _ dismiss: DismissAction, _ auth: UserAuthService
    ) {
        self.modelContext = context
        self.categoryService = TodoItemCategoryService(modelContext: context)
        self.auth = auth
        self.dismiss = dismiss
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
