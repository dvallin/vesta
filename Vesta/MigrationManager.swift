import SwiftData
import SwiftUI

struct MigrationManager {
    static func fixCategoryNames(using modelContext: ModelContext) {
        let categoryService = TodoItemCategoryService(modelContext: modelContext)
        let categories = categoryService.fetchAllCategories()

        for category in categories {
            let trimmedName = category.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedName != category.name {
                if let trimmedCategory = categoryService.fetchOrCreate(named: trimmedName) {
                    // Move all todo items to the trimmed category
                    for todoItem in category.todoItems {
                        todoItem.category = trimmedCategory
                    }
                    // Delete the original category
                    modelContext.delete(category)
                }
            }
        }

        // Save the context to persist changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context after fixing category names: \(error)")
        }
    }
}
