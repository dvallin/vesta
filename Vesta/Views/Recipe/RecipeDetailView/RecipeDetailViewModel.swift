import SwiftData
import SwiftUI

@Observable class RecipeDetailViewModel {
    private var modelContext: ModelContext?
    private var auth: UserAuthService?
    private var dismiss: DismissAction?

    var recipe: Recipe

    var showingValidationAlert = false
    var validationMessage = ""
    var toastMessages: [ToastMessage] = []

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
            dismiss?()
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
        dismiss?()
    }

    func addIngredient(name: String, quantity: Double?, unit: Unit?, group: String?) {
        guard let currentUser = auth?.currentUser else { return }
        withAnimation {
            recipe.addIngredient(
                name: name, quantity: quantity, unit: unit, group: group, currentUser: currentUser)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }
    }

    func removeIngredient(_ ingredient: Ingredient) {
        guard let currentUser = auth?.currentUser else { return }
        let index =
            recipe.sortedIngredients.firstIndex(where: { $0 === ingredient })
            ?? recipe.ingredients.count - 1
        withAnimation {
            recipe.removeIngredient(ingredient, currentUser: currentUser)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }

        let toastId = UUID()
        let toast = ToastMessage(
            id: toastId,
            message: String(
                format: NSLocalizedString(
                    "%@ deleted", comment: "Toast message for deleting ingredient"),
                ingredient.name
            ),
            undoAction: { [weak self] in
                guard let self = self, let currentUser = self.auth?.currentUser else { return }
                withAnimation {
                    self.recipe.reinsertIngredient(ingredient, at: index, currentUser: currentUser)
                    self.toastMessages.removeAll { $0.id == toastId }
                    HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
                }
            }
        )
        toastMessages.append(toast)
    }

    func updateIngredient(_ ingredient: Ingredient, name: String, quantity: Double?, unit: Unit?) {
        guard let currentUser = auth?.currentUser else { return }
        recipe.updateIngredient(
            ingredient, name: name, quantity: quantity, unit: unit, currentUser: currentUser)
        HapticFeedbackManager.shared.generateImpactFeedback(style: .light)
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
        let index =
            recipe.sortedSteps.firstIndex(where: { $0 === step })
            ?? recipe.steps.count - 1
        withAnimation {
            recipe.removeStep(step, currentUser: currentUser)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }

        let toastId = UUID()
        let toast = ToastMessage(
            id: toastId,
            message: String(
                format: NSLocalizedString(
                    "Step %d deleted", comment: "Toast message for deleting step"),
                index + 1
            ),
            undoAction: { [weak self] in
                guard let self = self, let currentUser = self.auth?.currentUser else { return }
                withAnimation {
                    self.recipe.reinsertStep(step, at: index, currentUser: currentUser)
                    self.toastMessages.removeAll { $0.id == toastId }
                    HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
                }
            }
        )
        toastMessages.append(toast)
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

    func setServings(_ servings: Int) {
        guard let currentUser = auth?.currentUser else { return }
        recipe.setServings(servings, currentUser: currentUser)
    }

    func setDifficulty(_ difficulty: Difficulty?) {
        guard let currentUser = auth?.currentUser else { return }
        recipe.setDifficulty(difficulty, currentUser: currentUser)
    }

    func setSourceURL(_ url: String?) {
        guard let currentUser = auth?.currentUser else { return }
        recipe.setSourceURL(url, currentUser: currentUser)
    }

    func setNotes(_ notes: String) {
        guard let currentUser = auth?.currentUser else { return }
        recipe.setNotes(notes, currentUser: currentUser)
    }
}
