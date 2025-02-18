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

    func addIngredient(name: String, quantity: Double, unit: String) {
        let ingredient = Ingredient(name: name, quantity: quantity, unit: unit, recipe: self)
        ingredients.append(ingredient)
    }

    func removeIngredient(ingredient: Ingredient) {
        if let index = ingredients.firstIndex(where: { $0 === ingredient }) {
            ingredients.remove(at: index)
        }
    }
}

@Model
class Ingredient {
    var name: String
    var quantity: Double
    var unit: String

    @Relationship(inverse: \Recipe.ingredients)
    var recipe: Recipe?

    init(name: String, quantity: Double, unit: String, recipe: Recipe? = nil) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.recipe = recipe
    }
}
