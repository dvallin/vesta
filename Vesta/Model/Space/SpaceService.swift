import Foundation
import SwiftData

class SpaceService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Fetch a space by its unique identifier
    func fetchUnique(withUID uid: String) throws -> Space? {
        let descriptor = FetchDescriptor<Space>(predicate: #Predicate<Space> { $0.uid == uid })
        let spaces = try modelContext.fetch(descriptor)
        return spaces.first
    }

    /// Fetch a space by its unique identifier
    func fetchMany(withUIDs uids: [String]) throws -> [Space] {
        let descriptor = FetchDescriptor<Space>(
            predicate: #Predicate<Space> {
                uids.contains($0.uid ?? "")
            })
        return try modelContext.fetch(descriptor)
    }
}
