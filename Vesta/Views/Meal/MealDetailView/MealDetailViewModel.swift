import SwiftData
import SwiftUI

class MealDetailViewModel: ObservableObject {
    private var userManager: UserManager?
    private var modelContext: ModelContext?

    @Published var meal: Meal

    init(meal: Meal) {
        self.meal = meal
    }

    func configureEnvironment(_ context: ModelContext, _ userManager: UserManager) {
        self.modelContext = context
        self.userManager = userManager
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
        guard let currentUser = userManager?.currentUser else { return }
        meal.updateTodoItemDueDate(for: mealType, currentUser: currentUser)
    }
}
