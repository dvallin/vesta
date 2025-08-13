import Foundation
import SwiftData

extension ShoppingListItem {
    /// Converts the ShoppingListItem entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "ShoppingListItem",
            "uid": uid,
            "ownerId": owner?.uid ?? "",
            "isShared": isShared,

            "name": name,
            "isPurchased": isPurchased,
            "deletedAt": deletedAt as Any,
            "expireAt": expireAt as Any,
        ]

        dto["quantity"] = quantity as Any
        dto["unit"] = unit?.rawValue as Any

        // Add related entity IDs for references
        dto["todoItemId"] = todoItem?.uid as Any

        // Add meal references
        dto["mealIds"] = meals.compactMap { $0.uid }

        return dto
    }

    /// Updates the entity's properties from a dictionary of values
    func update(from data: [String: Any]) {
        // Handle deletedAt - can be nil when restored
        if data.keys.contains("deletedAt") {
            self.deletedAt = data["deletedAt"] as? Date
        }
        // Handle expireAt - can be nil when restored
        if data.keys.contains("expireAt") {
            self.expireAt = data["expireAt"] as? Date
        }
        self.isShared = data["isShared"] as? Bool ?? false

        if let name = data["name"] as? String {
            self.name = name
        }

        if data.keys.contains("quantity") {
            self.quantity = data["quantity"] as? Double
        }

        if data.keys.contains("unit") {
            if let unitRaw = data["unit"] as? String {
                self.unit = Unit(rawValue: unitRaw)
            } else {
                self.unit = nil
            }
        }
    }
}
