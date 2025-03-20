import SwiftData
import SwiftUI

class RecipeDetailViewModel: ObservableObject {
    private var modelContext: ModelContext?

    @Published var recipe: Recipe

    init(recipe: Recipe) {
        self.recipe = recipe
    }

    func configureEnvironment(_ context: ModelContext) {
        self.modelContext = context
    }

    func save() {
        do {
            try modelContext?.save()
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)
        } catch {
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .error)
        }
    }

    func addIngredient(name: String, quantity: Double?, unit: Unit?) {
        let newIngredient = Ingredient(
            name: name, order: recipe.ingredients.count + 1, quantity: quantity, unit: unit)
        withAnimation {
            recipe.ingredients.append(newIngredient)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }
    }

    func removeIngredient(_ ingredient: Ingredient) {
        withAnimation {
            if let index = recipe.ingredients.firstIndex(where: { $0 === ingredient }) {
                recipe.ingredients.remove(at: index)
                HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
            }
        }
    }

    func moveIngredient(from source: IndexSet, to destination: Int) {
        var sortedIngredients = recipe.sortedIngredients
        
        sortedIngredients.move(fromOffsets: source, toOffset: destination)
        for (index, ingredient) in sortedIngredients.enumerated() {
            ingredient.order = index + 1
        }
        recipe.ingredients = sortedIngredients
    }
}
