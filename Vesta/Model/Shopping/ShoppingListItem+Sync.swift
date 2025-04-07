import Foundation
import SwiftData

extension ShoppingListItem {
    /// Converts the ShoppingListItem entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "ShoppingListItem",
            "uid": uid,
            "lastModified": lastModified,
            "ownerId": owner?.uid ?? "",

            "name": name,
            "isPurchased": isPurchased,
        ]

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
        dto["mealIds"] = meals.compactMap {
            $0.uid
        }

        return dto
    }
}
