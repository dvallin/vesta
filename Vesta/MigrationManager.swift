import SwiftData
import SwiftUI

struct MigrationManager {

    static func migrateToSyncableEntities(in context: ModelContext, currentUser: User) {
        do {
            try context.save()
        } catch {
            print("Error saving migration changes: \(error)")
        }
    }
}
