import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import SwiftData
import SwiftUI

@main
struct VestaApp: App {
    @Environment(\.scenePhase) private var scenePhase

    let sharedModelContainer: ModelContainer
    let userManager: UserManager
    let syncService: SyncService

    init() {
        FirebaseApp.configure()

        do {
            self.sharedModelContainer = try ModelContainerHelper.createModelContainer(
                isStoredInMemoryOnly: false)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        let modelContext = sharedModelContainer.mainContext
        userManager = UserManager(modelContext: modelContext)
        syncService = SyncService(userManager: userManager, modelContext: modelContext)

        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            VestaMainPage()
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(userManager)
        .environmentObject(syncService)
    }
}
