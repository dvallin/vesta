import Foundation
import SwiftData

class TodoItemCategoryService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchOrCreate(named name: String) -> TodoItemCategory? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }

        let fetchDescriptor = FetchDescriptor<TodoItemCategory>(
            predicate: #Predicate { item in item.name == trimmedName },
            sortBy: []
        )

        if let existingCategory = try? modelContext.fetch(fetchDescriptor).first {
            return existingCategory
        } else {
            let newCategory = TodoItemCategory(name: trimmedName)
            modelContext.insert(newCategory)
            return newCategory
        }
    }

    func fetchAllCategories() -> [TodoItemCategory] {
        let fetchDescriptor = FetchDescriptor<TodoItemCategory>(
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(fetchDescriptor)) ?? []
    }

    func findMatchingCategories(startingWith prefix: String) -> [TodoItemCategory] {
        let trimmedPrefix = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        let fetchDescriptor = FetchDescriptor<TodoItemCategory>(
            predicate: #Predicate { item in
                item.name.starts(with: trimmedPrefix)
            },
            sortBy: []
        )

        return (try? modelContext.fetch(fetchDescriptor)) ?? []
    }
}
