import Foundation

// MARK: - Ingredient Snapshot

struct IngredientSnapshot: Hashable, Identifiable {
    var name: String
    var order: Int
    var quantity: Double?
    var unit: Unit?
    var group: String?

    var id: Int { order }

    init(name: String, order: Int, quantity: Double?, unit: Unit?, group: String? = nil) {
        self.name = name
        self.order = order
        self.quantity = quantity
        self.unit = unit
        self.group = group
    }

    init(from ingredient: Ingredient) {
        self.name = ingredient.name
        self.order = ingredient.order
        self.quantity = ingredient.quantity
        self.unit = ingredient.unit
        self.group = ingredient.group
    }
}

extension IngredientSnapshot: Codable {
    private enum CodingKeys: String, CodingKey {
        case name, order, quantity, unit, group
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        order = try container.decode(Int.self, forKey: .order)
        quantity = try container.decodeIfPresent(Double.self, forKey: .quantity)
        unit = try container.decodeIfPresent(Unit.self, forKey: .unit)
        group = try container.decodeIfPresent(String.self, forKey: .group)
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

struct RecipeSnapshot: Hashable {
    var title: String
    var details: String
    var ingredients: [IngredientSnapshot]
    var steps: [StepSnapshot]
    var seasonality: Seasonality?
    var mealTypes: [MealType]
    var tags: [String]
    var servings: Int
    var difficulty: Difficulty?

    init(
        title: String,
        details: String,
        ingredients: [IngredientSnapshot],
        steps: [StepSnapshot],
        seasonality: Seasonality?,
        mealTypes: [MealType],
        tags: [String],
        servings: Int = 4,
        difficulty: Difficulty? = nil
    ) {
        self.title = title
        self.details = details
        self.ingredients = ingredients
        self.steps = steps
        self.seasonality = seasonality
        self.mealTypes = mealTypes
        self.tags = tags
        self.servings = servings
        self.difficulty = difficulty
    }

    init(from recipe: Recipe) {
        self.title = recipe.title
        self.details = recipe.details
        self.ingredients = recipe.sortedIngredients.map { IngredientSnapshot(from: $0) }
        self.steps = recipe.sortedSteps.map { StepSnapshot(from: $0) }
        self.seasonality = recipe.seasonality
        self.mealTypes = recipe.mealTypes
        self.tags = recipe.tags
        self.servings = recipe.servings
        self.difficulty = recipe.difficulty
    }

    func apply(to recipe: Recipe, currentUser: User) {
        recipe.setTitle(title, currentUser: currentUser)
        recipe.setDetails(details, currentUser: currentUser)
        recipe.setSeasonality(seasonality, currentUser: currentUser)
        recipe.setMealTypes(mealTypes, currentUser: currentUser)
        recipe.setTags(tags, currentUser: currentUser)
        recipe.setServings(servings, currentUser: currentUser)
        recipe.setDifficulty(difficulty, currentUser: currentUser)

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
                group: ingredient.group,
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

// MARK: - Codable (backward-compatible: LLM responses omitting new fields still decode)

extension RecipeSnapshot: Codable {
    private enum CodingKeys: String, CodingKey {
        case title, details, ingredients, steps, seasonality, mealTypes, tags, servings, difficulty
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        details = try container.decode(String.self, forKey: .details)
        ingredients = try container.decode([IngredientSnapshot].self, forKey: .ingredients)
        steps = try container.decode([StepSnapshot].self, forKey: .steps)
        seasonality = try container.decodeIfPresent(Seasonality.self, forKey: .seasonality)
        mealTypes = try container.decodeIfPresent([MealType].self, forKey: .mealTypes) ?? []
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        servings = try container.decodeIfPresent(Int.self, forKey: .servings) ?? 4
        difficulty = try container.decodeIfPresent(Difficulty.self, forKey: .difficulty)
    }
}
