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
