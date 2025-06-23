import SwiftUI
import os

struct VestaMainPage: View {
    @EnvironmentObject var auth: UserAuthService
    @EnvironmentObject var syncService: SyncService
    @EnvironmentObject var entitySharingService: EntitySharingService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    private let logger = Logger(subsystem: "com.app.Vesta", category: "MainPage")

    var body: some View {
        if let currentUser = auth.currentUser {
            TabView {
                TodoListView().tabItem {
                    Label("Today", systemImage: "list.bullet")
                }
                .onAppear {
                    HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
                }
                MealPlanView().tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }
                .onAppear {
                    HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
                }
                ShoppingListView(
                    showPurchased: false
                ).tabItem {
                    Label("Shopping", systemImage: "cart")
                }
                .onAppear {
                    HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
                }
                UserProfileView().tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .onAppear {
                    HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
                }
            }
            .onAppear {
                // Handle data migrations first
                MigrationManager.migrateToSyncableEntities(
                    in: modelContext, currentUser: currentUser)

                // Apply sharing settings to all entities
                let updatedCount = entitySharingService.updateEntitySharingStatus(for: currentUser)
                logger.info("Initial sharing status update affected \(updatedCount) entities")

                // Start synchronization with remote server
                syncService.startSync()
            }
            .onDisappear {
                syncService.stopSync()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .background {
                    // Make sure changes are synced when going to background
                    syncService.pushLocalChanges()
                }
            }
        } else {
            LoginView()
        }
    }
}
