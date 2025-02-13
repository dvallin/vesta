import SwiftData
import SwiftUI

@main
struct VestaApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: false)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TodoListView()
        }
        .modelContainer(sharedModelContainer)
    }
}
