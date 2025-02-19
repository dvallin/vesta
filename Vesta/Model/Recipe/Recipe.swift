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
    case teaspoon = "tsp"
    case tablespoon = "tbsp"
    case cup = "cup"
    case milliliter = "ml"
    case liter = "l"
    case gram = "g"
    case kilogram = "kg"
    case ounce = "oz"
    case pound = "lb"
    case piece = "piece"
}
