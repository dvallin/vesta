import Foundation
import SwiftData
import SwiftUI

class CategoryManagementViewModel: ObservableObject {
    var modelContext: ModelContext?

    // UI State
    @Published var categoryToEdit: TodoItemCategory?
    @Published var newCategoryName: String = ""
    @Published var showingEditAlert = false
    @Published var showingDeleteAlert = false
    @Published var showingCannotDeleteAlert = false
    @Published var categoryToDelete: TodoItemCategory?

    func configureContext(
        _ context: ModelContext
    ) {
        self.modelContext = context
    }

    func editCategory(_ category: TodoItemCategory, newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        category.name = trimmedName

        if let context = modelContext {
            saveContext(context)
        }
    }

    func deleteCategory(_ category: TodoItemCategory) {
        guard let context = modelContext else { return }
        context.delete(category)
        saveContext(context)
    }

    func deleteCategories(categories: [TodoItemCategory], at offsets: IndexSet) {
        guard let context = modelContext else { return }
        for index in offsets {
            let category = categories[index]
            if canDeleteCategory(category) {
                context.delete(category)
            }
        }

        saveContext(context)
    }

    func showCannotDeleteAlert(category: TodoItemCategory) {
        // Set the categoryToDelete for reference but show can't delete alert instead
        self.categoryToDelete = category
        self.showingCannotDeleteAlert = true
    }

    func canDeleteCategory(_ category: TodoItemCategory) -> Bool {
        return category.todoItems.isEmpty
    }

    func toggleFreezable(category: TodoItemCategory, isFreezable: Bool) {
        guard let context = modelContext else { return }
        category.isFreezable = isFreezable
        saveContext(context)
    }

    private func saveContext(_ context: ModelContext) {
        do {
            try context.save()
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)
        } catch {
            print("Failed to save context: \(error)")
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .error)
        }
    }
}
