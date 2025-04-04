import Foundation
import SwiftData

extension Meal {
    /// Converts the Meal entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "Meal",
            "id": id,
            "lastModified": lastModified.timeIntervalSince1970,
            "ownerId": owner?.id ?? "",

            "scalingFactor": scalingFactor,
            "mealType": mealType.rawValue,
            "isDone": isDone,
        ]

        // Add related entity IDs for references
        if let todoItemId = todoItem?.id {
            dto["todoItemId"] = todoItemId
        }

        if let recipeId = recipe?.id {
            dto["recipeId"] = recipeId
        }

        // Add shopping list item references
        dto["shoppingListItemIds"] = shoppingListItems.compactMap {
            $0.id
        }

        return dto
    }
}
