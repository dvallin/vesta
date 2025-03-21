import SwiftData

struct Fixtures {
    static func createRecipe() -> Recipe {
        let recipe = Recipe(
            title: "Spaghetti Bolognese",
            details: "A classic Italian pasta dish."
        )
        recipe.ingredients.append(
            Ingredient(name: "Spaghetti", order: 1, quantity: 200, unit: .gram))
        recipe.ingredients.append(
            Ingredient(name: "Ground Beef", order: 2, quantity: 300, unit: .gram))
        recipe.ingredients.append(
            Ingredient(name: "Tomato Sauce", order: 3, quantity: 400, unit: .milliliter))
        recipe.ingredients.append(Ingredient(name: "Salt", order: 4, quantity: nil, unit: nil))
        return recipe
    }
}
