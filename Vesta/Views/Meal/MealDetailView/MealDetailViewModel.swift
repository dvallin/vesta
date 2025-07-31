import SwiftData
import SwiftUI

class MealDetailViewModel: ObservableObject {
    private var auth: UserAuthService?
    private var modelContext: ModelContext?

    @Published var meal: Meal

    init(meal: Meal) {
        self.meal = meal
    }

    func configureEnvironment(_ context: ModelContext, _ auth: UserAuthService) {
        self.modelContext = context
        self.auth = auth
    }

    func save() {
        do {
            try modelContext?.save()
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)
        } catch {
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .error)
        }
    }

    func updateTodoItemDueDate(for mealType: MealType) {
        guard let currentUser = auth?.currentUser else { return }
        meal.updateTodoItemDueDate(for: mealType, currentUser: currentUser)
    }

    func removeDueDate() {
        guard let currentUser = auth?.currentUser else { return }
        meal.removeDueDate(currentUser: currentUser)
    }
}
