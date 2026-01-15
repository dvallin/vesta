import SwiftData
import SwiftUI

struct MigrationManager {

    static func migrateToSyncableEntities(in context: ModelContext, currentUser: User) {
        do {
            //cleanupShoppingListItemReferences(in: context)
            //deleteAllShoppingListItems(in: context)
            //try context.save()
        } catch {
            print("Error saving migration changes: \(error)")
        }
    }

    static func cleanupShoppingListItemReferences(in context: ModelContext) {
        let todoDescriptor = FetchDescriptor<TodoItem>()
        do {
            let todoItems = try context.fetch(todoDescriptor)
            for todoItem in todoItems {
                // Nullify the relationship to avoid cascade deletion issues
                todoItem.shoppingListItem = nil
            }
        } catch {
            print("Error fetching todo items for cleanup: \(error)")
        }
    }

    static func deleteAllShoppingListItems(in context: ModelContext) {
        let descriptor = FetchDescriptor<ShoppingListItem>()
        do {
            let shoppingListItems = try context.fetch(descriptor)
            for item in shoppingListItems {
                context.delete(item)
            }
        } catch {
            print("Error fetching shopping list items for deletion: \(error)")
        }
    }
}
