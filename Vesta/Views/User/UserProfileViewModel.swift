import Foundation
import SwiftData
import os

class UserProfileViewModel: ObservableObject {
    @Published var isPresentingAddFriendView = false
    @Published var isPresentingInvitesView = false
    @Published var toastMessages: [ToastMessage] = []
    @Published var shareMeals: Bool = false
    @Published var shareShoppingItems: Bool = false
    @Published var selectedCategories: [TodoItemCategory] = []
    @Published var isOnHoliday: Bool = false
    @Published var holidayStartDate: Date? = nil

    private var modelContext: ModelContext?
    private var auth: UserAuthService?
    private var sharingService: EntitySharingService?
    private let logger = Logger(subsystem: "com.app.Vesta", category: "UserProfile")

    func configureContext(_ context: ModelContext, _ authService: UserAuthService) {
        self.modelContext = context
        self.auth = authService

        // Create services needed for EntitySharingService
        let todoItemService = TodoItemService(modelContext: context)
        let mealService = MealService(modelContext: context)
        let recipeService = RecipeService(modelContext: context)
        let shoppingItemService = ShoppingListItemService(modelContext: context)

        // Initialize the sharing service
        self.sharingService = EntitySharingService(
            modelContext: context,
            todoItemService: todoItemService,
            mealService: mealService,
            recipeService: recipeService,
            shoppingItemService: shoppingItemService
        )

        // Initialize sharing preferences from user data
        if let currentUser = auth?.currentUser {
            self.shareMeals = currentUser.shareMeals ?? false
            self.shareShoppingItems = currentUser.shareShoppingItems ?? false
            self.selectedCategories = currentUser.shareTodoItemCategories
            self.isOnHoliday = currentUser.isOnHoliday
            self.holidayStartDate = currentUser.holidayStartDate
        }
    }

    func save() {
        guard let currentUser = auth?.currentUser, let context = modelContext else { return }

        // Update user preferences
        currentUser.shareMeals = shareMeals
        currentUser.shareShoppingItems = shareShoppingItems
        currentUser.shareTodoItemCategories = selectedCategories

        // Unfreeze all frozen todo items when coming back from holiday if status changed
        if !isOnHoliday && currentUser.isOnHoliday {
            do {
                let todoItemService = TodoItemService(modelContext: context)
                let items = try todoItemService.fetchByOwnerId(currentUser.uid)
                for item in items {
                    if item.isFrozen {
                        item.unfreeze(currentUser: currentUser)
                    }
                }
            } catch {
                logger.error("Failed to unfreeze todo items: \(error.localizedDescription)")
            }
        }
        currentUser.isOnHoliday = isOnHoliday
        currentUser.holidayStartDate = holidayStartDate

        currentUser.dirty = true

        do {
            try context.save()
            
            try auth?.updateUser()

            // Update sharing status on all entities
            if let sharingService = self.sharingService {
                let updatedCount = sharingService.updateEntitySharingStatus(for: currentUser)
                logger.info("Updated sharing status for \(updatedCount) entities")

                showToast(
                    message: NSLocalizedString(
                        "Sharing preferences updated",
                        comment: "Success message for updating sharing preferences"))
            } else {
                logger.error("Sharing service not initialized")
                showToast(
                    message: NSLocalizedString(
                        "Sharing preferences updated but entity sharing status not updated",
                        comment: "Partial success message for updating sharing preferences"))
            }
        } catch {
            logger.error("Failed to update sharing preferences: \(error.localizedDescription)")
            showToast(
                message: NSLocalizedString(
                    "Failed to update preferences",
                    comment: "Error message for updating sharing preferences"))
        }
    }

    func updateHolidayStatus(isOnHoliday: Bool) {
        let oldValue = self.isOnHoliday
        self.isOnHoliday = isOnHoliday

        if isOnHoliday && !oldValue {
            holidayStartDate = Date()
        } else if !isOnHoliday {
            holidayStartDate = nil
        }
    }

    private func showToast(message: String) {
        let toast = ToastMessage(id: UUID(), message: message, undoAction: nil)
        toastMessages.append(toast)
    }
}
