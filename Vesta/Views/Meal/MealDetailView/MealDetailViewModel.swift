import SwiftData
import SwiftUI

class MealDetailViewModel: ObservableObject {
    private var auth: UserAuthService?
    private var dismiss: DismissAction?
    private var modelContext: ModelContext?

    @Published var meal: Meal

    init(meal: Meal) {
        self.meal = meal
    }

    func configureEnvironment(
        _ context: ModelContext, _ dismiss: DismissAction, _ auth: UserAuthService
    ) {
        self.modelContext = context
        self.auth = auth
        self.dismiss = dismiss
    }

    func save() {
        do {
            try modelContext?.save()
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)

            dismiss?()

            guard let item = meal.todoItem else { return }
            NotificationManager.shared.scheduleNotification(for: item)
        } catch {
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .error)
        }
    }

    @MainActor
    func cancel() {
        modelContext?.rollback()
        dismiss?()
    }

    func updateTodoItemDueDate(for mealType: MealType) {
        guard let currentUser = auth?.currentUser else { return }
        meal.updateTodoItemDueDate(for: mealType, currentUser: currentUser)
    }

    func setMealType(_ mealType: MealType) {
        guard let currentUser = auth?.currentUser else { return }
        meal.setMealType(mealType, currentUser: currentUser)
    }

    func removeDueDate() {
        guard let currentUser = auth?.currentUser else { return }
        meal.removeDueDate(currentUser: currentUser)
    }
}
