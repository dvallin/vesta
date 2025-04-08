import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import SwiftData
import SwiftUI

@main
struct VestaApp: App {
    @Environment(\.scenePhase) private var scenePhase

    let sharedModelContainer: ModelContainer
    let userService: UserService
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
        userService = UserService(modelContext: modelContext)
        syncService = SyncService(userService: userService, modelContext: modelContext)

        MigrationManager.migrateToSyncableEntities(in: ModelContext, userService: UserService)

        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            VestaMainPage()
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(userService)
        .environmentObject(syncService)
    }
}
