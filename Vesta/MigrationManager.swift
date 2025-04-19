import SwiftData
import SwiftUI

struct MigrationManager {

    static func migrateToSyncableEntities(in context: ModelContext, currentUser: User) {

        // Assign owners to all entities that implement SyncableEntity
        migrateTodoItemEvents(in: context, owner: currentUser)
        migrateTodoItems(in: context, owner: currentUser)
        migrateRecipes(in: context, owner: currentUser)
        migrateMeals(in: context, owner: currentUser)
        migrateShoppingListItems(in: context, owner: currentUser)
        migrateSpaces(in: context, owner: currentUser)
        migrateUsers(in: context, owner: currentUser)

        // Save changes
        do {
            try context.save()
        } catch {
            print("Error saving migration changes: \(error)")
        }
    }

    private static func migrateUsers(in context: ModelContext, owner: User) {
        let descriptor = FetchDescriptor<User>()
        do {
            let users = try context.fetch(descriptor)
            for user in users {
                if user.uid == nil {
                    print("Error \(user) does not contain uuid")
                }
                if user.owner == nil {
                    user.owner = owner
                    print("User \(user.id) marked as dirty: owner assigned")
                }
            }
        } catch {
            print("Error migrating TodoItems: \(error)")
        }
    }

    private static func migrateTodoItemEvents(in context: ModelContext, owner: User) {
        let descriptor = FetchDescriptor<TodoItemEvent>()
        do {
            let items = try context.fetch(descriptor)
            for item in items {
                if item.uid == nil {
                    item.uid = UUID().uuidString
                    item.dirty = true
                    print("TodoItemEvent \(item.id) marked as dirty: missing UID generated")
                }
                if item.owner == nil {
                    item.owner = owner
                    item.dirty = true
                    print("TodoItemEvent \(item.toDTO()) marked as dirty: owner assigned")
                }
            }
        } catch {
            print("Error migrating TodoItems: \(error)")
        }
    }

    private static func migrateTodoItems(in context: ModelContext, owner: User) {
        let descriptor = FetchDescriptor<TodoItem>()
        do {
            let items = try context.fetch(descriptor)
            for item in items {
                if item.uid == nil {
                    item.uid = UUID().uuidString
                    item.dirty = true
                    print("TodoItem \(item.id) marked as dirty: missing UID generated")
                }
                if item.owner == nil {
                    item.owner = owner
                    item.dirty = true
                    print("TodoItem \(item.id) marked as dirty: owner assigned")
                }
            }
        } catch {
            print("Error migrating TodoItems: \(error)")
        }
    }

    private static func migrateRecipes(in context: ModelContext, owner: User) {
        let descriptor = FetchDescriptor<Recipe>()
        do {
            let recipes = try context.fetch(descriptor)
            for recipe in recipes {
                if recipe.uid == nil {
                    recipe.uid = UUID().uuidString
                    recipe.dirty = true
                    print("Recipe \(recipe.id) marked as dirty: missing UID generated")
                }
                if recipe.owner == nil {
                    recipe.owner = owner
                    recipe.dirty = true
                    print("Recipe \(recipe.id) marked as dirty: owner assigned")
                }
            }
        } catch {
            print("Error migrating Recipes: \(error)")
        }
    }

    private static func migrateMeals(in context: ModelContext, owner: User) {
        let descriptor = FetchDescriptor<Meal>()
        do {
            let meals = try context.fetch(descriptor)
            for meal in meals {
                if meal.uid == nil {
                    meal.uid = UUID().uuidString
                    meal.dirty = true
                    print("Meal \(meal.id) marked as dirty: missing UID generated")
                }
                if meal.owner == nil {
                    meal.owner = owner
                    meal.dirty = true
                    print("Meal \(meal.id) marked as dirty: owner assigned")
                }
            }
        } catch {
            print("Error migrating Meals: \(error)")
        }
    }

    private static func migrateShoppingListItems(in context: ModelContext, owner: User) {
        let descriptor = FetchDescriptor<ShoppingListItem>()
        do {
            let items = try context.fetch(descriptor)
            for item in items {
                if item.uid == nil {
                    item.uid = UUID().uuidString
                    item.dirty = true
                    print("ShoppingListItem \(item.id) marked as dirty: missing UID generated")
                }
                if item.owner == nil {
                    item.owner = owner
                    item.dirty = true
                    print("ShoppingListItem \(item.id) marked as dirty: owner assigned")
                }
            }
        } catch {
            print("Error migrating ShoppingListItems: \(error)")
        }
    }

    private static func migrateSpaces(in context: ModelContext, owner: User) {
        let descriptor = FetchDescriptor<Space>()
        do {
            let spaces = try context.fetch(descriptor)
            for space in spaces {
                if space.uid == nil {
                    space.uid = UUID().uuidString
                    space.dirty = true
                    print("Space \(space.id) marked as dirty: missing UID generated")
                }
                if space.owner == nil {
                    space.owner = owner
                    space.dirty = true
                    print("Space \(space.id) marked as dirty: owner assigned")
                }
            }
        } catch {
            print("Error migrating Spaces: \(error)")
        }
    }
}
