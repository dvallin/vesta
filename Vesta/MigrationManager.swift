import SwiftData
import SwiftUI

struct MigrationManager {
    @MainActor
    static func migrateIgnoreTimeComponent(toDefault container: ModelContainer) {
        let context = container.mainContext

        let descriptor = FetchDescriptor<TodoItem>(predicate: nil, sortBy: [])

        do {
            let items = try context.fetch(descriptor)

            for item in items {
                item.ignoreTimeComponent = false
            }

            try context.save()
            print(
                "Migration succeeded: All TodoItem records now have ignoreTimeComponent set to true."
            )
        } catch {
            // Handle errors as appropriate in your app’s logic.
            print("Migration failed with error: \(error)")
        }
    }
}
