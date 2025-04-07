import SwiftUI

struct VestaMainPage: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var syncService: SyncService

    var body: some View {
        if userManager.currentUser != nil {
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
