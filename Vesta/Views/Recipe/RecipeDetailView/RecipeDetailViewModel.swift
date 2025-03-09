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
        } catch {
            // Handle save error
        }
    }

    func addIngredient(name: String, quantity: Double?, unit: Unit?) {
        let newIngredient = Ingredient(name: name, quantity: quantity, unit: unit)
        withAnimation {
            recipe.ingredients.append(newIngredient)
        }
    }

    func removeIngredient(_ ingredient: Ingredient) {
        withAnimation {
            if let index = recipe.ingredients.firstIndex(where: { $0 === ingredient }) {
                recipe.ingredients.remove(at: index)
            }
        }
    }
}
