import Foundation
import SwiftData

@Model
class ShoppingListItem {
    var name: String
    var quantity: Double?
    var unit: Unit?
    @Relationship(deleteRule: .cascade)
    var todoItem: TodoItem
    @Relationship(deleteRule: .nullify)
    var meals: [Meal]

    init(
        name: String, quantity: Double? = nil, unit: Unit? = nil,
        todoItem: TodoItem, meals: [Meal] = []
    ) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.todoItem = todoItem
        self.meals = meals
    }

    func updateQuantity(newQuantity: Double) {
        self.quantity = newQuantity
    }

    func updateUnit(newUnit: Unit) {
        self.unit = newUnit
    }
}
