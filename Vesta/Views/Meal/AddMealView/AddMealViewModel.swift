import SwiftData
import SwiftUI

class AddMealViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private var dismiss: DismissAction?

    @Published var selectedRecipe: Recipe?
    @Published var selectedDate: Date
    @Published var scalingFactor: Double = 1.0
    @Published var selectedMealType: MealType = .dinner

    @Published var showingValidationAlert = false
    @Published var validationMessage = ""

    init(selectedDate: Date) {
        self.selectedDate = selectedDate
    }

    func configureEnvironment(_ context: ModelContext, _ dismiss: DismissAction) {
        self.modelContext = context
        self.dismiss = dismiss
    }

    @MainActor
    func save() {
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
            let todoItem = TodoItem(
                title: recipe.title, details: recipe.details,
                dueDate: selectedDate, ignoreTimeComponent: false)
            let meal = Meal(
                scalingFactor: scalingFactor, todoItem: todoItem, recipe: recipe,
                mealType: selectedMealType
            )
            meal.updateTodoItemDueDate(for: selectedMealType, on: selectedDate)

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
        dismiss!()
    }
}
