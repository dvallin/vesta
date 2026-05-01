import Foundation

// MARK: - Protocols

protocol IngredientDisplayable {
    var name: String { get }
    var order: Int { get }
    var quantity: Double? { get }
    var unit: Unit? { get }
}

protocol StepDisplayable {
    var order: Int { get }
    var instruction: String { get }
    var type: StepType { get }
    var duration: TimeInterval? { get }
}

protocol RecipeDisplayable {
    associatedtype IngredientItem: IngredientDisplayable & Identifiable
    associatedtype StepItem: StepDisplayable & Identifiable

    var title: String { get }
    var details: String { get }
    var seasonality: Seasonality? { get }
    var mealTypes: [MealType] { get }
    var tags: [String] { get }

    var sortedIngredients: [IngredientItem] { get }
    var sortedSteps: [StepItem] { get }

    var preparationDuration: TimeInterval { get }
    var cookingDuration: TimeInterval { get }
    var maturingDuration: TimeInterval { get }
    var totalDuration: TimeInterval { get }
}

// MARK: - Default Duration Implementations

extension RecipeDisplayable {
    var preparationDuration: TimeInterval {
        sortedSteps.filter { $0.type == .preparation }.reduce(0) { $0 + ($1.duration ?? 0) }
    }

    var cookingDuration: TimeInterval {
        sortedSteps.filter { $0.type == .cooking }.reduce(0) { $0 + ($1.duration ?? 0) }
    }

    var maturingDuration: TimeInterval {
        sortedSteps.filter { $0.type == .maturing }.reduce(0) { $0 + ($1.duration ?? 0) }
    }

    var totalDuration: TimeInterval {
        preparationDuration + cookingDuration + maturingDuration
    }
}

// MARK: - Conformances for SwiftData Models

extension Ingredient: IngredientDisplayable {}

extension RecipeStep: StepDisplayable {}

extension Recipe: RecipeDisplayable {
    typealias IngredientItem = Ingredient
    typealias StepItem = RecipeStep
}

// MARK: - Conformances for Snapshot Structs

extension IngredientSnapshot: IngredientDisplayable {}

extension StepSnapshot: StepDisplayable {}

extension RecipeSnapshot: RecipeDisplayable {
    var sortedIngredients: [IngredientSnapshot] {
        ingredients.sorted { $0.order < $1.order }
    }

    var sortedSteps: [StepSnapshot] {
        steps.sorted { $0.order < $1.order }
    }
}
