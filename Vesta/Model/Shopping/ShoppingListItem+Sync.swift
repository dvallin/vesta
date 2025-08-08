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
        ]
        if let timestamp = deletedAt {
            dto["deletedAt"] = timestamp
        }

        // Handle optional values
        if let quantity = quantity {
            dto["quantity"] = quantity
        }

        if let unit = unit {
            dto["unit"] = unit.rawValue
        }

        // Add related entity IDs for references
        if let todoItemId = todoItem?.uid {
            dto["todoItemId"] = todoItemId
        }

        // Add meal references
        dto["mealIds"] = meals.compactMap { $0.uid }

        return dto
    }

    /// Updates the entity's properties from a dictionary of values
    func update(from data: [String: Any]) {
        if let deletedAt = data["deletedAt"] as? Date {
            self.deletedAt = deletedAt
        }
        self.isShared = data["isShared"] as? Bool ?? false

        if let name = data["name"] as? String {
            self.name = name
        }

        if let quantity = data["quantity"] as? Double {
            self.quantity = quantity
        }

        if let unitRaw = data["unit"] as? String, let unit = Unit(rawValue: unitRaw) {
            self.unit = unit
        }
    }
}
