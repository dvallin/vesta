import Foundation
import SwiftData

@Model
class Recipe: SyncableEntity {
    var title: String
    var details: String

    var owner: User?
    var lastModified: Date = Date()
    var dirty: Bool = true

    @Relationship(deleteRule: .cascade)
    var ingredients: [Ingredient]

    @Relationship(deleteRule: .cascade)
    var steps: [RecipeStep]

    @Relationship(deleteRule: .cascade)
    var meals: [Meal]

    init(
        title: String, details: String, ingredients: [Ingredient] = [], steps: [RecipeStep] = [], owner: User
    ) {
        self.title = title
        self.details = details
        self.ingredients = ingredients
        self.steps = steps
        self.meals = []
        self.owner = owner
        self.lastModified = Date()
        self.dirty = true
    }

    var sortedIngredients: [Ingredient] {
        ingredients.sorted { $0.order < $1.order }
    }

    var sortedSteps: [RecipeStep] {
        steps.sorted { $0.order < $1.order }
    }

    var preparationDuration: TimeInterval {
        steps.filter { $0.type == .preparation }.reduce(0) { $0 + ($1.duration ?? 0) }
    }

    var cookingDuration: TimeInterval {
        steps.filter { $0.type == .cooking }.reduce(0) { $0 + ($1.duration ?? 0) }
    }

    var maturingDuration: TimeInterval {
        steps.filter { $0.type == .maturing }.reduce(0) { $0 + ($1.duration ?? 0) }
    }

    var totalDuration: TimeInterval {
        preparationDuration + cookingDuration + maturingDuration
    }
}

@Model
class Ingredient {
    var name: String
    var order: Int
    var quantity: Double?
    var unit: Unit?

    @Relationship(inverse: \Recipe.ingredients)
    var recipe: Recipe?

    init(name: String, order: Int, quantity: Double?, unit: Unit?, recipe: Recipe? = nil) {
        self.name = name
        self.order = order
        self.quantity = quantity
        self.unit = unit
        self.recipe = recipe
    }
}

@Model
class RecipeStep {
    var order: Int
    var instruction: String
    var type: StepType
    var duration: TimeInterval?

    @Relationship(inverse: \Recipe.steps)
    var recipe: Recipe?

    init(
        order: Int, instruction: String, type: StepType, duration: TimeInterval?,
        recipe: Recipe? = nil
    ) {
        self.order = order
        self.instruction = instruction
        self.type = type
        self.duration = duration
        self.recipe = recipe
    }
}

enum StepType: String, Codable, CaseIterable {
    case preparation
    case cooking
    case maturing

    var displayName: String {
        switch self {
        case .preparation:
            return NSLocalizedString("Preparation", comment: "Preparation step type")
        case .cooking:
            return NSLocalizedString("Cooking", comment: "Cooking step type")
        case .maturing:
            return NSLocalizedString("Maturing", comment: "Maturing step type")
        }
    }
}

enum Unit: String, Codable, CaseIterable {
    case teaspoon
    case tablespoon
    case cup
    case milliliter
    case liter
    case gram
    case kilogram
    case ounce
    case pound
    case piece

    var displayName: String {
        switch self {
        case .teaspoon:
            return NSLocalizedString("tsp", comment: "Teaspoon unit abbreviation")
        case .tablespoon:
            return NSLocalizedString("tbsp", comment: "Tablespoon unit abbreviation")
        case .cup:
            return NSLocalizedString("cup", comment: "Cup unit abbreviation")
        case .milliliter:
            return NSLocalizedString("ml", comment: "Milliliter unit abbreviation")
        case .liter:
            return NSLocalizedString("l", comment: "Liter unit abbreviation")
        case .gram:
            return NSLocalizedString("g", comment: "Gram unit abbreviation")
        case .kilogram:
            return NSLocalizedString("kg", comment: "Kilogram unit abbreviation")
        case .ounce:
            return NSLocalizedString("oz", comment: "Ounce unit abbreviation")
        case .pound:
            return NSLocalizedString("lb", comment: "Pound unit abbreviation")
        case .piece:
            return NSLocalizedString("pc", comment: "Piece unit abbreviation")
        }
    }
}
