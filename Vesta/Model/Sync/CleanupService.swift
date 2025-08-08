import Foundation
import SwiftData
import os

/// Represents a soft-deleted item in the trash bin
struct SoftDeletedItem: Identifiable {
    let id = UUID()
    let uid: String
    let entityType: String
    let displayName: String
    let deletedAt: Date
    let daysUntilCleanup: Int
    let isEligibleForCleanup: Bool

    init<T: SyncableEntity>(entity: T, cleanupThreshold: TimeInterval) {
        self.uid = entity.uid
        self.entityType = String(describing: type(of: entity))
        self.deletedAt = entity.deletedAt ?? Date()

        let daysSinceDeleted = Int(-self.deletedAt.timeIntervalSinceNow / (24 * 60 * 60))
        let thresholdDays = Int(cleanupThreshold / (24 * 60 * 60))
        self.daysUntilCleanup = max(0, thresholdDays - daysSinceDeleted)
        self.isEligibleForCleanup = daysSinceDeleted >= thresholdDays

        // Set display name based on entity type
        switch entity {
        case let meal as Meal:
            if let recipe = meal.recipe {
                self.displayName = "\(recipe.title) (\(meal.mealType.displayName))"
            } else {
                self.displayName = "Meal (\(meal.mealType.displayName))"
            }
        case let recipe as Recipe:
            self.displayName = recipe.title
        case let todoItem as TodoItem:
            self.displayName = todoItem.title
        case let shoppingItem as ShoppingListItem:
            self.displayName = shoppingItem.name
        case let user as User:
            self.displayName = user.displayName ?? user.email ?? "Unknown User"
        default:
            self.displayName = "Unknown Item"
        }
    }
}

/// Service responsible for cleaning up soft-deleted entities that are older than a specified threshold.
/// Performs hard deletion of entities that have been soft-deleted for an extended period.
class CleanupService: ObservableObject {
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.app.Vesta", category: "Cleanup")

    /// Default threshold for cleaning up deleted entities (3 months)
    private let defaultCleanupThreshold: TimeInterval = 90 * 24 * 60 * 60  // 90 days in seconds

    /// Timer for periodic cleanup
    private var cleanupTimer: Timer?

    /// Cleanup interval (24 hours by default)
    private let cleanupInterval: TimeInterval = 24 * 60 * 60  // 24 hours in seconds

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// Start automatic periodic cleanup
    func startPeriodicCleanup() {
        logger.info("Starting periodic cleanup service")

        // Stop any existing timer
        stopPeriodicCleanup()

        // Schedule periodic cleanup
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: cleanupInterval, repeats: true) {
            [weak self] _ in
            Task {
                await self?.performCleanup()
            }
        }

