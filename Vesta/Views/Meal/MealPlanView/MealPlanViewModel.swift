import SwiftData
import SwiftUI

class MealPlanViewModel: ObservableObject {
    private var auth: UserAuthService?
    private var modelContext: ModelContext?

    @Published var selectedMeal: Meal?
    @Published var isPresentingAddMealView = false
    @Published var isPresentingRecipeListView = false
    @Published var isPresentingShoppingListGenerator = false
    @Published var toastMessages: [ToastMessage] = []

    func configureContext(_ context: ModelContext, _ auth: UserAuthService) {
        self.modelContext = context
        self.auth = auth
    }

    func activeMeals(from meals: [Meal]) -> [Meal] {
        return meals.filter { !$0.isDone }
    }

    func sortedMeals(from meals: [Meal]) -> [Meal] {
        return meals.sorted {
            let dateA = $0.todoItem?.dueDate ?? Date.distantFuture
            let dateB = $1.todoItem?.dueDate ?? Date.distantFuture
            if dateA != dateB {
                return dateA < dateB
            }
            let titleA = $0.recipe?.title ?? ""
            let titleB = $1.recipe?.title ?? ""
            return titleA.localizedCaseInsensitiveCompare(titleB) == .orderedAscending
        }
    }

    func activeSortedMeals(from meals: [Meal]) -> [Meal] {
        return sortedMeals(from: activeMeals(from: meals))
    }

    func selectMeal(_ meal: Meal) {
        selectedMeal = meal
    }

    func nextUpcomingMeal(meals: [Meal]) -> Meal? {
        let now = Date()
        return meals.filter { meal in
            guard let dueDate = meal.todoItem?.dueDate else { return false }
            return dueDate > now
        }.min { a, b in
            guard let dateA = a.todoItem?.dueDate, let dateB = b.todoItem?.dueDate else {
                return false
            }
            return dateA < dateB
        }
    }

    func presentAddMealView() {
        HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        isPresentingAddMealView = true
    }

    func deleteMeal(_ meal: Meal, undoAction: @escaping (Meal, UUID) -> Void) {
        if let todoItem = meal.todoItem {
            NotificationManager.shared.cancelNotification(for: todoItem)
        }
        meal.deletedAt = Date()
        meal.todoItem?.deletedAt = meal.deletedAt

        if saveContext() {
            HapticFeedbackManager.shared.generateImpactFeedback(style: .heavy)

            let id = UUID()
            let toastMessage = ToastMessage(
                id: id,
                message: String(
                    format: NSLocalizedString(
                        "%@ deleted", comment: "Toast message for deleting meal"),
                    meal.recipe?.title ?? "Meal"
                ),
                undoAction: {
                    undoAction(meal, id)
                }
            )
            toastMessages.append(toastMessage)
        }
    }

    func markMealAsDone(_ meal: Meal) {
        guard let currentUser = auth?.currentUser,
            let todoItem = meal.todoItem
        else { return }

        todoItem.markAsDone(currentUser: currentUser)

        if saveContext() {
            NotificationManager.shared.scheduleNotification(for: todoItem)
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)

            let id = UUID()
            let toastMessage = ToastMessage(
                id: id,
                message: String(
                    format: NSLocalizedString(
                        "%@ marked as done", comment: "Toast message for marking meal as done"),
                    meal.recipe?.title ?? "Meal"
                ),
                undoAction: { [weak self] in
                    self?.undoMealCompletion(meal, id: id)
                }
            )
            toastMessages.append(toastMessage)
        }
    }

    func undoMealDeletion(_ meal: Meal, id: UUID) {
        // Undo deletion
        meal.deletedAt = nil
        meal.todoItem?.deletedAt = nil
        if let todoItem = meal.todoItem {
            NotificationManager.shared.scheduleNotification(for: todoItem)
        }

        toastMessages.removeAll { $0.id == id }

        if saveContext() {
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }
    }

    func undoMealCompletion(_ meal: Meal, id: UUID) {
        // Undo completion
        if let todoItem = meal.todoItem {
            todoItem.undoLastEvent()
            NotificationManager.shared.scheduleNotification(for: todoItem)
        }

        toastMessages.removeAll { $0.id == id }

        if saveContext() {
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }
    }

    private func saveContext() -> Bool {
        do {
            try modelContext?.save()
            return true
        } catch {
            return false
        }
    }
}
