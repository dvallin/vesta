import Foundation
import OSLog
import SwiftData

class ShoppingListItemEntityProcessor: BaseEntityProcessor, EntityProcessor {
    var shoppingItems: ShoppingListItemService
    var users: UserService
    var todoItems: TodoItemService
    var meals: MealService

    init(
        modelContext: ModelContext,
        logger: Logger,
        shoppingItems: ShoppingListItemService,
        users: UserService,
        todoItems: TodoItemService,
        meals: MealService
    ) {
        self.shoppingItems = shoppingItems
        self.users = users
        self.todoItems = todoItems
        self.meals = meals
        super.init(modelContext: modelContext, logger: logger)
    }

    @MainActor
    func process(entities: [[String: Any]], currentUser: User) async throws {
        self.logger.info("Processing \(entities.count) ShoppingListItem entities")

        for data in entities {
            guard let uid = data["uid"] as? String else {
                self.logger.warning("Skipping ShoppingListItem entity without UID")
                continue
            }

            // Check if entity exists or create a new one
            let shoppingListItem: ShoppingListItem
            if let existingItem = try shoppingItems.fetchUnique(withUID: uid) {
                shoppingListItem = existingItem
                self.logger.debug("Found existing ShoppingListItem with UID: \(uid)")
            } else {
                guard let name = data["name"] as? String else {
                    self.logger.warning("Skipping ShoppingListItem without required name: \(uid)")
                    continue
                }

                shoppingListItem = ShoppingListItem(
                    name: name,
                    quantity: nil,  // Will be updated from data
                    unit: nil,  // Will be updated from data
                    todoItem: nil,  // Will be updated based on references
                    owner: nil  // Will be updated based on references
                )
                shoppingListItem.uid = uid
                modelContext.insert(shoppingListItem)
                self.logger.debug("Created new ShoppingListItem with UID: \(uid), name: \(name)")
            }

            // Update properties
            shoppingListItem.update(from: data)
            self.logger.debug("Updated properties for ShoppingListItem: \(uid)")

            // Update owner if available
            if let ownerId = data["ownerId"] as? String {
                if ownerId != shoppingListItem.owner?.uid {
                    if let owner = try? users.fetchUnique(withUID: ownerId) {
                        shoppingListItem.owner = owner
                        self.logger.debug("Set owner \(ownerId) for ShoppingListItem: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find owner with UID \(ownerId) for ShoppingListItem: \(uid)")
                    }
                }
            } else if shoppingListItem.owner != nil {
                self.logger.debug("Removing owner from ShoppingListItem: \(uid)")
                shoppingListItem.owner = nil
            }

            // Process todoItem reference if available
            if let todoItemUID = data["todoItemId"] as? String {
                if todoItemUID != shoppingListItem.todoItem?.uid {
                    if let todoItem = try? todoItems.fetchUnique(withUID: todoItemUID) {
                        shoppingListItem.todoItem = todoItem
                        self.logger.debug(
                            "Set todoItem \(todoItemUID) for ShoppingListItem: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find todoItem with UID \(todoItemUID) for ShoppingListItem: \(uid)"
                        )
                    }
                }
            } else if shoppingListItem.todoItem != nil {
                self.logger.debug("Removing todoItem from ShoppingListItem: \(uid)")
                shoppingListItem.todoItem = nil
            }

            // Process meal references
            if let mealIds = data["mealIds"] as? [String], !mealIds.isEmpty {
                self.logger.debug(
                    "Processing \(mealIds.count) meal references for ShoppingListItem: \(uid)")

                let currentMealIds = Set(shoppingListItem.meals.compactMap { $0.uid })
                let newMealIds = Set(mealIds).subtracting(currentMealIds)

                if !newMealIds.isEmpty {
                    if let newMeals = try? meals.fetchMany(withUIDs: Array(newMealIds)) {
                        shoppingListItem.meals.append(contentsOf: newMeals)
                        self.logger.debug(
                            "Added \(newMeals.count) new meals to ShoppingListItem: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find any of the \(newMealIds.count) new meals for ShoppingListItem: \(uid)"
                        )
                    }
                }

                // Remove meals that are no longer associated with this shopping list item
                let initialCount = shoppingListItem.meals.count
                shoppingListItem.meals.removeAll { meal in
                    guard let mealUid = meal.uid else { return false }
                    return !mealIds.contains(mealUid)
                }
                let removedCount = initialCount - shoppingListItem.meals.count
                if removedCount > 0 {
                    self.logger.debug("Removed \(removedCount) meals from ShoppingListItem: \(uid)")
                }
            } else if !shoppingListItem.meals.isEmpty {
                self.logger.debug(
                    "Clearing all \(shoppingListItem.meals.count) meals from ShoppingListItem: \(uid)"
                )
                shoppingListItem.meals.removeAll()
            }

            shoppingListItem.markAsSynced()
            self.logger.debug("Successfully processed ShoppingListItem: \(uid)")
        }
    }
}
