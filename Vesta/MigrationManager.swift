import SwiftData
import SwiftUI

struct MigrationManager {
    @MainActor
    static func migratePriority(toDefault container: ModelContainer) {
        let context = container.mainContext

        let allTodoItems = FetchDescriptor<TodoItem>(predicate: nil, sortBy: [])

        do {
            let items = try context.fetch(allTodoItems)

            for item in items {
                item.priority = 4
            }

            try context.save()
            print("Migration succeeded: All Items records now have default order values.")
        } catch {
            // Handle errors as appropriate in your app’s logic.
            print("Migration failed with error: \(error)")
        }
    }
}
