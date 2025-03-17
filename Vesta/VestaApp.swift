import SwiftData
import SwiftUI

@main
struct VestaApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            let container = try ModelContainerHelper.createModelContainer(
                isStoredInMemoryOnly: false)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                TodayView().tabItem {
                    Label("Today", systemImage: "list.bullet")
                }
                .onAppear {
                    HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
                }
                MealsView().tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }
                .onAppear {
                    HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
                }
                ShoppingView().tabItem {
                    Label("Shopping", systemImage: "cart")
                }
                .onAppear {
                    HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
