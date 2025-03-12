import Foundation
import SwiftData

@Model
class Recipe {
    var title: String
    var details: String
    @Relationship(deleteRule: .cascade)
    var ingredients: [Ingredient]

    init(title: String, details: String, ingredients: [Ingredient] = []) {
        self.title = title
        self.details = details
        self.ingredients = ingredients
    }
}

@Model
class Ingredient {
    var name: String
    var quantity: Double?
    var unit: Unit?

    @Relationship(inverse: \Recipe.ingredients)
    var recipe: Recipe?

    init(name: String, quantity: Double?, unit: Unit?, recipe: Recipe? = nil) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.recipe = recipe
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
            return "tsp"
        case .tablespoon:
            return "tbsp"
        case .cup:
            return "cup"
        case .milliliter:
            return "ml"
        case .liter:
            return "l"
        case .gram:
            return "g"
        case .kilogram:
            return "kg"
        case .ounce:
            return "oz"
        case .pound:
            return "lb"
        case .piece:
            return "pc"
        }
    }
}
