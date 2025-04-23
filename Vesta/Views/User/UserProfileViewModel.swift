import Foundation
import SwiftData

class UserProfileViewModel: ObservableObject {
    @Published var isPresentingAddFriendView = false
    @Published var isPresentingInvitesView = false
    @Published var toastMessages: [ToastMessage] = []
    @Published var shareMeals: Bool = false
    @Published var shareShoppingItems: Bool = false
    @Published var selectedCategories: [TodoItemCategory] = []

    private var modelContext: ModelContext?
    private var auth: UserAuthService?

    func configureContext(_ context: ModelContext, _ authService: UserAuthService) {
        self.modelContext = context
        self.auth = authService

        // Initialize sharing preferences from user data
        if let currentUser = auth?.currentUser {
            self.shareMeals = currentUser.shareMeals ?? false
            self.shareShoppingItems = currentUser.shareShoppingItems ?? false
            self.selectedCategories = currentUser.shareTodoItemCategories
        }
    }

    func updateSharingPreferences() {
        guard let currentUser = auth?.currentUser, let context = modelContext else { return }

        currentUser.shareMeals = shareMeals
        currentUser.shareShoppingItems = shareShoppingItems
        currentUser.shareTodoItemCategories = selectedCategories
        currentUser.dirty = true

        do {
            try context.save()
            showToast(
                message: NSLocalizedString(
                    "Sharing preferences updated",
                    comment: "Success message for updating sharing preferences"))
        } catch {
            showToast(
                message: NSLocalizedString(
                    "Failed to update preferences",
                    comment: "Error message for updating sharing preferences"))
        }
    }

    private func showToast(message: String) {
        let toast = ToastMessage(id: UUID(), message: message, undoAction: nil)
        toastMessages.append(toast)
    }
}
