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
                TodayView().tabItem { Label("Today", systemImage: "list.bullet") }
                MealsView().tabItem { Label("Meals", systemImage: "fork.knife") }
                ShoppingView().tabItem { Label("Shopping", systemImage: "cart") }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
