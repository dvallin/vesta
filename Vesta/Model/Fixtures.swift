import SwiftData

struct Fixtures {
    static func createRecipe() -> Recipe {
        let recipe = Recipe(
            title: "Spaghetti Bolognese",
            details:
                "A classic Italian pasta dish. [link to original recipe](https://www.youtube.com/watch?v=0O2Xd-Yw\\_cQ)"
        )

        // Ingredients
        recipe.ingredients.append(
            Ingredient(name: "Spaghetti", order: 1, quantity: 200, unit: .gram))
        recipe.ingredients.append(
            Ingredient(name: "Ground Beef", order: 2, quantity: 300, unit: .gram))
        recipe.ingredients.append(
            Ingredient(name: "Tomato Sauce", order: 3, quantity: 400, unit: .milliliter))
        recipe.ingredients.append(Ingredient(name: "Salt", order: 4, quantity: nil, unit: nil))

        // Steps
        recipe.steps.append(
            RecipeStep(
                order: 1,
                instruction: "Bring a large pot of water to boil",
                type: .preparation,
                duration: 300))  // 5 minutes

        recipe.steps.append(
            RecipeStep(
                order: 2,
                instruction: "Brown the ground beef in a large pan over medium heat",
                type: .cooking,
                duration: 600))  // 10 minutes

        recipe.steps.append(
            RecipeStep(
                order: 3,
                instruction: "Add tomato sauce and seasonings to the beef",
                type: .cooking,
                duration: 120))  // 2 minutes

        recipe.steps.append(
            RecipeStep(
                order: 4,
                instruction: "Let the sauce simmer",
                type: .cooking,
                duration: 1800))  // 30 minutes

        recipe.steps.append(
            RecipeStep(
                order: 5,
                instruction: "Cook spaghetti in boiling water according to package instructions",
                type: .cooking,
                duration: 600))  // 10 minutes

        recipe.steps.append(
            RecipeStep(
                order: 6,
                instruction: "Drain spaghetti and combine with sauce",
                type: .cooking,
                duration: 120))  // 2 minutes

        return recipe
    }
}
