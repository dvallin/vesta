import Foundation
import SwiftData

class ShoppingListItemService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Fetch all shopping list items
    func fetchAll() throws -> [ShoppingListItem] {
        let descriptor = FetchDescriptor<ShoppingListItem>()
        return try modelContext.fetch(descriptor)
    }

    /// Fetch a shopping list item by its unique identifier
    func fetchUnique(withUID uid: String) throws -> ShoppingListItem? {
        let descriptor = FetchDescriptor<ShoppingListItem>(
            predicate: #Predicate<ShoppingListItem> { $0.uid == uid }
        )
        let items = try modelContext.fetch(descriptor)
        return items.first
    }

    /// Fetch multiple shopping list items by their UIDs
    func fetchMany(withUIDs uids: [String]) throws -> [ShoppingListItem] {
        // Fetch all users first
        let allItems = try fetchAll()

        // Then filter in memory to avoid unsupported predicate
        return allItems.filter { item in
            guard let uid = item.uid else { return false }
            return uids.contains(uid)
        }
    }

    /// Fetch all shopping list items owned by a specific user
    func fetchByOwnerId(_ ownerId: String) throws -> [ShoppingListItem] {
        let descriptor = FetchDescriptor<ShoppingListItem>(
            predicate: #Predicate<ShoppingListItem> { item in
                item.owner?.uid == ownerId
            }
        )
        return try modelContext.fetch(descriptor)
    }
}
