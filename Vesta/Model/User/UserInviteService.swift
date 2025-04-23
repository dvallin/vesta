import Combine
import Foundation
import SwiftData
import os

/// Service for managing user invites
class UserInviteService: ObservableObject {
    private let modelContext: ModelContext
    private let apiClient: InviteAPIClient
    private let logger = Logger(subsystem: "com.app.Vesta", category: "UserInvite")
    private var cancellables = Set<AnyCancellable>()

    @Published var receivedInvites: [Invite] = []
    @Published var sentInvites: [Invite] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    init(modelContext: ModelContext, apiClient: InviteAPIClient) {
        self.modelContext = modelContext
        self.apiClient = apiClient
    }

    /// Sends an invite to another user
    /// - Parameters:
    ///   - currentUser: The current user sending the invite
    ///   - recipient: The recipient user information
    ///   - completionStatus: completion handler called after the operation
    func sendInvite(
        from currentUser: User, to recipient: UserSearchResult,
        completion: @escaping (Bool) -> Void
    ) {
        guard let currentUserId = currentUser.uid else {
            logger.error("Cannot send invite: current user has no UID")
            completion(false)
            return
        }

        isLoading = true
        errorMessage = nil

        // Create user data dictionaries
        let currentUserData: [String: Any] = [
            "email": currentUser.email ?? "",
            "displayName": currentUser.displayName ?? "",
            "photoURL": currentUser.photoURL ?? "",
        ]

        let recipientData: [String: Any] = [
            "email": recipient.email ?? "",
            "displayName": recipient.displayName ?? "",
            "photoURL": recipient.photoURL ?? "",
        ]

        // Call Firebase API
        apiClient.sendInvite(
            currentUserId: currentUserId,
            currentUserData: currentUserData,
            recipientId: recipient.uid,
            recipientData: recipientData
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completionStatus in
            guard let self = self else { return }
            self.isLoading = false

            switch completionStatus {
            case .finished:
                // Success case handled in receiveValue
                break
            case .failure(let error):
                self.logger.error("Failed to send invite: \(error.localizedDescription)")
                self.errorMessage = NSLocalizedString(
                    "Failed to send invite", comment: "Send invite error")
                self.isLoading = false
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        } receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.logger.info("Successfully sent invite to: \(recipient.uid)")

            // Create local invite record
            let invite = Invite(
                uid: "\(currentUserId)_to_\(recipient.uid)_\(Date().timeIntervalSince1970)",
                createdAt: Date(),
                email: recipient.email,
                displayName: recipient.displayName,
                photoURL: recipient.photoURL
            )

            // Add to local model
            DispatchQueue.main.async {
                invite.owner = currentUser
                currentUser.sentInvites.append(invite)
                self.modelContext.insert(invite)

                do {
                    try self.modelContext.save()
                    self.sentInvites.append(invite)
                    completion(true)
                } catch {
                    self.logger.error("Failed to save local invite: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
        .store(in: &cancellables)
    }

    /// Accepts an invite from another user
    /// - Parameters:
    ///   - invite: The invite to accept
    ///   - currentUser: The current user accepting the invite
    ///   - completion: Completion handler called after the operation
    func acceptInvite(invite: Invite, currentUser: User, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = currentUser.uid else {
            logger.error("Cannot accept invite: missing user ID or invite ID")
            completion(false)
            return
        }

        // Extract sender ID from invite ID format
        let components = invite.uid.components(separatedBy: "_from_")
        guard components.count > 1 else {
            logger.error("Invalid invite ID format")
            completion(false)
            return
        }

        // Extract sender ID from the second part (may contain timestamp)
        let senderIdWithTimestamp = components[1]
        let senderIdComponents = senderIdWithTimestamp.components(separatedBy: "_")
        let senderId = senderIdComponents[0]

        isLoading = true
        errorMessage = nil

        // Call Firebase API
        apiClient.acceptInvite(
            currentUserId: currentUserId,
            inviteId: invite.uid,
            senderId: senderId
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completionStatus in
            guard let self = self else { return }
            self.isLoading = false

            switch completionStatus {
            case .finished:
                // Success case handled in receiveValue
                break
            case .failure(let error):
                self.logger.error("Failed to accept invite: \(error.localizedDescription)")
                self.errorMessage = NSLocalizedString(
                    "Failed to accept invite", comment: "Accept invite error")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        } receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.logger.info("Successfully accepted invite from \(senderId)")

            // Handle local model updates
            DispatchQueue.main.async {
                // Find the sender user or create a placeholder if not in our local database yet
                let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.uid == senderId })

                do {
                    let users = try self.modelContext.fetch(descriptor)
                    let sender: User

                    if let existingUser = users.first {
                        sender = existingUser
                    } else {
                        // Create a placeholder user that will be updated when data syncs
                        sender = User(uid: senderId)
                        sender.displayName = invite.displayName
                        sender.email = invite.email
                        sender.photoURL = invite.photoURL
                        self.modelContext.insert(sender)
                    }

                    // Add relationship in both directions
                    if !currentUser.friends.contains(where: { $0.uid == senderId }) {
                        currentUser.friends.append(sender)
                    }

                    if !sender.friends.contains(where: { $0.uid == currentUserId }) {
                        sender.friends.append(currentUser)
                    }

                    // Remove the invite from our list
                    currentUser.receivedInvites.removeAll { $0.uid == invite.uid }
                    self.receivedInvites.removeAll { $0.uid == invite.uid }

                    // Delete the invite
                    self.modelContext.delete(invite)

                    try self.modelContext.save()
                    completion(true)
                } catch {
                    self.logger.error(
                        "Failed to update local model after accepting invite: \(error.localizedDescription)"
                    )
                    completion(false)
                }
            }
        }
        .store(in: &cancellables)
    }

    /// Declines an invite from another user
    /// - Parameters:
    ///   - invite: The invite to decline
    ///   - currentUser: The current user declining the invite
    ///   - completion: Completion handler called after the operation
    func declineInvite(invite: Invite, currentUser: User, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = currentUser.uid else {
            logger.error("Cannot decline invite: missing user ID or invite ID")
            completion(false)
            return
        }

        // Extract sender ID from invite ID format
        let components = invite.uid.components(separatedBy: "_from_")
        guard components.count > 1 else {
            logger.error("Invalid invite ID format")
            completion(false)
            return
        }

        // Extract sender ID from the second part (may contain timestamp)
        let senderIdWithTimestamp = components[1]
        let senderIdComponents = senderIdWithTimestamp.components(separatedBy: "_")
        let senderId = senderIdComponents[0]

        isLoading = true
        errorMessage = nil

        // Call Firebase API
        apiClient.declineInvite(
            currentUserId: currentUserId,
            inviteId: invite.uid,
            senderId: senderId
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completionStatus in
            guard let self = self else { return }
            self.isLoading = false

            switch completionStatus {
            case .finished:
                // Success case handled in receiveValue
                break
            case .failure(let error):
                self.logger.error("Failed to decline invite: \(error.localizedDescription)")
                self.errorMessage = NSLocalizedString(
                    "Failed to decline invite", comment: "Decline invite error")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        } receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.logger.info("Successfully declined invite from \(senderId)")

            // Handle local model updates
            DispatchQueue.main.async {
                // Remove the invite from our list
                currentUser.receivedInvites.removeAll { $0.uid == invite.uid }
                self.receivedInvites.removeAll { $0.uid == invite.uid }

                // Delete the invite
                self.modelContext.delete(invite)

                do {
                    try self.modelContext.save()
                    completion(true)
                } catch {
                    self.logger.error(
                        "Failed to update local model after declining invite: \(error.localizedDescription)"
                    )
                    completion(false)
                }
            }
        }
        .store(in: &cancellables)
    }

    /// Fetches received invites for the current user
    /// - Parameters:
    ///   - userId: The ID of the user whose invites to fetch
    ///   - completion: Completion handler called after the operation
    func fetchReceivedInvites(userId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil

        apiClient.fetchReceivedInvites(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completionStatus in
                guard let self = self else { return }
                self.isLoading = false

                switch completionStatus {
                case .finished:
                    // Success case handled in receiveValue
                    break
                case .failure(let error):
                    self.logger.error(
                        "Failed to fetch received invites: \(error.localizedDescription)")
                    self.errorMessage = NSLocalizedString(
                        "Failed to load received invites", comment: "Fetch invites error")
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            } receiveValue: { [weak self] invitesData in
                guard let self = self else { return }
                self.logger.info("Fetched \(invitesData.count) received invites for user \(userId)")

                DispatchQueue.main.async {
                    // Find the current user
                    let descriptor = FetchDescriptor<User>(
                        predicate: #Predicate { $0.uid == userId })

                    do {
                        guard let currentUser = try self.modelContext.fetch(descriptor).first else {
                            self.logger.error("User not found in local database")
                            completion(false)
                            return
                        }

                        // Clear existing invites
                        for invite in currentUser.receivedInvites {
                            self.modelContext.delete(invite)
                        }
                        currentUser.receivedInvites.removeAll()

                        // Process new invites
                        var newInvites: [Invite] = []

                        for inviteData in invitesData {
                            if let uid = inviteData["uid"] as? String {
                                // Convert Firestore timestamp to date
                                let createdAt: Date
                                if let timestamp = inviteData["createdAt"] as? [String: Any],
                                    let seconds = timestamp["seconds"] as? TimeInterval
                                {
                                    createdAt = Date(timeIntervalSince1970: seconds)
                                } else {
                                    createdAt = Date()
                                }

                                let invite = Invite(
                                    uid: uid,
                                    createdAt: createdAt,
                                    email: inviteData["email"] as? String,
                                    displayName: inviteData["displayName"] as? String,
                                    photoURL: inviteData["photoURL"] as? String
                                )

                                invite.owner = currentUser
                                self.modelContext.insert(invite)
                                currentUser.receivedInvites.append(invite)
                                newInvites.append(invite)
                            }
                        }

                        try self.modelContext.save()
                        self.receivedInvites = newInvites
                        completion(true)
                    } catch {
                        self.logger.error(
                            "Failed to save received invites: \(error.localizedDescription)")
                        completion(false)
                    }
                }
            }
            .store(in: &cancellables)
    }

    /// Fetches sent invites for the current user
    /// - Parameters:
    ///   - userId: The ID of the user whose invites to fetch
    ///   - completion: Completion handler called after the operation
    func fetchSentInvites(userId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil

        apiClient.fetchSentInvites(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completionStatus in
                guard let self = self else { return }
                self.isLoading = false

                switch completionStatus {
                case .finished:
                    // Success case handled in receiveValue
                    break
                case .failure(let error):
                    self.logger.error("Failed to fetch sent invites: \(error.localizedDescription)")
                    self.errorMessage = NSLocalizedString(
                        "Failed to load sent invites", comment: "Fetch invites error")
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            } receiveValue: { [weak self] invitesData in
                guard let self = self else { return }
                self.logger.info("Fetched \(invitesData.count) sent invites for user \(userId)")

                DispatchQueue.main.async {
                    // Find the current user
                    let descriptor = FetchDescriptor<User>(
                        predicate: #Predicate { $0.uid == userId })

                    do {
                        guard let currentUser = try self.modelContext.fetch(descriptor).first else {
                            self.logger.error("User not found in local database")
                            completion(false)
                            return
                        }

                        // Clear existing invites
                        for invite in currentUser.sentInvites {
                            self.modelContext.delete(invite)
                        }
                        currentUser.sentInvites.removeAll()

                        // Process new invites
                        var newInvites: [Invite] = []

                        for inviteData in invitesData {
                            if let uid = inviteData["uid"] as? String {
                                // Convert Firestore timestamp to date
                                let createdAt: Date
                                if let timestamp = inviteData["createdAt"] as? [String: Any],
                                    let seconds = timestamp["seconds"] as? TimeInterval
                                {
                                    createdAt = Date(timeIntervalSince1970: seconds)
                                } else {
                                    createdAt = Date()
                                }

                                let invite = Invite(
                                    uid: uid,
                                    createdAt: createdAt,
                                    email: inviteData["email"] as? String,
                                    displayName: inviteData["displayName"] as? String,
                                    photoURL: inviteData["photoURL"] as? String
                                )

                                invite.owner = currentUser
                                self.modelContext.insert(invite)
                                currentUser.sentInvites.append(invite)
                                newInvites.append(invite)
                            }
                        }

                        try self.modelContext.save()
                        self.sentInvites = newInvites
                        completion(true)
                    } catch {
                        self.logger.error(
                            "Failed to save sent invites: \(error.localizedDescription)")
                        completion(false)
                    }
                }
            }
            .store(in: &cancellables)
    }

    /// Refreshes all invites for the current user
    /// - Parameter userId: The ID of the user whose invites to refresh
    func refreshInvites(userId: String) {
        fetchReceivedInvites(userId: userId) { _ in }
        fetchSentInvites(userId: userId) { _ in }
    }
}
