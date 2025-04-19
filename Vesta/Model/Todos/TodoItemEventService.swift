import Foundation
import SwiftData

class TodoItemEventService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Fetch a todo item by its unique identifier
    func fetchUnique(withUID uid: String) throws -> TodoItemEvent? {
        let descriptor = FetchDescriptor<TodoItemEvent>(
            predicate: #Predicate<TodoItemEvent> { $0.uid == uid })
        let items = try modelContext.fetch(descriptor)
        return items.first
    }

    /// Fetch multiple shopping list items by their UIDs
    func fetchMany(withUIDs uids: [String]) throws -> [TodoItemEvent] {
        let descriptor = FetchDescriptor<TodoItemEvent>(
            predicate: #Predicate<TodoItemEvent> { uids.contains($0.uid ?? "") }
        )
        return try modelContext.fetch(descriptor)
    }
}
