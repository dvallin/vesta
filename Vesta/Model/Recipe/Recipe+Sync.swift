import Foundation
import SwiftData

extension Recipe {
    /// Converts the Recipe entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "TodoItem",
            "uid": uid,
            "ownerId": owner?.uid ?? "",
            "lastModifiedBy": lastModifiedBy?.uid,

            "title": title,
            "details": details,
        ]

        // Include related ingredients
        dto["ingredients"] = ingredients.map { $0.toDTO() }

        // Include related steps
        dto["steps"] = steps.map { $0.toDTO() }

        // Include meal references
        dto["mealIds"] = meals.compactMap { $0.uid }

        // Add space references
        dto["spaceIds"] = spaces.compactMap { $0.uid }

        return dto
    }
}

extension Ingredient {
    /// Converts the Ingredient entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "Ingredient",

            "name": name,
            "order": order,
        ]

        // Add optional properties
        if let quantity = quantity {
            dto["quantity"] = quantity
        }

        if let unit = unit {
            dto["unit"] = unit.rawValue
        }

        return dto
    }
}

extension RecipeStep {
    /// Converts the RecipeStep entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "RecipeStep",

            "order": order,
            "instruction": instruction,
            "type": type.rawValue,
        ]

        // Add optional duration
        if let duration = duration {
            dto["duration"] = duration
        }

        return dto
    }
}
