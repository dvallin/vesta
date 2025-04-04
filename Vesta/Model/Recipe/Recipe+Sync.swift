import Foundation
import SwiftData

extension Recipe {
    /// Converts the Recipe entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "TodoItem",
            "id": id,
            "lastModified": lastModified.timeIntervalSince1970,
            "ownerId": owner?.id ?? "",

            "title": title,
            "details": details,
        ]

        // Include related ingredients
        dto["ingredients"] = ingredients.map { $0.toDTO() }

        // Include related steps
        dto["steps"] = steps.map { $0.toDTO() }

        // Include meal references
        dto["mealIds"] = meals.compactMap { $0.id }

        return dto
    }
}

extension Ingredient {
    /// Converts the Ingredient entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "Ingredient",
            "id": id,

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

        // Add reference to parent recipe if available
        if let recipeId = recipe?.id {
            dto["recipeId"] = recipeId
        }

        return dto
    }
}

extension RecipeStep {
    /// Converts the RecipeStep entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "RecipeStep",
            "id": id,

            "order": order,
            "instruction": instruction,
            "type": type.rawValue,
        ]

        // Add optional duration
        if let duration = duration {
            dto["duration"] = duration
        }

        // Add reference to parent recipe if available
        if let recipeId = recipe?.id {
            dto["recipeId"] = recipeId
        }

        return dto
    }
}
