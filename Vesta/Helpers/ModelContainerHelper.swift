import SwiftData

class ModelContainerHelper {
    static func createModelContainer(isStoredInMemoryOnly: Bool) throws -> ModelContainer {
        let schema = Schema([
            TodoItem.self,
            TodoItemEvent.self,
            Recipe.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }
}


            
