import Foundation
import SwiftData

class TodoItemService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Fetch a todo item by its unique identifier
    func fetchUnique(withUID uid: String) throws -> TodoItem? {
        let descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate<TodoItem> { $0.uid == uid })
        let items = try modelContext.fetch(descriptor)
        return items.first
    }

    /// Fetch all todo items owned by a specific user
    func fetchByOwnerId(_ ownerId: String) throws -> [TodoItem] {
        let descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate<TodoItem> { item in
                item.owner?.uid == ownerId
            }
        )
        return try modelContext.fetch(descriptor)
    }
}
