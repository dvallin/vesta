import Foundation
import SwiftData

extension Space {
    /// Converts the Space entity to a DTO (Data Transfer Object) for API syncing
    func toDTO() -> [String: Any] {
        var dto: [String: Any] = [
            "entityType": "Space",
            "id": id,
            "lastModified": lastModified.timeIntervalSince1970,
            "ownerId": owner?.id ?? "",

            "name": name,
            "shareAllRecipes": shareAllRecipes,
            "shareAllMeals": shareAllMeals,
            "shareAllShoppingItems": shareAllShoppingItems,
        ]

        // Include member references
        dto["memberIds"] = members.compactMap { $0.id }

        // Include shared category references
        dto["sharedCategoryNames"] = sharedCategories.compactMap { $0.name }

        return dto
    }
}
