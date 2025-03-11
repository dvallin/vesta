import Foundation
import SwiftData

@Model
class ShoppingListItem {
    var name: String
    var quantity: Double?
    var unit: Unit?
    var isPurchased: Bool
    @Relationship(deleteRule: .cascade)
    var todoItem: TodoItem
    @Relationship(deleteRule: .nullify)
    var meal: Meal?

    init(
        name: String, quantity: Double? = nil, unit: Unit? = nil, isPurchased: Bool = false,
        todoItem: TodoItem, meal: Meal? = nil
    ) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.isPurchased = isPurchased
        self.todoItem = todoItem
        self.meal = meal
    }

    func markAsPurchased() {
        self.isPurchased = true
    }

    func updateQuantity(newQuantity: Double) {
        self.quantity = newQuantity
    }

    func updateUnit(newUnit: Unit) {
        self.unit = newUnit
    }
}
