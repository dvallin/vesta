import SwiftData
import SwiftUI

struct MigrationManager {
    @MainActor
    static func migrateIngredientOrder(toDefault container: ModelContainer) {
        let context = container.mainContext

        // Fetch all Recipe objects.
        let recipeFetchDescriptor = FetchDescriptor<Recipe>(predicate: nil, sortBy: [])

        do {
            let recipes = try context.fetch(recipeFetchDescriptor)

            // For each recipe, assign an order to its ingredients based on their current order.
            for recipe in recipes {
                // Enumerate ingredients in their current array order (if that order is meaningful).
                for (index, ingredient) in recipe.ingredients.enumerated() {
                    ingredient.order = index
                }
            }

            try context.save()
            print("Migration succeeded: All Ingredient records now have default order values.")
        } catch {
            // Handle errors as appropriate in your app’s logic.
            print("Migration failed with error: \(error)")
        }
    }
}
