import Foundation
import SwiftData

@Model
class Recipe: SyncableEntity {
    @Attribute(.unique) var uid: String?

    var title: String
    var details: String

    @Relationship(deleteRule: .noAction)
    var owner: User?

    var isShared: Bool = false
    var dirty: Bool = true

    @Relationship(deleteRule: .cascade, inverse: \Ingredient.recipe)
    var ingredients: [Ingredient]

    @Relationship(deleteRule: .cascade, inverse: \RecipeStep.recipe)
    var steps: [RecipeStep]

    @Relationship(deleteRule: .cascade)
    var meals: [Meal]

    init(
        title: String, details: String, ingredients: [Ingredient] = [], steps: [RecipeStep] = [],
        owner: User?
    ) {
        self.uid = UUID().uuidString
        self.title = title
        self.details = details
        self.ingredients = []
        self.steps = []
        self.meals = []
        self.owner = owner
        self.dirty = true

        for ingredient in ingredients {
            ingredient.recipe = self
        }
        for step in steps {
            step.recipe = self
        }
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

    // Mutation methods

    func addIngredient(name: String, quantity: Double?, unit: Unit?, currentUser: User) {
        let newIngredient = Ingredient(
            name: name, order: ingredients.count + 1, quantity: quantity, unit: unit, recipe: self)
        ingredients.append(newIngredient)
        markAsDirty(currentUser)
    }

    func removeIngredient(_ ingredient: Ingredient, currentUser: User) {
        if let index = ingredients.firstIndex(where: { $0 === ingredient }) {
            ingredients.remove(at: index)
            markAsDirty(currentUser)
        }
    }

    func moveIngredient(from source: IndexSet, to destination: Int, currentUser: User) {
        var sortedIngredients = self.sortedIngredients

        sortedIngredients.move(fromOffsets: source, toOffset: destination)
        for (index, ingredient) in sortedIngredients.enumerated() {
            ingredient.order = index + 1
        }
        ingredients = sortedIngredients
        markAsDirty(currentUser)
    }

    func addStep(instruction: String, type: StepType, duration: TimeInterval?, currentUser: User) {
        let newStep = RecipeStep(
            order: steps.count + 1,
            instruction: instruction,
            type: type,
            duration: duration,
            recipe: self
        )
        steps.append(newStep)
        markAsDirty(currentUser)
    }

    func removeStep(_ step: RecipeStep, currentUser: User) {
        if let index = steps.firstIndex(where: { $0 === step }) {
            steps.remove(at: index)
            markAsDirty(currentUser)
        }
    }

    func moveStep(from source: IndexSet, to destination: Int, currentUser: User) {
        var sortedSteps = self.sortedSteps

        sortedSteps.move(fromOffsets: source, toOffset: destination)
        for (index, step) in sortedSteps.enumerated() {
            step.order = index + 1
        }
        steps = sortedSteps
        markAsDirty(currentUser)
    }

    func setTitle(_ newTitle: String, currentUser: User) {
        title = newTitle
        markAsDirty(currentUser)
    }

    func setDetails(_ newDetails: String, currentUser: User) {
        details = newDetails
        markAsDirty(currentUser)
    }
}

@Model
class Ingredient {
    var name: String
    var order: Int
    var quantity: Double?
    var unit: Unit?

    @Relationship
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

    @Relationship
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