        // Perform initial cleanup
        Task {
            await performCleanup()
        }
    }

    /// Stop automatic periodic cleanup
    func stopPeriodicCleanup() {
        logger.info("Stopping periodic cleanup service")
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }

    /// Perform a manual cleanup operation
    /// - Parameter customThreshold: Optional custom threshold for deletion. If nil, uses default threshold
    /// - Returns: The total number of entities that were hard deleted
    @MainActor
    func performCleanup(customThreshold: TimeInterval? = nil) async -> Int {
        let threshold = customThreshold ?? defaultCleanupThreshold
        let cutoffDate = Date().addingTimeInterval(-threshold)

        logger.info("Starting cleanup of entities deleted before \(cutoffDate)")

        var totalDeleted = 0

        // Clean up each type of syncable entity
        totalDeleted += await cleanupEntities(of: Meal.self, deletedBefore: cutoffDate)
        totalDeleted += await cleanupEntities(of: Recipe.self, deletedBefore: cutoffDate)
        totalDeleted += await cleanupEntities(of: TodoItem.self, deletedBefore: cutoffDate)
        totalDeleted += await cleanupEntities(of: ShoppingListItem.self, deletedBefore: cutoffDate)
        totalDeleted += await cleanupEntities(of: User.self, deletedBefore: cutoffDate)

        // Save changes if any deletions occurred
        if totalDeleted > 0 {
            do {
                try modelContext.save()
                logger.info("Successfully completed cleanup. Hard deleted \(totalDeleted) entities")
            } catch {
                logger.error("Failed to save cleanup changes: \(error.localizedDescription)")
            }
        } else {
            logger.info("No entities found for cleanup")
        }

        return totalDeleted
    }

    /// Get count of entities that would be cleaned up without actually deleting them
    /// - Parameter customThreshold: Optional custom threshold for deletion. If nil, uses default threshold
    /// - Returns: Dictionary with entity type names as keys and counts as values
    @MainActor
    func getCleanupCandidateCount(customThreshold: TimeInterval? = nil) async -> [String: Int] {
        let threshold = customThreshold ?? defaultCleanupThreshold
        let cutoffDate = Date().addingTimeInterval(-threshold)

        var counts: [String: Int] = [:]

        counts["Meal"] = await getEntityCount(of: Meal.self, deletedBefore: cutoffDate)
        counts["Recipe"] = await getEntityCount(of: Recipe.self, deletedBefore: cutoffDate)
        counts["TodoItem"] = await getEntityCount(of: TodoItem.self, deletedBefore: cutoffDate)
        counts["ShoppingListItem"] = await getEntityCount(
            of: ShoppingListItem.self, deletedBefore: cutoffDate)
        counts["User"] = await getEntityCount(of: User.self, deletedBefore: cutoffDate)

        return counts
    }

    /// Get count of recently soft-deleted entities that are not yet eligible for cleanup
    /// - Parameter customThreshold: Optional custom threshold for deletion. If nil, uses default threshold
    /// - Returns: Dictionary with entity type names as keys and counts as values
    @MainActor
    func getRecentlySoftDeletedCount(customThreshold: TimeInterval? = nil) async -> [String: Int] {
        let threshold = customThreshold ?? defaultCleanupThreshold
        let cutoffDate = Date().addingTimeInterval(-threshold)

        var counts: [String: Int] = [:]

        counts["Meal"] = await getEntityCount(of: Meal.self, deletedAfter: cutoffDate)
        counts["Recipe"] = await getEntityCount(of: Recipe.self, deletedAfter: cutoffDate)
        counts["TodoItem"] = await getEntityCount(of: TodoItem.self, deletedAfter: cutoffDate)
        counts["ShoppingListItem"] = await getEntityCount(
            of: ShoppingListItem.self, deletedAfter: cutoffDate)
        counts["User"] = await getEntityCount(of: User.self, deletedAfter: cutoffDate)

        return counts
    }

    /// Get all soft-deleted items (both eligible for cleanup and recently deleted)
    /// - Parameter customThreshold: Optional custom threshold for deletion. If nil, uses default threshold
    /// - Returns: Array of SoftDeletedItem objects
    @MainActor
    func getAllSoftDeletedItems(customThreshold: TimeInterval? = nil) async -> [SoftDeletedItem] {
        let threshold = customThreshold ?? defaultCleanupThreshold
        var items: [SoftDeletedItem] = []

        items += await getSoftDeletedItems(of: Meal.self, cleanupThreshold: threshold)
        items += await getSoftDeletedItems(of: Recipe.self, cleanupThreshold: threshold)
        items += await getSoftDeletedItems(of: TodoItem.self, cleanupThreshold: threshold)
        items += await getSoftDeletedItems(of: ShoppingListItem.self, cleanupThreshold: threshold)
        items += await getSoftDeletedItems(of: User.self, cleanupThreshold: threshold)

        // Sort by deletion date (newest first)
        return items.sorted { $0.deletedAt > $1.deletedAt }
    }

    // MARK: - Private Methods

    /// Clean up entities of a specific type that were deleted before the cutoff date
    /// - Parameters:
    ///   - type: The entity type to clean up
    ///   - cutoffDate: The cutoff date for deletion
    /// - Returns: The number of entities that were deleted
    private func cleanupEntities<T: PersistentModel & SyncableEntity>(
        of type: T.Type,
        deletedBefore cutoffDate: Date
    ) async -> Int {
        do {
            // First, fetch all entities that have deletedAt set (not nil)
            let descriptor = FetchDescriptor<T>(
                predicate: #Predicate<T> { entity in
                    entity.deletedAt != nil
                }
            )

            let deletedEntities = try modelContext.fetch(descriptor)

            // Filter in Swift to find entities deleted before the cutoff date
            let entitiesToDelete = deletedEntities.filter { entity in
                guard let deletedAt = entity.deletedAt else { return false }
                return deletedAt < cutoffDate
            }

            let count = entitiesToDelete.count

            if count > 0 {
                logger.debug("Found \(count) \(String(describing: type)) entities to hard delete")

                for entity in entitiesToDelete {
                    modelContext.delete(entity)
                }

                logger.debug("Hard deleted \(count) \(String(describing: type)) entities")
            }

            return count
        } catch {
            logger.error(
                "Error cleaning up \(String(describing: type)) entities: \(error.localizedDescription)"
            )
            return 0
        }
    }

    /// Get soft-deleted items of a specific type
    /// - Parameters:
    ///   - type: The entity type to fetch
    ///   - cleanupThreshold: The cleanup threshold in seconds
    /// - Returns: Array of SoftDeletedItem objects for the specified type
    private func getSoftDeletedItems<T: PersistentModel & SyncableEntity>(
        of type: T.Type,
        cleanupThreshold: TimeInterval
    ) async -> [SoftDeletedItem] {
        do {
            let descriptor = FetchDescriptor<T>(
                predicate: #Predicate<T> { entity in
                    entity.deletedAt != nil
                }
            )

            let deletedEntities = try modelContext.fetch(descriptor)

            return deletedEntities.map { entity in
                SoftDeletedItem(entity: entity, cleanupThreshold: cleanupThreshold)
            }
        } catch {
            logger.error(
                "Error fetching soft-deleted \(String(describing: type)) items: \(error.localizedDescription)"
            )
            return []
        }
    }

    /// Get count of entities of a specific type that would be cleaned up (deleted before cutoff)
    /// - Parameters:
    ///   - type: The entity type to count
    ///   - cutoffDate: The cutoff date for deletion
    /// - Returns: The number of entities that would be deleted
    private func getEntityCount<T: PersistentModel & SyncableEntity>(
        of type: T.Type,
        deletedBefore cutoffDate: Date
    ) async -> Int {
        do {
            // First, fetch all entities that have deletedAt set (not nil)
            let descriptor = FetchDescriptor<T>(
                predicate: #Predicate<T> { entity in
                    entity.deletedAt != nil
                }
            )

            let deletedEntities = try modelContext.fetch(descriptor)

            // Filter in Swift to find entities deleted before the cutoff date
            let entitiesForCleanup = deletedEntities.filter { entity in
                guard let deletedAt = entity.deletedAt else { return false }
                return deletedAt < cutoffDate
            }

            return entitiesForCleanup.count
        } catch {
            logger.error(
                "Error counting \(String(describing: type)) entities for cleanup: \(error.localizedDescription)"
            )
            return 0
        }
    }

    /// Get count of entities of a specific type that were deleted after a cutoff date (recently deleted)
    /// - Parameters:
    ///   - type: The entity type to count
    ///   - cutoffDate: The cutoff date for deletion
    /// - Returns: The number of recently deleted entities
    private func getEntityCount<T: PersistentModel & SyncableEntity>(
        of type: T.Type,
        deletedAfter cutoffDate: Date
    ) async -> Int {
        do {
            // First, fetch all entities that have deletedAt set (not nil)
            let descriptor = FetchDescriptor<T>(
                predicate: #Predicate<T> { entity in
                    entity.deletedAt != nil
                }
            )

            let deletedEntities = try modelContext.fetch(descriptor)

            // Filter in Swift to find entities deleted after the cutoff date
            let recentlyDeletedEntities = deletedEntities.filter { entity in
                guard let deletedAt = entity.deletedAt else { return false }
                return deletedAt >= cutoffDate
            }

            return recentlyDeletedEntities.count
        } catch {
            logger.error(
                "Error counting recently deleted \(String(describing: type)) entities: \(error.localizedDescription)"
            )
            return 0
        }
    }
}

