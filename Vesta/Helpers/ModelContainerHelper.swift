import SwiftData

class ModelContainerHelper {
    static func createModelContainer(isStoredInMemoryOnly: Bool) throws -> ModelContainer {
        let schema = Schema([
            Meal.self,
            Recipe.self,
            ShoppingListItem.self,
            Space.self,
            TodoItem.self,
            TodoItemCategory.self,
            TodoItemEvent.self,
            User.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }
}
