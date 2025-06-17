import Foundation
import OSLog
import SwiftData

class UserEntityProcessor: BaseEntityProcessor, EntityProcessor {
    var users: UserService

    init(modelContext: ModelContext, logger: Logger, users: UserService) {
        self.users = users
        super.init(modelContext: modelContext, logger: logger)
    }

    @MainActor
    func process(entities: [[String: Any]], currentUser: User) async throws {
        self.logger.info("Processing \(entities.count) User entities")

        for data in entities {
            guard let uid = data["uid"] as? String else {
                self.logger.warning("Skipping User entity without UID")
                continue
            }

            // Check if entity exists or create a new one
            let user: User
            if let existingUser = try users.fetchUnique(withUID: uid) {
                user = existingUser
                self.logger.debug("Found existing User with UID: \(uid)")
            } else {
                // For new users, we need just the UID - the rest will be updated
                user = User(uid: uid)
                modelContext.insert(user)
                self.logger.debug("Created new User with UID: \(uid)")
            }

            // Update properties and members
            user.update(from: data)

            if let ownerId = data["ownerId"] as? String {
                if ownerId != user.owner?.uid {
                    if ownerId == uid {
                        user.owner = user
                    } else if let owner = try? users.fetchUnique(withUID: ownerId) {
                        user.owner = owner
                    }
                }
            } else if user.owner != nil {
                user.owner = nil
            }

            // Process friend IDs if available
            if let friendIds = data["friendIds"] as? [String], !friendIds.isEmpty {
                self.logger.debug("Processing \(friendIds.count) friends for user \(uid)")

                // Get current friend IDs for comparison
                let currentFriendIds = Set(user.friends.compactMap { $0.uid })
                // Find new friend IDs that need to be added
                let newFriendIds = Set(friendIds).subtracting(currentFriendIds)

                if !newFriendIds.isEmpty {
                    self.logger.debug("Adding \(newFriendIds.count) new friends to user \(uid)")
                    // Fetch and add new friends
                    if let newFriends = try? users.fetchMany(withUIDs: Array(newFriendIds)) {
                        self.logger.debug("Found \(newFriends.count) in the context")
                        user.friends.append(contentsOf: newFriends)
                    } else {
                        self.logger.debug("Could not find friends in the context")
                    }
                }

                // Remove friends that are no longer in the friend list
                user.friends.removeAll { friend in
                    let shouldRemove = !friendIds.contains(friend.uid)
                    if shouldRemove {
                        self.logger.debug("Removing friend with UID \(friend.uid) from user \(uid)")
                    }
                    return shouldRemove
                }
            } else if !user.friends.isEmpty {
                self.logger.debug("Clearing all friends for user \(uid)")
                user.friends.removeAll()
            }

            user.markAsSynced()
            self.logger.debug("Successfully processed User: \(uid)")
        }
    }
}
