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
        ]
        if let timestamp = deletedAt {
            dto["deletedAt"] = timestamp
        }

        // Add related entity IDs for references
        if let todoItemId = todoItem?.uid {
            dto["todoItemId"] = todoItemId
        }

        if let recipeId = recipe?.uid {
            dto["recipeId"] = recipeId
        }

        // Add shopping list item references
        dto["shoppingListItemIds"] = shoppingListItems.compactMap {
            $0.uid
        }

        return dto
    }

    func update(from dto: [String: Any]) {
        if let deletedAt = dto["deletedAt"] as? Date {
            self.deletedAt = deletedAt
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