// MARK: - Convenience Extensions

extension CleanupService {
    /// Convenience method to perform cleanup with a custom threshold in days
    /// - Parameter daysThreshold: Number of days after which deleted entities should be hard deleted
    /// - Returns: The total number of entities that were hard deleted
    @MainActor
    func performCleanup(afterDays daysThreshold: Int) async -> Int {
        let threshold = TimeInterval(daysThreshold * 24 * 60 * 60)
        return await performCleanup(customThreshold: threshold)
    }

    /// Convenience method to get cleanup candidate count with a custom threshold in days
    /// - Parameter daysThreshold: Number of days after which deleted entities should be hard deleted
    /// - Returns: Dictionary with entity type names as keys and counts as values
    @MainActor
    func getCleanupCandidateCount(afterDays daysThreshold: Int) async -> [String: Int] {
        let threshold = TimeInterval(daysThreshold * 24 * 60 * 60)
        return await getCleanupCandidateCount(customThreshold: threshold)
    }

    /// Convenience method to get recently soft-deleted entity count with a custom threshold in days
    /// - Parameter daysThreshold: Number of days after which deleted entities should be hard deleted
    /// - Returns: Dictionary with entity type names as keys and counts as values
    @MainActor
    func getRecentlySoftDeletedCount(afterDays daysThreshold: Int) async -> [String: Int] {
        let threshold = TimeInterval(daysThreshold * 24 * 60 * 60)
        return await getRecentlySoftDeletedCount(customThreshold: threshold)
    }

