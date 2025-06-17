import SwiftData

class ModelContainerHelper {
    static func createModelContainer(isStoredInMemoryOnly: Bool) throws -> ModelContainer {
        let schema = Schema([
            Meal.self,
            Recipe.self,
            ShoppingListItem.self,
            TodoItem.self,
            TodoItemCategory.self,
            User.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }
}
