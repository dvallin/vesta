import Foundation
import OSLog
import SwiftData

class TodoItemEntityProcessor: BaseEntityProcessor, EntityProcessor {
    var todoItems: TodoItemService
    var users: UserService
    var meals: MealService
    var shoppingItems: ShoppingListItemService
    var todoItemCategories: TodoItemCategoryService

    init(
        modelContext: ModelContext,
        logger: Logger,
        todoItems: TodoItemService,
        users: UserService,
        meals: MealService,
        shoppingItems: ShoppingListItemService,
        todoItemCategories: TodoItemCategoryService
    ) {
        self.todoItems = todoItems
        self.users = users
        self.meals = meals
        self.shoppingItems = shoppingItems
        self.todoItemCategories = todoItemCategories
        super.init(modelContext: modelContext, logger: logger)
    }

    @MainActor
    func process(entities: [[String: Any]], currentUser: User) async throws {
        self.logger.info("Processing \(entities.count) TodoItem entities")

        for data in entities {
            guard let uid = data["uid"] as? String else {
                self.logger.warning("Skipping TodoItem entity without UID")
                continue
            }

            // Check if entity exists or create a new one
            let todoItem: TodoItem
            if let existingTodoItem = try todoItems.fetchUnique(withUID: uid) {
                todoItem = existingTodoItem
                self.logger.debug("Found existing TodoItem with UID: \(uid)")
            } else {
                guard let title = data["title"] as? String,
                    let details = data["details"] as? String
                else {
                    self.logger.warning(
                        "Skipping TodoItem without required title or details: \(uid)")
                    continue
                }

                todoItem = TodoItem(title: title, details: details, owner: nil)
                todoItem.uid = uid
                modelContext.insert(todoItem)
                self.logger.debug("Created new TodoItem with UID: \(uid), title: \(title)")
            }

            // Update properties
            todoItem.update(from: data)
            self.logger.debug("Updated properties for TodoItem: \(uid)")

            // Update owner if available
            if let ownerId = data["ownerId"] as? String {
                if ownerId != todoItem.owner?.uid {
                    if let owner = try? users.fetchUnique(withUID: ownerId) {
                        todoItem.owner = owner
                        self.logger.debug("Set owner \(ownerId) for TodoItem: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find owner with UID \(ownerId) for TodoItem: \(uid)")
                    }
                }
            } else if todoItem.owner != nil {
                self.logger.debug("Removing owner from TodoItem: \(uid)")
                todoItem.owner = nil
            }

            // Process meal reference if available
            if let mealUID = data["mealId"] as? String {
                if mealUID != todoItem.meal?.uid {
                    if let meal = try? meals.fetchUnique(withUID: mealUID) {
                        todoItem.meal = meal
                        self.logger.debug("Set meal \(mealUID) for TodoItem: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find meal with UID \(mealUID) for TodoItem: \(uid)")
                    }
                }
            } else if todoItem.meal != nil {
                self.logger.debug("Removing meal from TodoItem: \(uid)")
                todoItem.meal = nil
            }

            // Process shopping list item reference if available
            if let shoppingListItemUID = data["shoppingListItemId"] as? String {
                if shoppingListItemUID != todoItem.shoppingListItem?.uid {
                    if let shoppingListItem = try? shoppingItems.fetchUnique(
                        withUID: shoppingListItemUID)
                    {
                        todoItem.shoppingListItem = shoppingListItem
                        self.logger.debug(
                            "Set shopping list item \(shoppingListItemUID) for TodoItem: \(uid)")
                    } else {
                        self.logger.debug(
                            "Failed to find shopping list item with UID \(shoppingListItemUID) for TodoItem: \(uid)"
                        )
                    }
                }
            } else if todoItem.shoppingListItem != nil {
                self.logger.debug("Removing shopping list item from TodoItem: \(uid)")
                todoItem.shoppingListItem = nil
            }

            // Process category if available
            if let categoryName = data["categoryName"] as? String {
                if categoryName != todoItem.category?.name {
                    todoItem.category = todoItemCategories.fetchOrCreate(named: categoryName)
                    self.logger.debug("Set category '\(categoryName)' for TodoItem: \(uid)")
                }
            } else if todoItem.category != nil {
                self.logger.debug("Removing category from TodoItem: \(uid)")
                todoItem.category = nil
            }

            todoItem.markAsSynced()
            self.logger.debug("Successfully processed TodoItem: \(uid)")
        }
    }
}
