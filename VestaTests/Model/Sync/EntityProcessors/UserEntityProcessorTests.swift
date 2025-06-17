import OSLog
import SwiftData
import XCTest

@testable import Vesta

class UserEntityProcessorTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var processor: UserEntityProcessor!
    var userService: UserService!
    var logger: Logger!
    var currentUser: User!

    override func setUp() async throws {
        container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        context = ModelContext(container)
        logger = Logger(subsystem: "com.vesta.test", category: "UserEntityProcessorTests")
        userService = UserService(modelContext: context)
        processor = UserEntityProcessor(modelContext: context, logger: logger, users: userService)

        // Create a current user for testing
        currentUser = Fixtures.createUser()
        context.insert(currentUser)
        try context.save()
    }

    override func tearDown() async throws {
        container = nil
        context = nil
        processor = nil
        userService = nil
    }

    // MARK: - Tests for New User Creation

    func testProcessNewUser() async throws {
        // Create a new user DTO that doesn't exist in the context yet
        let newUserUid = "test-new-user-123"
        let userData: [String: Any] = [
            "uid": newUserUid,
            "email": "newuser@example.com",
            "displayName": "New Test User",
            "photoURL": "https://example.com/photo.jpg",
            "isEmailVerified": true,
            "createdAt": Date().addingTimeInterval(-7 * 24 * 60 * 60),  // 7 days ago
            "lastSignInAt": Date(),
            "isShared": false,
        ]

        // Process the entity
        try await processor.process(entities: [userData], currentUser: currentUser)

        // Verify the user was created properly
        let fetchedUser = try userService.fetchUnique(withUID: newUserUid)
        XCTAssertNotNil(fetchedUser, "New user should be created in the context")
        XCTAssertEqual(fetchedUser?.email, "newuser@example.com")
        XCTAssertEqual(fetchedUser?.displayName, "New Test User")
        XCTAssertEqual(fetchedUser?.photoURL, "https://example.com/photo.jpg")
        XCTAssertEqual(fetchedUser?.isEmailVerified, true)
        XCTAssertFalse(fetchedUser?.dirty ?? true, "User should be marked as synced")
    }

    func testProcessNewUserWithFriends() async throws {
        // First create some existing users that will be friends
        let friend1 = User(uid: "friend-1", email: "friend1@example.com", displayName: "Friend One")
        let friend2 = User(uid: "friend-2", email: "friend2@example.com", displayName: "Friend Two")
        context.insert(friend1)
        context.insert(friend2)
        try context.save()

        // Print out all users in the context for debugging
        print("All users in context before processing:")
        try userService.fetchAll().forEach { user in
            print(" - User: \(user.uid ?? "nil") email: \(user.email ?? "nil")")
        }

        // Verify the friends can be found with fetchMany before proceeding
        let foundFriends = try userService.fetchMany(withUIDs: ["friend-1", "friend-2"])
        print("Found \(foundFriends.count) friends with fetchMany:")
        foundFriends.forEach { friend in
            print(" - Friend: \(friend.uid ?? "nil") email: \(friend.email ?? "nil")")
        }
        XCTAssertEqual(foundFriends.count, 2, "Should be able to find the friends with fetchMany")

        // Create a new user DTO with friends
        let newUserUid = "test-user-with-friends"
        let userData: [String: Any] = [
            "uid": newUserUid,
            "email": "userwithfriends@example.com",
            "displayName": "User With Friends",
            "isEmailVerified": true,
            "createdAt": Date(),
            "lastSignInAt": Date(),
            "friendIds": ["friend-1", "friend-2"],
            "isShared": false,
        ]

        print("Processing user with friendIds: \(userData["friendIds"] ?? [])")

        // Process the entity
        try await processor.process(entities: [userData], currentUser: currentUser)

        // Verify the user was created with friends
        let fetchedUser = try userService.fetchUnique(withUID: newUserUid)
        XCTAssertNotNil(fetchedUser, "New user should be created")

        print("Fetched user has \(fetchedUser?.friends.count ?? 0) friends")
        if let friends = fetchedUser?.friends {
            for friend in friends {
                print(
                    " - Friend in user.friends: \(friend.uid ?? "nil") email: \(friend.email ?? "nil")"
                )
            }
        }

        XCTAssertEqual(fetchedUser?.friends.count, 2, "User should have 2 friends")

        // Verify the actual friend objects
        let friendUids = fetchedUser?.friends.compactMap { $0.uid } ?? []
        print("Friend UIDs in fetched user: \(friendUids)")
        XCTAssertTrue(friendUids.contains("friend-1"), "Should contain friend-1")
        XCTAssertTrue(friendUids.contains("friend-2"), "Should contain friend-2")
    }

    // MARK: - Tests for Updating Existing Users

    func testUpdateExistingUser() async throws {
        // Create an existing user
        let existingUser = User(
            uid: "existing-user-123",
            email: "oldmail@example.com",
            displayName: "Old Name",
            photoURL: nil,
            isEmailVerified: false
        )
        context.insert(existingUser)
        try context.save()

        // Mark it as synced initially
        existingUser.markAsSynced()

        // Create an updated DTO
        let updatedData: [String: Any] = [
            "uid": "existing-user-123",
            "email": "newmail@example.com",
            "displayName": "Updated Name",
            "photoURL": "https://example.com/new-photo.jpg",
            "isEmailVerified": true,
            "createdAt": Date(),
            "lastSignInAt": Date(),
            "isShared": true,
        ]

        // Process the update
        try await processor.process(entities: [updatedData], currentUser: currentUser)

        // Verify the user was updated
        let fetchedUser = try userService.fetchUnique(withUID: "existing-user-123")
        XCTAssertNotNil(fetchedUser)
        XCTAssertEqual(fetchedUser?.email, "newmail@example.com")
        XCTAssertEqual(fetchedUser?.displayName, "Updated Name")
        XCTAssertEqual(fetchedUser?.photoURL, "https://example.com/new-photo.jpg")
        XCTAssertEqual(fetchedUser?.isEmailVerified, true)
        XCTAssertEqual(fetchedUser?.isShared, true)
        XCTAssertFalse(fetchedUser?.dirty ?? true, "User should be marked as synced")
    }

    // MARK: - Testing UserService Methods

    func testUserServiceFetchMany() async throws {
        // Create multiple users with known UIDs
        let user1 = User(uid: "fetch-many-1", email: "user1@example.com")
        let user2 = User(uid: "fetch-many-2", email: "user2@example.com")
        let user3 = User(uid: "fetch-many-3", email: "user3@example.com")

        // Insert users into context
        context.insert(user1)
        context.insert(user2)
        context.insert(user3)
        try context.save()

        print("All users in fetchMany test:")
        try userService.fetchAll().forEach { user in
            print(" - User: \(user.uid ?? "nil") email: \(user.email ?? "nil")")
        }

        // Test fetching subset of users
        let fetchedUsers = try userService.fetchMany(withUIDs: ["fetch-many-1", "fetch-many-3"])
        print("Found \(fetchedUsers.count) users with fetchMany:")
        fetchedUsers.forEach { user in
            print(" - Fetched: \(user.uid ?? "nil") email: \(user.email ?? "nil")")
        }
        XCTAssertEqual(fetchedUsers.count, 2, "Should fetch exactly 2 users")

        // Verify correct users were fetched
        let fetchedUids = fetchedUsers.compactMap { $0.uid }
        XCTAssertTrue(fetchedUids.contains("fetch-many-1"), "First user should be fetched")
        XCTAssertTrue(fetchedUids.contains("fetch-many-3"), "Third user should be fetched")
        XCTAssertFalse(fetchedUids.contains("fetch-many-2"), "Second user should not be fetched")

        // Test with non-existent UIDs
        let mixedFetch = try userService.fetchMany(withUIDs: ["fetch-many-1", "non-existent-uid"])
        print("Mixed fetch found \(mixedFetch.count) users:")
        mixedFetch.forEach { user in
            print(" - Mixed fetch: \(user.uid ?? "nil")")
        }
        XCTAssertEqual(mixedFetch.count, 1, "Should only fetch existing users")
        XCTAssertEqual(mixedFetch.first?.uid, "fetch-many-1")
    }

    func testUpdateUserWithChangedFriends() async throws {
        // Create an existing user with some initial friends
        let existingUser = User(
            uid: "user-with-changing-friends",
            email: "user@example.com",
            displayName: "Friendly User"
        )

        // Create initial friends
        let initialFriend1 = User(uid: "initial-friend-1")
        let initialFriend2 = User(uid: "initial-friend-2")
        let newFriend = User(uid: "new-friend-3")

        // Insert all users into the context
        context.insert(existingUser)
        context.insert(initialFriend1)
        context.insert(initialFriend2)
        context.insert(newFriend)

        // Add initial friends to user
        existingUser.friends = [initialFriend1, initialFriend2]
        try context.save()

        // Create updated data with changed friends (removed friend-2, added friend-3)
        let updatedData: [String: Any] = [
            "uid": "user-with-changing-friends",
            "friendIds": ["initial-friend-1", "new-friend-3"],
            "createdAt": Date(),
            "lastSignInAt": Date(),
            "isEmailVerified": false,
        ]

        // Process the update
        try await processor.process(entities: [updatedData], currentUser: currentUser)

        // Verify the user's friends were updated correctly
        let fetchedUser = try userService.fetchUnique(withUID: "user-with-changing-friends")
        XCTAssertNotNil(fetchedUser)

        // Should have 2 friends now (different ones)
        XCTAssertEqual(fetchedUser?.friends.count, 2)

        // Check that the right friends are there
        let friendUids = fetchedUser?.friends.compactMap { $0.uid } ?? []
        XCTAssertTrue(friendUids.contains("initial-friend-1"), "Should still have initial friend 1")
        XCTAssertFalse(
            friendUids.contains("initial-friend-2"), "Should no longer have initial friend 2")
        XCTAssertTrue(friendUids.contains("new-friend-3"), "Should now have the new friend 3")
    }

    func testUpdateUserWithInvites() async throws {
        // Create an existing user
        let existingUser = User(
            uid: "user-with-invites",
            email: "invited@example.com",
            displayName: "Invited User"
        )
        context.insert(existingUser)
        try context.save()

        // Create updated data with invites
        let now = Date()
        let receivedInviteData: [String: Any] = [
            "uid": "received-invite-1",
            "createdAt": now,
            "senderUid": "sender-123",
            "recipientUid": "user-with-invites",
            "senderEmail": "sender@example.com",
            "senderDisplayName": "Sender Person",
        ]

        let sentInviteData: [String: Any] = [
            "uid": "sent-invite-1",
            "createdAt": now,
            "senderUid": "user-with-invites",
            "recipientUid": "recipient-456",
            "recipientEmail": "recipient@example.com",
            "recipientDisplayName": "Recipient Person",
        ]

        let updatedData: [String: Any] = [
            "uid": "user-with-invites",
            "createdAt": Date(),
            "lastSignInAt": Date(),
            "isEmailVerified": false,
            "receivedInvites": [receivedInviteData],
            "sentInvites": [sentInviteData],
        ]

        // Process the update
        try await processor.process(entities: [updatedData], currentUser: currentUser)

        // Verify the invites were processed correctly
        let fetchedUser = try userService.fetchUnique(withUID: "user-with-invites")
        XCTAssertNotNil(fetchedUser)
        let dto = fetchedUser?.toDTO()
        // Check received invites
        XCTAssertEqual(fetchedUser?.receivedInvites.count, 1)
        let receivedInvite = fetchedUser?.receivedInvites.first
        XCTAssertEqual(receivedInvite?.uid, "received-invite-1")
        XCTAssertEqual(receivedInvite?.senderUid, "sender-123")
        XCTAssertEqual(receivedInvite?.recipientUid, "user-with-invites")
        XCTAssertEqual(receivedInvite?.senderEmail, "sender@example.com")
        XCTAssertEqual(receivedInvite?.senderDisplayName, "Sender Person")

        // Check sent invites
        XCTAssertEqual(fetchedUser?.sentInvites.count, 1)
        let sentInvite = fetchedUser?.sentInvites.first
        XCTAssertEqual(sentInvite?.uid, "sent-invite-1")
        XCTAssertEqual(sentInvite?.senderUid, "user-with-invites")
        XCTAssertEqual(sentInvite?.recipientUid, "recipient-456")
        XCTAssertEqual(sentInvite?.recipientEmail, "recipient@example.com")
        XCTAssertEqual(sentInvite?.recipientDisplayName, "Recipient Person")
    }

    // MARK: - Edge Cases

    func testProcessUserWithoutUID() async throws {
        // Create an incomplete user DTO
        let incompleteUserData: [String: Any] = [
            "email": "nouid@example.com",
            "displayName": "No UID User",
        ]

        // Count existing users before processing
        let userCountBefore = try userService.fetchAll().count

        // Process should skip this entity
        try await processor.process(entities: [incompleteUserData], currentUser: currentUser)

        // Verify no new user was added
        let userCountAfter = try userService.fetchAll().count
        XCTAssertEqual(userCountBefore, userCountAfter, "User without UID should be skipped")
    }

    func testClearingFriends() async throws {
        // Create a user with friends
        let existingUser = User(uid: "user-with-friends-to-clear")
        let friend1 = User(uid: "friend-1-to-clear")
        let friend2 = User(uid: "friend-2-to-clear")

        context.insert(existingUser)
        context.insert(friend1)
        context.insert(friend2)

        existingUser.friends = [friend1, friend2]
        try context.save()

        // Verify the user initially has friends
        XCTAssertEqual(existingUser.friends.count, 2)

        // Create updated data with empty friends list
        let updatedData: [String: Any] = [
            "uid": "user-with-friends-to-clear",
            "friendIds": [],  // Empty friends list
            "createdAt": Date(),
            "lastSignInAt": Date(),
            "isEmailVerified": false,
        ]

        // Process the update
        try await processor.process(entities: [updatedData], currentUser: currentUser)

        // Verify the user no longer has friends
        let fetchedUser = try userService.fetchUnique(withUID: "user-with-friends-to-clear")
        XCTAssertNotNil(fetchedUser)
        XCTAssertEqual(
            fetchedUser?.friends.count, 0,
            "User should have no friends after update with empty friendIds")
    }

    func testUserOwnerRelationship() async throws {
        // Create a user that will be the owner
        let ownerUser = User(uid: "owner-uid-123", displayName: "Owner User")
        context.insert(ownerUser)

        // Create a user with an owner relationship
        let userData: [String: Any] = [
            "uid": "user-with-owner",
            "displayName": "Member User",
            "ownerId": "owner-uid-123",
            "createdAt": Date(),
            "lastSignInAt": Date(),
            "isEmailVerified": false,
        ]

        // Process the entity
        try await processor.process(entities: [userData], currentUser: currentUser)

        // Verify the owner relationship is established
        let fetchedUser = try userService.fetchUnique(withUID: "user-with-owner")
        XCTAssertNotNil(fetchedUser)
        XCTAssertNotNil(fetchedUser?.owner, "User should have an owner")
        XCTAssertEqual(fetchedUser?.owner?.uid, "owner-uid-123", "Owner relationship is incorrect")
    }

    func testSelfOwnership() async throws {
        // Create a user that owns itself (common for main account users)
        let userData: [String: Any] = [
            "uid": "self-owner-user",
            "displayName": "Self Owner",
            "ownerId": "self-owner-user",  // Same as the user's UID
            "createdAt": Date(),
            "lastSignInAt": Date(),
            "isEmailVerified": false,
        ]

        // Process the entity
        try await processor.process(entities: [userData], currentUser: currentUser)

        // Verify the self-ownership relationship is established
        let fetchedUser = try userService.fetchUnique(withUID: "self-owner-user")
        XCTAssertNotNil(fetchedUser)
        XCTAssertNotNil(fetchedUser?.owner, "User should have an owner (itself)")
        XCTAssertEqual(
            fetchedUser?.owner?.uid, "self-owner-user", "Self-ownership relationship is incorrect")
        XCTAssertTrue(
            fetchedUser?.owner === fetchedUser, "Owner should be the same object as the user")
    }

    func testRemoveOwnership() async throws {
        // Create a user with an owner
        let ownerUser = User(uid: "owner-to-remove")
        let userWithOwner = User(uid: "user-with-owner-to-remove")
        context.insert(ownerUser)
        context.insert(userWithOwner)
        userWithOwner.owner = ownerUser
        try context.save()

        // Verify initial ownership
        XCTAssertNotNil(userWithOwner.owner)

        // Create updated data with no owner
        let updatedData: [String: Any] = [
            "uid": "user-with-owner-to-remove",
            "displayName": "No Longer Owned",
            // No ownerId provided
            "createdAt": Date(),
            "lastSignInAt": Date(),
            "isEmailVerified": false,
        ]

        // Process the update
        try await processor.process(entities: [updatedData], currentUser: currentUser)

        // Verify the owner relationship is removed
        let fetchedUser = try userService.fetchUnique(withUID: "user-with-owner-to-remove")
        XCTAssertNotNil(fetchedUser)
        XCTAssertNil(fetchedUser?.owner, "User should no longer have an owner")
    }
}
