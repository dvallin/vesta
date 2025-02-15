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
            TabView {
                TodoListView()
                    .tabItem {
                        Label("Todo List", systemImage: "list.bullet")
                    }
                TodoEventsView()
                    .tabItem {
                        Label("Events", systemImage: "clock")
                    }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
