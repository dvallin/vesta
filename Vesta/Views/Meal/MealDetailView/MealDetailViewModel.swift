import SwiftData
import SwiftUI

class MealDetailViewModel: ObservableObject {
    private var userService: UserService?
    private var modelContext: ModelContext?

    @Published var meal: Meal

    init(meal: Meal) {
        self.meal = meal
    }

    func configureEnvironment(_ context: ModelContext, _ userService: UserService) {
        self.modelContext = context
        self.userService = userService
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
        guard let currentUser = userService?.currentUser else { return }
        meal.updateTodoItemDueDate(for: mealType, currentUser: currentUser)
    }
}
