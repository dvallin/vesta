import SwiftData
import SwiftUI

struct MigrationManager {

    static func migrateToSyncableEntities(in context: ModelContext, auth: UserAuthService) {
        // Get the dummy user for offline development
        guard let dummyUser = auth.currentUser else { return }

        // Assign owners to all entities that implement SyncableEntity
        migrateTodoItemEvents(in: context, defaultOwner: dummyUser)
        migrateTodoItems(in: context, defaultOwner: dummyUser)
        migrateRecipes(in: context, defaultOwner: dummyUser)
        migrateMeals(in: context, defaultOwner: dummyUser)
        migrateShoppingListItems(in: context, defaultOwner: dummyUser)
        migrateSpaces(in: context, defaultOwner: dummyUser)

        // Save changes
        do {
            try context.save()
        } catch {
            print("Error saving migration changes: \(error)")
        }
    }

    private static func migrateTodoItemEvents(in context: ModelContext, defaultOwner: User) {
        let descriptor = FetchDescriptor<TodoItemEvent>()
        do {
            let items = try context.fetch(descriptor)
            for item in items {
                if item.uid == nil {
                    item.uid = UUID().uuidString
                }
                if item.owner == nil {
                    item.owner = defaultOwner
                    item.dirty = true
                }
            }
        } catch {
            print("Error migrating TodoItems: \(error)")
        }
    }

    private static func migrateTodoItems(in context: ModelContext, defaultOwner: User) {
        let descriptor = FetchDescriptor<TodoItem>()
        do {
            let items = try context.fetch(descriptor)
            for item in items {
                if item.uid == nil {
                    item.uid = UUID().uuidString
                }
                if item.owner == nil {
                    item.owner = defaultOwner
                    item.dirty = true
                }
            }
        } catch {
            print("Error migrating TodoItems: \(error)")
        }
    }

    private static func migrateRecipes(in context: ModelContext, defaultOwner: User) {
        let descriptor = FetchDescriptor<Recipe>()
        do {
            let recipes = try context.fetch(descriptor)
            for recipe in recipes {
                if recipe.uid == nil {
                    recipe.uid = UUID().uuidString
                }
                if recipe.owner == nil {
                    recipe.owner = defaultOwner
                    recipe.dirty = true
                }
            }
        } catch {
            print("Error migrating Recipes: \(error)")
        }
    }

    private static func migrateMeals(in context: ModelContext, defaultOwner: User) {
        let descriptor = FetchDescriptor<Meal>()
        do {
            let meals = try context.fetch(descriptor)
            for meal in meals {
                if meal.uid == nil {
                    meal.uid = UUID().uuidString
                }
                if meal.owner == nil {
                    meal.owner = defaultOwner
                    meal.dirty = true
                }
            }
        } catch {
            print("Error migrating Meals: \(error)")
        }
    }

    private static func migrateShoppingListItems(in context: ModelContext, defaultOwner: User) {
        let descriptor = FetchDescriptor<ShoppingListItem>()
        do {
            let items = try context.fetch(descriptor)
            for item in items {
                if item.uid == nil {
                    item.uid = UUID().uuidString
                }
                if item.owner == nil {
                    item.owner = defaultOwner
                    item.dirty = true
                }
            }
        } catch {
            print("Error migrating ShoppingListItems: \(error)")
        }
    }

    private static func migrateSpaces(in context: ModelContext, defaultOwner: User) {
        let descriptor = FetchDescriptor<Space>()
        do {
            let spaces = try context.fetch(descriptor)
            for space in spaces {
                if space.uid == nil {
                    space.uid = UUID().uuidString
                }
                if space.owner == nil {
                    space.owner = defaultOwner
                    space.dirty = true
                }
            }
        } catch {
            print("Error migrating Spaces: \(error)")
        }
    }
}