    /// Convenience method to get all soft-deleted items with a custom threshold in days
    /// - Parameter daysThreshold: Number of days after which deleted entities should be hard deleted
    /// - Returns: Array of SoftDeletedItem objects
    @MainActor
    func getAllSoftDeletedItems(afterDays daysThreshold: Int) async -> [SoftDeletedItem] {
        let threshold = TimeInterval(daysThreshold * 24 * 60 * 60)
        return await getAllSoftDeletedItems(customThreshold: threshold)
    }

    /// Restore multiple items by their UIDs
    /// - Parameters:
    ///   - itemUIDs: Array of UIDs to restore
    ///   - currentUser: The user performing the restore operation
    /// - Returns: The number of items successfully restored
    @MainActor
    func bulkRestore(itemUIDs: [String], currentUser: User) async -> Int {
        var restoredCount = 0

        for uid in itemUIDs {
            if await restoreItem(uid: uid, currentUser: currentUser) {
                restoredCount += 1
            }
        }

        if restoredCount > 0 {
            do {
                try modelContext.save()
                logger.info("Successfully restored \(restoredCount) items")
            } catch {
                logger.error("Failed to save restore changes: \(error.localizedDescription)")
            }
        }

        return restoredCount
    }

    /// Hard delete multiple items by their UIDs
    /// - Parameter itemUIDs: Array of UIDs to permanently delete
    /// - Returns: The number of items successfully deleted
    @MainActor
    func bulkDelete(itemUIDs: [String]) async -> Int {
        var deletedCount = 0

        for uid in itemUIDs {
            if await hardDeleteItem(uid: uid) {
                deletedCount += 1
            }
        }

        if deletedCount > 0 {
            do {
                try modelContext.save()
                logger.info("Successfully hard deleted \(deletedCount) items")
            } catch {
                logger.error("Failed to save hard delete changes: \(error.localizedDescription)")
            }
        }

        return deletedCount
    }

