import Foundation
import SwiftData

@Model
class ShoppingListItem: SyncableEntity {
    var name: String
    var quantity: Double?
    var unit: Unit?

    @Relationship(deleteRule: .noAction)
    var owner: User?

    var lastModified: Date = Date()
    var dirty: Bool = true

    @Relationship(deleteRule: .cascade)
    var todoItem: TodoItem?

    @Relationship(deleteRule: .nullify)
    var meals: [Meal]

    var isPurchased: Bool {
        guard let todoItem = todoItem else { return true }
        return todoItem.isCompleted
    }

    init(
        name: String, quantity: Double? = nil, unit: Unit? = nil,
        todoItem: TodoItem, meals: [Meal] = [], owner: User
    ) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.todoItem = todoItem
        self.meals = meals
        self.owner = owner
        self.lastModified = Date()
        self.dirty = true
    }

    func setQuantity(newQuantity: Double) {
        self.quantity = newQuantity
        self.markAsDirty()
    }

    func setUnit(newUnit: Unit) {
        self.unit = newUnit
        self.markAsDirty()
    }
}
