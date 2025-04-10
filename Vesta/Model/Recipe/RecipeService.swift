import Foundation
import SwiftData

class RecipeService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Fetch a recipe by its unique identifier
    func fetchUnique(withUID uid: String) throws -> Recipe? {
        let descriptor = FetchDescriptor<Recipe>(predicate: #Predicate<Recipe> { $0.uid == uid })
        let recipes = try modelContext.fetch(descriptor)
        return recipes.first
    }
}
