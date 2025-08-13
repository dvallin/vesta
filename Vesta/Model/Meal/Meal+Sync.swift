import Foundation
import SwiftData

extension Meal {
    /// Converts the Meal entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "Meal",
            "uid": uid,
            "ownerId": owner?.uid ?? "",
            "isShared": isShared,

            "scalingFactor": scalingFactor,
            "mealType": mealType.rawValue,
            "deletedAt": deletedAt as Any,
            "expireAt": expireAt as Any,
        ]

        // Add related entity IDs for references
        dto["todoItemId"] = todoItem?.uid as Any
        dto["recipeId"] = recipe?.uid as Any

        // Add shopping list item references
        dto["shoppingListItemIds"] = shoppingListItems.compactMap {
            $0.uid
        }

        return dto
    }

    func update(from dto: [String: Any]) {
        if dto.keys.contains("deletedAt") {
            self.deletedAt = dto["deletedAt"] as? Date
        }
        if dto.keys.contains("expireAt") {
            self.expireAt = dto["expireAt"] as? Date
        }
        self.isShared = dto["isShared"] as? Bool ?? false

        if let scalingFactor = dto["scalingFactor"] as? Double {
            self.scalingFactor = scalingFactor
        }

        if let mealTypeRaw = dto["mealType"] as? String,
            let mealType = MealType(rawValue: mealTypeRaw)
        {
            self.mealType = mealType
        }
    }
}
