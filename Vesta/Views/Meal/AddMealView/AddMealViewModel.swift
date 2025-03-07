import SwiftData
import SwiftUI

class AddMealViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private var dismiss: DismissAction?

    @Published var selectedRecipe: Recipe?
    @Published var selectedDate: Date
    @Published var scalingFactor: Double = 1.0

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
            validationMessage = "Please select a recipe"
            showingValidationAlert = true
            return
        }
        guard modelContext != nil else {
            validationMessage = "Environment not configured"
            showingValidationAlert = true
            return
        }

        do {
            let todoItem = TodoItem(
                title: recipe.title, details: recipe.details,
                dueDate: selectedDate)
            let meal = Meal(
                scalingFactor: scalingFactor, todoItem: todoItem, recipe: recipe
            )
            modelContext!.insert(todoItem)
            modelContext!.insert(meal)
            try modelContext!.save()
            dismiss!()
        } catch {
            validationMessage = "Error saving meal: \(error.localizedDescription)"
            showingValidationAlert = true
        }
    }

    @MainActor
    func cancel() {
        dismiss!()
    }
}
