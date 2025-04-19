import Foundation
import SwiftData

extension Space {
    /// Converts the Space entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "Space",
            "uid": uid,
            "ownerId": owner?.uid ?? "",
            "lastModifiedBy": lastModifiedBy?.uid,

            "name": name,
            "shareAllRecipes": shareAllRecipes,
            "shareAllMeals": shareAllMeals,
            "shareAllShoppingItems": shareAllShoppingItems,
        ]

        // Include member references
        dto["memberIds"] = members.compactMap { $0.uid }

        // Include shared category references
        dto["sharedCategoryNames"] = sharedCategories.compactMap { $0.name }

        return dto
    }

    /// Update properties from server data
    func update(from data: [String: Any]) {
        if let name = data["name"] as? String {
            self.name = name
        }

        if let shareAllRecipes = data["shareAllRecipes"] as? Bool {
            self.shareAllRecipes = shareAllRecipes
        }

        if let shareAllMeals = data["shareAllMeals"] as? Bool {
            self.shareAllMeals = shareAllMeals
        }

        if let shareAllShoppingItems = data["shareAllShoppingItems"] as? Bool {
            self.shareAllShoppingItems = shareAllShoppingItems
        }
    }
}
