import Foundation

// MARK: - Ingredient Snapshot

struct IngredientSnapshot: Codable, Hashable, Identifiable {
    var name: String
    var order: Int
    var quantity: Double?
    var unit: Unit?

    var id: Int { order }

    init(name: String, order: Int, quantity: Double?, unit: Unit?) {
        self.name = name
        self.order = order
        self.quantity = quantity
        self.unit = unit
    }

    init(from ingredient: Ingredient) {
        self.name = ingredient.name
        self.order = ingredient.order
        self.quantity = ingredient.quantity
        self.unit = ingredient.unit
    }
}

// MARK: - Step Snapshot

struct StepSnapshot: Codable, Hashable, Identifiable {
    var order: Int
    var instruction: String
    var type: StepType
    var duration: TimeInterval?

    var id: Int { order }

    init(order: Int, instruction: String, type: StepType, duration: TimeInterval?) {
        self.order = order
        self.instruction = instruction
        self.type = type
        self.duration = duration
    }

    init(from step: RecipeStep) {
        self.order = step.order
        self.instruction = step.instruction
        self.type = step.type
        self.duration = step.duration
    }
}

// MARK: - Recipe Snapshot

struct RecipeSnapshot: Codable, Hashable {
    var title: String
    var details: String
    var ingredients: [IngredientSnapshot]
    var steps: [StepSnapshot]
    var seasonality: Seasonality?
    var mealTypes: [MealType]
    var tags: [String]

    init(
        title: String,
        details: String,
        ingredients: [IngredientSnapshot],
        steps: [StepSnapshot],
        seasonality: Seasonality?,
        mealTypes: [MealType],
        tags: [String]
    ) {
        self.title = title
        self.details = details
        self.ingredients = ingredients
        self.steps = steps
        self.seasonality = seasonality
        self.mealTypes = mealTypes
        self.tags = tags
    }

    init(from recipe: Recipe) {
        self.title = recipe.title
        self.details = recipe.details
        self.ingredients = recipe.sortedIngredients.map { IngredientSnapshot(from: $0) }
        self.steps = recipe.sortedSteps.map { StepSnapshot(from: $0) }
        self.seasonality = recipe.seasonality
        self.mealTypes = recipe.mealTypes
        self.tags = recipe.tags
    }

    func apply(to recipe: Recipe, currentUser: User) {
        recipe.setTitle(title, currentUser: currentUser)
        recipe.setDetails(details, currentUser: currentUser)
        recipe.setSeasonality(seasonality, currentUser: currentUser)
        recipe.setMealTypes(mealTypes, currentUser: currentUser)
        recipe.setTags(tags, currentUser: currentUser)

        let existingIngredients = Array(recipe.ingredients)
        for ingredient in existingIngredients {
            recipe.removeIngredient(ingredient, currentUser: currentUser)
        }

        let existingSteps = Array(recipe.steps)
        for step in existingSteps {
            recipe.removeStep(step, currentUser: currentUser)
        }

        for ingredient in ingredients {
            recipe.addIngredient(
                name: ingredient.name,
                quantity: ingredient.quantity,
                unit: ingredient.unit,
                currentUser: currentUser
            )
        }

        for step in steps {
            recipe.addStep(
                instruction: step.instruction,
                type: step.type,
                duration: step.duration,
                currentUser: currentUser
            )
        }
    }
}