    /// Restore a single item by its UID
    /// - Parameters:
    ///   - uid: The UID of the item to restore
    ///   - currentUser: The user performing the restore operation
    /// - Returns: True if the item was found and restored, false otherwise
    @MainActor
    private func restoreItem(uid: String, currentUser: User) async -> Bool {
        // Try to find and restore the item in each entity type
        if await restoreEntity(of: Meal.self, uid: uid, currentUser: currentUser) { return true }
        if await restoreEntity(of: Recipe.self, uid: uid, currentUser: currentUser) { return true }
        if await restoreEntity(of: TodoItem.self, uid: uid, currentUser: currentUser) {
            return true
        }
        if await restoreEntity(of: ShoppingListItem.self, uid: uid, currentUser: currentUser) {
            return true
        }
        if await restoreEntity(of: User.self, uid: uid, currentUser: currentUser) { return true }

        logger.warning("Item with UID \(uid) not found for restore")
        return false
    }

    /// Hard delete a single item by its UID
    /// - Parameter uid: The UID of the item to permanently delete
    /// - Returns: True if the item was found and deleted, false otherwise
    @MainActor
    private func hardDeleteItem(uid: String) async -> Bool {
        // Try to find and delete the item in each entity type
        if await hardDeleteEntity(of: Meal.self, uid: uid) { return true }
        if await hardDeleteEntity(of: Recipe.self, uid: uid) { return true }
        if await hardDeleteEntity(of: TodoItem.self, uid: uid) { return true }
        if await hardDeleteEntity(of: ShoppingListItem.self, uid: uid) { return true }
        if await hardDeleteEntity(of: User.self, uid: uid) { return true }

        logger.warning("Item with UID \(uid) not found for hard delete")
        return false
    }

    /// Restore an entity of a specific type by its UID
    /// - Parameters:
    ///   - type: The entity type to search
    ///   - uid: The UID of the entity to restore
    ///   - currentUser: The user performing the restore operation
    /// - Returns: True if the entity was found and restored, false otherwise
    private func restoreEntity<T: PersistentModel & SyncableEntity>(
        of type: T.Type, uid: String, currentUser: User
    ) async -> Bool {
        do {
            let descriptor = FetchDescriptor<T>(
                predicate: #Predicate<T> { entity in
                    entity.uid == uid && entity.deletedAt != nil
                }
            )

            let entities = try modelContext.fetch(descriptor)

            if let entity = entities.first {
                entity.restore(currentUser: currentUser)
                logger.debug("Restored \(String(describing: type)) with UID \(uid)")
                return true
            }

            return false
        } catch {
            logger.error(
                "Error restoring \(String(describing: type)) with UID \(uid): \(error.localizedDescription)"
            )
            return false
        }
    }

    /// Hard delete an entity of a specific type by its UID
    /// - Parameters:
    ///   - type: The entity type to search
    ///   - uid: The UID of the entity to delete
    /// - Returns: True if the entity was found and deleted, false otherwise
    private func hardDeleteEntity<T: PersistentModel & SyncableEntity>(
        of type: T.Type, uid: String
    ) async -> Bool {
        do {
            let descriptor = FetchDescriptor<T>(
                predicate: #Predicate<T> { entity in
                    entity.uid == uid && entity.deletedAt != nil
                }
            )

            let entities = try modelContext.fetch(descriptor)

            if let entity = entities.first {
                modelContext.delete(entity)
                logger.debug("Hard deleted \(String(describing: type)) with UID \(uid)")
                return true
            }

            return false
        } catch {
            logger.error(
                "Error hard deleting \(String(describing: type)) with UID \(uid): \(error.localizedDescription)"
            )
            return false
        }
    }
}
