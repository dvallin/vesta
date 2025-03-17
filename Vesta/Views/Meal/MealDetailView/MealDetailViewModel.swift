import SwiftData
import SwiftUI

class MealDetailViewModel: ObservableObject {
    private var modelContext: ModelContext?

    @Published var meal: Meal

    init(meal: Meal) {
        self.meal = meal
    }

    func configureEnvironment(_ context: ModelContext) {
        self.modelContext = context
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
        meal.updateTodoItemDueDate(for: mealType)
    }
}
