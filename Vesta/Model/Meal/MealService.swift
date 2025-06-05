import Foundation
import SwiftData

class MealService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Fetch all meals
    func fetchAll() throws -> [Meal] {
        let descriptor = FetchDescriptor<Meal>()
        return try modelContext.fetch(descriptor)
    }

    /// Fetch a meal by its unique identifier
    func fetchUnique(withUID uid: String) throws -> Meal? {
        let descriptor = FetchDescriptor<Meal>(predicate: #Predicate<Meal> { $0.uid == uid })
        let meals = try modelContext.fetch(descriptor)
        return meals.first
    }

    /// Fetch a meal by its unique identifier
    func fetchMany(withUIDs uids: [String]) throws -> [Meal] {
        // Fetch all users first
        let allMeals = try fetchAll()

        // Then filter in memory to avoid unsupported predicate
        return allMeals.filter { meal in
            guard let uid = meal.uid else { return false }
            return uids.contains(uid)
        }
    }

    /// Fetch all meals owned by a specific user
    func fetchByOwnerId(_ ownerId: String) throws -> [Meal] {
        let descriptor = FetchDescriptor<Meal>(
            predicate: #Predicate<Meal> { meal in
                meal.owner?.uid == ownerId
            }
        )
        return try modelContext.fetch(descriptor)
    }
}
