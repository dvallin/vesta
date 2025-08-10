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
    private let userAuth: UserAuthService
    private let syncService: SyncService
    private let logger = Logger(subsystem: "com.app.Vesta", category: "Cleanup")

    /// Default threshold for cleaning up deleted entities (30 days)
    /// Note: This matches the TTL set in Firestore via expireAt field
    let defaultCleanupThreshold: TimeInterval = 30 * 24 * 60 * 60  // 30 days in seconds

    /// Threshold for auto-soft-deleting completed todo items (90 days)
    private let completedTodoThreshold: TimeInterval = 90 * 24 * 60 * 60  // 90 days in seconds

    /// Timer for periodic cleanup
    private var cleanupTimer: Timer?

    /// Cleanup interval (24 hours by default)
    private let cleanupInterval: TimeInterval = 24 * 60 * 60  // 24 hours in seconds

    init(modelContext: ModelContext, userAuth: UserAuthService, syncService: SyncService) {
        self.modelContext = modelContext
        self.userAuth = userAuth
        self.syncService = syncService
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
    /// - Returns: The total number of entities that were hard deleted and soft deleted
    @MainActor
    func performCleanup(customThreshold: TimeInterval? = nil) async -> Int {
        let threshold = customThreshold ?? defaultCleanupThreshold
        let cutoffDate = Date().addingTimeInterval(-threshold)

        logger.info("Starting cleanup of entities deleted before \(cutoffDate)")

        var totalDeleted = 0
        var totalSoftDeleted = 0

        // First, auto-soft-delete completed todo items after 90 days
        totalSoftDeleted += await autoSoftDeleteCompletedTodos()

        // Then clean up each type of syncable entity (hard delete after 30 days)
        // Note: Firestore cleanup will happen automatically via TTL on expireAt field
        totalDeleted += await cleanupEntities(of: Meal.self, deletedBefore: cutoffDate)
        totalDeleted += await cleanupEntities(of: Recipe.self, deletedBefore: cutoffDate)
        totalDeleted += await cleanupEntities(of: TodoItem.self, deletedBefore: cutoffDate)
        totalDeleted += await cleanupEntities(of: ShoppingListItem.self, deletedBefore: cutoffDate)
        totalDeleted += await cleanupEntities(of: User.self, deletedBefore: cutoffDate)

        // Save changes if any deletions occurred
        if totalDeleted > 0 || totalSoftDeleted > 0 {
            do {
                try modelContext.save()
                logger.info(
                    "Successfully completed local cleanup. Hard deleted \(totalDeleted) entities, soft deleted \(totalSoftDeleted) completed todos. Firestore cleanup handled automatically via TTL."
                )
            } catch {
                logger.error("Failed to save cleanup changes: \(error.localizedDescription)")
            }
        } else {
            logger.info("No entities found for local cleanup")
        }

        return totalDeleted + totalSoftDeleted
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
    /// Cleanup entities of a specific type that have been soft-deleted for longer than the threshold
    /// This only handles local SwiftData cleanup - Firestore cleanup is automatic via TTL
    /// - Parameters:
    ///   - type: The entity type to clean up
    ///   - cutoffDate: The cutoff date for deletion
    /// - Returns: The number of entities that were deleted
    private func cleanupEntities<T: PersistentModel & SyncableEntity>(
        of type: T.Type,
        deletedBefore cutoffDate: Date
    ) async -> Int {
        do {
            // Fetch entities that have been soft-deleted and have expired
            let descriptor = FetchDescriptor<T>(
                predicate: #Predicate<T> { entity in
                    entity.deletedAt != nil && entity.expireAt != nil
                }
            )

            let deletedEntities = try modelContext.fetch(descriptor)

            // Filter entities that have expired (expireAt is in the past)
            let now = Date()
            let entitiesToDelete = deletedEntities.filter { entity in
                guard let expireAt = entity.expireAt else { return false }
                return expireAt < now
            }

            let count = entitiesToDelete.count

            if count > 0 {
                logger.debug(
                    "Found \(count) expired \(String(describing: type)) entities to hard delete locally"
                )

                for entity in entitiesToDelete {
                    modelContext.delete(entity)
                }

                try modelContext.save()
                _ = syncService.pushLocalChanges()

                logger.debug(
                    "Hard deleted \(count) \(String(describing: type)) entities from local storage")
            }

            return count
        } catch {
            logger.error(
                "Error cleaning up \(String(describing: type)) entities: \(error.localizedDescription)"
            )
            return 0
        }
    }

    /// Auto-soft-delete completed todo items that have been completed for more than 90 days
    /// - Returns: The number of todo items that were soft deleted
    private func autoSoftDeleteCompletedTodos() async -> Int {
        do {
            let cutoffDate = Date().addingTimeInterval(-completedTodoThreshold)

            // Get current user from auth service for performing the soft delete operation
            guard let currentUser = userAuth.currentUser else {
                logger.warning("No current user available for auto-soft-delete operation")
                return 0
            }

            // Fetch completed todos that are not already soft deleted
            let descriptor = FetchDescriptor<TodoItem>(
                predicate: #Predicate<TodoItem> { todo in
                    todo.isCompleted && todo.deletedAt == nil
                }
            )

            let completedTodos = try modelContext.fetch(descriptor)

            // Filter todos that have been completed for more than 90 days
            var todosToSoftDelete: [TodoItem] = []

            for todo in completedTodos {
                let recentCompletionEvents = todo.events.filter { event in
                    event.eventType == .completed && event.completedAt >= cutoffDate
                }
                if recentCompletionEvents.isEmpty {
                    todosToSoftDelete.append(todo)
                }
            }

            let count = todosToSoftDelete.count

            if count > 0 {
                logger.debug("Found \(count) completed TodoItems to auto-soft-delete")

                for todo in todosToSoftDelete {
                    todo.softDelete(currentUser: currentUser)
                }

                try modelContext.save()
                _ = syncService.pushLocalChanges()

                logger.debug("Auto-soft-deleted \(count) completed TodoItems")
            }

            return count
        } catch {
            logger.error("Error auto-soft-deleting completed todos: \(error.localizedDescription)")
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
            if await restoreItemInternal(uid: uid, currentUser: currentUser) {
                restoredCount += 1
            }
        }

        if restoredCount > 0 {
            do {
                try modelContext.save()
                _ = syncService.pushLocalChanges()
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
            if await hardDeleteItemInternal(uid: uid) {
                deletedCount += 1
            }
        }

        if deletedCount > 0 {
            do {
                try modelContext.save()
                _ = syncService.pushLocalChanges()
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
    func restoreItem(uid: String, currentUser: User) async -> Bool {
        let result = await restoreItemInternal(uid: uid, currentUser: currentUser)
        if result {
            do {
                try modelContext.save()
                _ = syncService.pushLocalChanges()
            } catch {
                logger.error("Failed to save restore changes: \(error.localizedDescription)")
                return false
            }
        }
        return result
    }

    /// Internal restore method that doesn't save/sync - used by bulk operations
    /// - Parameters:
    ///   - uid: The UID of the item to restore
    ///   - currentUser: The user performing the restore operation
    /// - Returns: True if the item was found and restored, false otherwise
    @MainActor
    private func restoreItemInternal(uid: String, currentUser: User) async -> Bool {
        // Try to find and restore the item in each entity type
        if await restoreEntityInternal(of: Meal.self, uid: uid, currentUser: currentUser) {
            return true
        }
        if await restoreEntityInternal(of: Recipe.self, uid: uid, currentUser: currentUser) {
            return true
        }
        if await restoreEntityInternal(of: TodoItem.self, uid: uid, currentUser: currentUser) {
            return true
        }
        if await restoreEntityInternal(
            of: ShoppingListItem.self, uid: uid, currentUser: currentUser)
        {
            return true
        }
        if await restoreEntityInternal(of: User.self, uid: uid, currentUser: currentUser) {
            return true
        }

        logger.warning("Item with UID \(uid) not found for restore")
        return false
    }

    /// Hard delete a single item by its UID
    /// - Parameter uid: The UID of the item to permanently delete
    /// - Returns: True if the item was found and deleted, false otherwise
    @MainActor
    func hardDeleteItem(uid: String) async -> Bool {
        let result = await hardDeleteItemInternal(uid: uid)
        if result {
            do {
                try modelContext.save()
                _ = syncService.pushLocalChanges()
            } catch {
                logger.error("Failed to save hard delete changes: \(error.localizedDescription)")
                return false
            }
        }
        return result
    }

    /// Internal hard delete method that doesn't save/sync - used by bulk operations
    /// - Parameter uid: The UID of the item to permanently delete
    /// - Returns: True if the item was found and deleted, false otherwise
    @MainActor
    private func hardDeleteItemInternal(uid: String) async -> Bool {
        // Try to find and delete the item in each entity type
        if await hardDeleteEntityInternal(of: Meal.self, uid: uid) { return true }
        if await hardDeleteEntityInternal(of: Recipe.self, uid: uid) { return true }
        if await hardDeleteEntityInternal(of: TodoItem.self, uid: uid) { return true }
        if await hardDeleteEntityInternal(of: ShoppingListItem.self, uid: uid) { return true }
        if await hardDeleteEntityInternal(of: User.self, uid: uid) { return true }

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
        let result = await restoreEntityInternal(of: type, uid: uid, currentUser: currentUser)
        if result {
            do {
                try modelContext.save()
                _ = syncService.pushLocalChanges()
            } catch {
                logger.error("Failed to save restore changes: \(error.localizedDescription)")
                return false
            }
        }
        return result
    }

    private func restoreEntityInternal<T: PersistentModel & SyncableEntity>(
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
        let result = await hardDeleteEntityInternal(of: type, uid: uid)
        if result {
            do {
                try modelContext.save()
                _ = syncService.pushLocalChanges()
            } catch {
                logger.error("Failed to save hard delete changes: \(error.localizedDescription)")
                return false
            }
        }
        return result
    }

    private func hardDeleteEntityInternal<T: PersistentModel & SyncableEntity>(
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
