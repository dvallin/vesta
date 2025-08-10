import Foundation
import SwiftData

extension Recipe {
    /// Converts the Recipe entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "Recipe",
            "uid": uid,
            "ownerId": owner?.uid ?? "",
            "isShared": isShared,

            "title": title,
            "details": details,
            "deletedAt": deletedAt as Any,
            "expireAt": expireAt as Any,
        ]

        // Add optional seasonality
        if let seasonality = seasonality {
            dto["seasonality"] = seasonality.rawValue
        }

        // Add meal types
        dto["mealTypes"] = mealTypes.map { $0.rawValue }

        // Add tags
        dto["tags"] = tags

        dto["ingredients"] = ingredients.map { $0.toDTO() }
        dto["steps"] = steps.map { $0.toDTO() }
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

        if let title = data["title"] as? String {
            self.title = title
        }

        if let details = data["details"] as? String {
            self.details = details
        }

        // Handle seasonality
        if let seasonalityRaw = data["seasonality"] as? String {
            self.seasonality = Seasonality(rawValue: seasonalityRaw)
        } else if data.keys.contains("seasonality") {
            self.seasonality = nil
        }

        // Handle meal types
        if let mealTypesRaw = data["mealTypes"] as? [String] {
            self.mealTypes = mealTypesRaw.compactMap { MealType(rawValue: $0) }
        }

        // Handle tags
        if let tags = data["tags"] as? [String] {
            self.tags = tags
        }

        // Process ingredients from data
        self.ingredients.removeAll()
        if let ingredients = data["ingredients"] as? [[String: Any]] {
            for ingredientData in ingredients {
                if let ingredient = Ingredient.fromDTO(ingredientData, recipe: self) {
                    self.ingredients.append(ingredient)
                }
            }
        }

        // Process steps from data
        self.steps.removeAll()
        if let steps = data["steps"] as? [[String: Any]] {
            for stepData in steps {
                if let step = RecipeStep.fromDTO(stepData, recipe: self) {
                    self.steps.append(step)
                }
            }
        }
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

    /// Creates an Ingredient instance from a DTO (Data Transfer Object)
    /// - Parameters:
    ///   - data: Dictionary containing ingredient data
    ///   - recipe: The recipe to associate this ingredient with
    /// - Returns: A new Ingredient instance, or nil if required data is missing
    static func fromDTO(_ data: [String: Any], recipe: Recipe?) -> Ingredient? {
        guard let name = data["name"] as? String,
            let order = data["order"] as? Int
        else { return nil }

        let quantity = data["quantity"] as? Double
        var unit: Unit? = nil
        if let unitRaw = data["unit"] as? String {
            unit = Unit(rawValue: unitRaw)
        }

        return Ingredient(
            name: name,
            order: order,
            quantity: quantity,
            unit: unit,
            recipe: recipe
        )
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

    /// Creates a RecipeStep instance from a DTO (Data Transfer Object)
    /// - Parameters:
    ///   - data: Dictionary containing recipe step data
    ///   - recipe: The recipe to associate this step with
    /// - Returns: A new RecipeStep instance, or nil if required data is missing
    static func fromDTO(_ data: [String: Any], recipe: Recipe?) -> RecipeStep? {
        guard let order = data["order"] as? Int,
            let instruction = data["instruction"] as? String,
            let typeRaw = data["type"] as? String,
            let type = StepType(rawValue: typeRaw)
        else { return nil }

        let duration = data["duration"] as? TimeInterval

        return RecipeStep(
            order: order,
            instruction: instruction,
            type: type,
            duration: duration,
            recipe: recipe
        )
    }
}
