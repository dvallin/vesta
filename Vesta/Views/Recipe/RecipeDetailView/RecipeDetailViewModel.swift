import SwiftData
import SwiftUI

class RecipeDetailViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private var auth: UserAuthService?
    private var dismiss: DismissAction?

    @Published var recipe: Recipe

    @Published var showingValidationAlert = false
    @Published var validationMessage = ""

    init(recipe: Recipe) {
        self.recipe = recipe
    }

    func configureEnvironment(
        _ context: ModelContext, _ dismiss: DismissAction, _ auth: UserAuthService
    ) {
        self.modelContext = context
        self.dismiss = dismiss
        self.auth = auth
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
        guard let currentUser = auth?.currentUser else { return }
        withAnimation {
            recipe.addIngredient(
                name: name, quantity: quantity, unit: unit, currentUser: currentUser)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }
    }

    func removeIngredient(_ ingredient: Ingredient) {
        guard let currentUser = auth?.currentUser else { return }
        withAnimation {
            recipe.removeIngredient(ingredient, currentUser: currentUser)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }
    }

    func moveIngredient(from source: IndexSet, to destination: Int) {
        guard let currentUser = auth?.currentUser else { return }
        recipe.moveIngredient(from: source, to: destination, currentUser: currentUser)
    }

    func addStep(instruction: String, type: StepType, duration: TimeInterval?) {
        guard let currentUser = auth?.currentUser else { return }
        withAnimation {
            recipe.addStep(
                instruction: instruction, type: type, duration: duration, currentUser: currentUser)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }
    }

    func removeStep(_ step: RecipeStep) {
        guard let currentUser = auth?.currentUser else { return }
        withAnimation {
            recipe.removeStep(step, currentUser: currentUser)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }
    }

    func moveStep(from source: IndexSet, to destination: Int) {
        guard let currentUser = auth?.currentUser else { return }
        recipe.moveStep(from: source, to: destination, currentUser: currentUser)
    }

    func setSeasonality(_ seasonality: Seasonality?) {
        guard let currentUser = auth?.currentUser else { return }
        recipe.setSeasonality(seasonality, currentUser: currentUser)
    }

    func setMealTypes(_ mealTypes: [MealType]) {
        guard let currentUser = auth?.currentUser else { return }
        recipe.setMealTypes(mealTypes, currentUser: currentUser)
    }

    func addTag(_ tag: String) {
        guard let currentUser = auth?.currentUser else { return }
        withAnimation {
            recipe.addTag(tag, currentUser: currentUser)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .light)
        }
    }

    func removeTag(_ tag: String) {
        guard let currentUser = auth?.currentUser else { return }
        withAnimation {
            recipe.removeTag(tag, currentUser: currentUser)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .light)
        }
    }

    func setTags(_ tags: [String]) {
        guard let currentUser = auth?.currentUser else { return }
        recipe.setTags(tags, currentUser: currentUser)
    }
}
