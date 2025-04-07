import SwiftData
import SwiftUI

class AddMealViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private var dismiss: DismissAction?
    private var userManager: UserManager?
    private var categoryService: TodoItemCategoryService?

    @Published var selectedRecipe: Recipe?
    @Published var selectedDate: Date
    @Published var scalingFactor: Double = 1.0
    @Published var selectedMealType: MealType = .dinner

    @Published var showingValidationAlert = false
    @Published var validationMessage = ""

    init(selectedDate: Date) {
        self.selectedDate = selectedDate
    }

    func configureEnvironment(_ context: ModelContext, _ dismiss: DismissAction, _ userManager: UserManager) {
        self.modelContext = context
        self.categoryService = TodoItemCategoryService(modelContext: context)
        self.userManager = userManager
        self.dismiss = dismiss
    }

    @MainActor
    func save() {
        guard let currentUser = userManager?.currentUser else { return }
        guard let recipe = selectedRecipe else {
            validationMessage = NSLocalizedString(
                "Please select a recipe", comment: "Recipe selection validation message")
            showingValidationAlert = true
            return
        }
        guard modelContext != nil else {
            validationMessage = NSLocalizedString(
                "Environment not configured", comment: "Environment configuration error message")
            showingValidationAlert = true
            return
        }

        do {
            let mealCategory = categoryService?.fetchOrCreate(
                named: NSLocalizedString("Meals", comment: "Category name for meal todo items")
            )

            let todoItem = TodoItem.create(
                title: recipe.title,
                details: recipe.details,
                dueDate: selectedDate,
                ignoreTimeComponent: false,
                category: mealCategory,
                owner: currentUser
            )

            let meal = Meal(
                scalingFactor: scalingFactor, todoItem: todoItem, recipe: recipe,
                mealType: selectedMealType, owner: currentUser
            )
            meal.updateTodoItemDueDate(for: selectedMealType, on: selectedDate, currentUser: currentUser)

            modelContext!.insert(todoItem)
            modelContext!.insert(meal)
            try modelContext!.save()
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)
            dismiss!()
        } catch {
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .error)
            validationMessage = String(
                format: NSLocalizedString(
                    "Error saving meal: %@", comment: "Error saving meal message"),
                error.localizedDescription)
            showingValidationAlert = true
        }
    }

    @MainActor
    func cancel() {
        modelContext?.rollback()
        dismiss!()
    }
}
