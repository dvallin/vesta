import Foundation
import SwiftData

extension Meal {
    /// Converts the Meal entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "Meal",
            "uid": uid ?? "",
            "ownerId": owner?.uid ?? "",
            "lastModifiedBy": lastModifiedBy?.uid,

            "scalingFactor": scalingFactor,
            "mealType": mealType.rawValue,
            "isDone": isDone,
        ]

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

        // Add space references
        dto["spaceIds"] = spaces.compactMap { $0.uid }

        return dto
    }

    func update(from data: [String: Any]) {
        if let scalingFactor = data["scalingFactor"] as? Double {
            self.scalingFactor = scalingFactor
        }

        if let mealTypeRaw = data["mealType"] as? String,
            let mealType = MealType(rawValue: mealTypeRaw)
        {
            self.mealType = mealType
        }
    }
}
