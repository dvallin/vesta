import SwiftData
import SwiftUI

struct ReadOnlyRecipeDetailView: View {
    let recipe: Recipe
    let scalingFactor: Double

    var body: some View {
        Form {
            Section(header: Text(NSLocalizedString("Title", comment: "Section header"))) {
                Text(recipe.title)
            }

            Section(header: Text(NSLocalizedString("Ingredients", comment: "Section header"))) {
                ForEach(recipe.sortedIngredients, id: \.self) { ingredient in
                    HStack {
                        Text(ingredient.name)
                        Spacer()
                        Text(formattedQuantity(for: ingredient))
                    }
                }
            }

            Section(header: Text(NSLocalizedString("Description", comment: "Section header"))) {
                Text(recipe.details)
            }
        }
    }

    private func formattedQuantity(for ingredient: Ingredient) -> String {
        let scaledQuantity = (ingredient.quantity ?? 0) * scalingFactor
        let qtyPart = NumberFormatter.localizedString(
            from: NSNumber(value: scaledQuantity), number: .decimal)
        let unitPart = ingredient.unit?.displayName ?? ""
        return qtyPart + " " + unitPart
    }
}

#Preview {
    let recipe = Recipe(
        title: "Spaghetti Bolognese",
        details: "A classic Italian pasta dish."
    )
    recipe.ingredients.append(Ingredient(name: "Spaghetti", order: 1, quantity: 200, unit: .gram))
    recipe.ingredients.append(Ingredient(name: "Ground Beef", order: 2, quantity: 300, unit: .gram))
    recipe.ingredients.append(
        Ingredient(name: "Tomato Sauce", order: 3, quantity: 400, unit: .milliliter))
    recipe.ingredients.append(Ingredient(name: "Salt", order: 4, quantity: nil, unit: nil))

    return ReadOnlyRecipeDetailView(recipe: recipe, scalingFactor: 1.0)
}
