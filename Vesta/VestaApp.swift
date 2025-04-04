import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import SwiftData
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        if let options = FirebaseApp.app()?.options {
            print("Firebase configuration verified:")
            print("• Project ID: \(options.projectID ?? "unknown")")
            print("• Google App ID: \(options.googleAppID)")
            print("• API Key: \(options.apiKey?.prefix(4))...[redacted]")
            print("• GCM Sender ID: \(options.gcmSenderID)")
        }
        
        #if DEBUG
        //    Auth.auth().useEmulator(withHost: "localhost", port: 9099)
        //    Firestore.firestore().useEmulator(withHost: "localhost", port: 8080)
        #endif

        return true
    }
}

@main
struct VestaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        do {
            let container = try ModelContainerHelper.createModelContainer(
                isStoredInMemoryOnly: false)
            // MigrationManager.migrateToSyncableEntities(in: container.mainContext)
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
            if UserManager.shared.isAuthenticated {
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
                .onAppear {
                    SyncService.shared.configure(with: sharedModelContainer.mainContext)
                    UserManager.shared.configure(with: sharedModelContainer.mainContext)

                    SyncService.shared.startSync()
                }
            } else {
                LoginView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
