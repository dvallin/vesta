import Foundation
import SwiftData

class UserService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Fetch all users
    func fetchAll() throws -> [User] {
        let descriptor = FetchDescriptor<User>()
        return try modelContext.fetch(descriptor)
    }

    /// Fetch a user by their unique identifier
    func fetchUnique(withUID uid: String) throws -> User? {
        let descriptor = FetchDescriptor<User>(predicate: #Predicate<User> { $0.uid == uid })
        let users = try modelContext.fetch(descriptor)
        return users.first
    }

    /// Fetch multiple users by their unique identifiers
    func fetchMany(withUIDs uids: [String]) throws -> [User] {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { uids.contains($0.uid) })
        return try modelContext.fetch(descriptor)
    }
}
