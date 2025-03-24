import Foundation
import SwiftData

class TodoItemCategoryService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchOrCreate(named name: String) -> TodoItemCategory? {
        guard !name.isEmpty else { return nil }

        let fetchDescriptor = FetchDescriptor<TodoItemCategory>(
            predicate: #Predicate { item in item.name == name },
            sortBy: []
        )

        if let existingCategory = try? modelContext.fetch(fetchDescriptor).first {
            return existingCategory
        } else {
            let newCategory = TodoItemCategory(name: name)
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
        let fetchDescriptor = FetchDescriptor<TodoItemCategory>(
            predicate: #Predicate { item in
                item.name.starts(with: prefix)
            },
            sortBy: []
        )

        return (try? modelContext.fetch(fetchDescriptor)) ?? []
    }
}
