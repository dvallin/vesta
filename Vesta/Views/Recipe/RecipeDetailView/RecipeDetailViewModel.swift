import SwiftData
import SwiftUI

class RecipeDetailViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private var dismiss: DismissAction?

    @Published var recipe: Recipe

    @Published var showingValidationAlert = false
    @Published var validationMessage = ""

    init(recipe: Recipe) {
        self.recipe = recipe
    }

    func configureEnvironment(_ context: ModelContext, _ dismiss: DismissAction) {
        self.modelContext = context
        self.dismiss = dismiss
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
        withAnimation {
            recipe.addIngredient(name: name, quantity: quantity, unit: unit)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }
    }

    func removeIngredient(_ ingredient: Ingredient) {
        withAnimation {
            recipe.removeIngredient(ingredient)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }
    }

    func moveIngredient(from source: IndexSet, to destination: Int) {
        recipe.moveIngredient(from: source, to: destination)
    }

    func addStep(instruction: String, type: StepType, duration: TimeInterval?) {
        withAnimation {
            recipe.addStep(instruction: instruction, type: type, duration: duration)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }
    }

    func removeStep(_ step: RecipeStep) {
        withAnimation {
            recipe.removeStep(step)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }
    }

    func moveStep(from source: IndexSet, to destination: Int) {
        recipe.moveStep(from: source, to: destination)
    }
}
