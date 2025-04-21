import Foundation
import SwiftData

@Model
class ShoppingListItem: SyncableEntity {
    @Attribute(.unique) var uid: String?

    var name: String
    var quantity: Double?
    var unit: Unit?

    @Relationship(deleteRule: .noAction)
    var owner: User?

    var isShared: Bool = false
    var dirty: Bool = true

    @Relationship(deleteRule: .cascade, inverse: \TodoItem.shoppingListItem)
    var todoItem: TodoItem?

    @Relationship(deleteRule: .nullify)
    var meals: [Meal]

    var isPurchased: Bool {
        guard let todoItem = todoItem else { return true }
        return todoItem.isCompleted
    }

    init(
        name: String, quantity: Double? = nil, unit: Unit? = nil,
        todoItem: TodoItem?, owner: User?
    ) {
        self.uid = UUID().uuidString
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.todoItem = todoItem
        self.meals = []
        self.owner = owner
        self.dirty = true
    }

    func setQuantity(newQuantity: Double?, currentUser: User) {
        self.quantity = newQuantity
        self.markAsDirty(currentUser)
    }

    func setUnit(newUnit: Unit?, currentUser: User) {
        self.unit = newUnit
        self.markAsDirty(currentUser)
    }
}
