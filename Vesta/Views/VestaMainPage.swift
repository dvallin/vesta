import SwiftUI

struct VestaMainPage: View {
    @EnvironmentObject var auth: UserAuthService
    @EnvironmentObject var syncService: SyncService
    @Environment(\.modelContext) private var modelContext

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
                MigrationManager.migrateToSyncableEntities(
                    in: modelContext, currentUser: currentUser)
                syncService.startSync()
            }
            .onDisappear {
                syncService.stopSync()
            }
        } else {
            LoginView()
        }
    }
}
