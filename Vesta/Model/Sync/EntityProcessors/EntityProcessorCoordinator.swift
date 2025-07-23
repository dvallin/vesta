import Foundation
import OSLog
import SwiftData

class EntityProcessorCoordinator {
    let userProcessor: UserEntityProcessor
    let todoItemProcessor: TodoItemEntityProcessor
    let recipeProcessor: RecipeEntityProcessor
    let mealProcessor: MealEntityProcessor
    let shoppingListItemProcessor: ShoppingListItemEntityProcessor

    let logger: Logger

    init(
        modelContext: ModelContext,
        users: UserService,
        todoItems: TodoItemService,
        todoItemCategories: TodoItemCategoryService,
        meals: MealService,
        recipes: RecipeService,
        shoppingItems: ShoppingListItemService,
        logger: Logger
    ) {
        self.logger = logger

        self.userProcessor = UserEntityProcessor(
            modelContext: modelContext,
            logger: logger,
            users: users
        )

        self.todoItemProcessor = TodoItemEntityProcessor(
            modelContext: modelContext,
            logger: logger,
            todoItems: todoItems,
            users: users,
            meals: meals,
            shoppingItems: shoppingItems,
            todoItemCategories: todoItemCategories
        )

        self.recipeProcessor = RecipeEntityProcessor(
            modelContext: modelContext,
            logger: logger,
            recipes: recipes,
            users: users,
            meals: meals
        )

        self.mealProcessor = MealEntityProcessor(
            modelContext: modelContext,
            logger: logger,
            meals: meals,
            users: users,
            todoItems: todoItems,
            recipes: recipes,
            shoppingItems: shoppingItems
        )

        self.shoppingListItemProcessor = ShoppingListItemEntityProcessor(
            modelContext: modelContext,
            logger: logger,
            shoppingItems: shoppingItems,
            users: users,
            todoItems: todoItems,
            meals: meals
        )
    }

    @MainActor
    func processEntities(_ entityData: [String: [[String: Any]]]) async throws {
        self.logger.info("Processing entities from received data")

        // Process users first since other entities might reference them
        if let userEntities = entityData["users"] {
            try await userProcessor.process(entities: userEntities)
        }

        // Process recipes before meals because meals can reference recipes
        if let recipeEntities = entityData["recipes"] {
            try await recipeProcessor.process(entities: recipeEntities)
        }

        // Process todoItems and meals before shopping items as they might be referenced
        if let todoItemEntities = entityData["todoItems"] {
            try await todoItemProcessor.process(
                entities: todoItemEntities)
        }

        if let mealEntities = entityData["meals"] {
            try await mealProcessor.process(entities: mealEntities)
        }

        // Process shopping items last since they can reference everything else
        if let shoppingListItemEntities = entityData["shoppingListItems"] {
            try await shoppingListItemProcessor.process(
                entities: shoppingListItemEntities
            )
        }

        self.logger.info("Entity processing completed successfully")
    }
}
