import Foundation
import SwiftData

class MealService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Fetch a meal by its unique identifier
    func fetchUnique(withUID uid: String) throws -> Meal? {
        let descriptor = FetchDescriptor<Meal>(predicate: #Predicate<Meal> { $0.uid == uid })
        let meals = try modelContext.fetch(descriptor)
        return meals.first
    }

    /// Fetch a meal by its unique identifier
    func fetchMany(withUIDs uids: [String]) throws -> [Meal] {
        let descriptor = FetchDescriptor<Meal>(
            predicate: #Predicate<Meal> {
                uids.contains($0.uid ?? "")
            })
        return try modelContext.fetch(descriptor)
    }
}
