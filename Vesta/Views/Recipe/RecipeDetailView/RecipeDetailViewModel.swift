import SwiftData
import SwiftUI

class RecipeDetailViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private var userService: UserService?
    private var dismiss: DismissAction?

    @Published var recipe: Recipe

    @Published var showingValidationAlert = false
    @Published var validationMessage = ""

    init(recipe: Recipe) {
        self.recipe = recipe
    }

    func configureEnvironment(_ context: ModelContext, _ dismiss: DismissAction, _ userService: UserService) {
        self.modelContext = context
        self.dismiss = dismiss
        self.userService = userService
    }

    func save() {
        do {
            try modelContext?.save()
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

    func addIngredient(name: String, quantity: Double?, unit: Unit?) {
        guard let currentUser = userService?.currentUser else { return }
        withAnimation {
            recipe.addIngredient(name: name, quantity: quantity, unit: unit, currentUser: currentUser)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }
    }

    func removeIngredient(_ ingredient: Ingredient) {
        guard let currentUser = userService?.currentUser else { return }
        withAnimation {
            recipe.removeIngredient(ingredient, currentUser: currentUser)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }
    }

    func moveIngredient(from source: IndexSet, to destination: Int) {
        guard let currentUser = userService?.currentUser else { return }
        recipe.moveIngredient(from: source, to: destination, currentUser: currentUser)
    }

    func addStep(instruction: String, type: StepType, duration: TimeInterval?) {
        guard let currentUser = userService?.currentUser else { return }
        withAnimation {
            recipe.addStep(instruction: instruction, type: type, duration: duration, currentUser: currentUser)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }
    }

    func removeStep(_ step: RecipeStep) {
        guard let currentUser = userService?.currentUser else { return }
        withAnimation {
            recipe.removeStep(step, currentUser: currentUser)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }
    }

    func moveStep(from source: IndexSet, to destination: Int) {
        guard let currentUser = userService?.currentUser else { return }
        recipe.moveStep(from: source, to: destination, currentUser: currentUser)
    }
}
