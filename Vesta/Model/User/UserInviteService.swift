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

        // Create the invite with all the necessary information
        let invite = Invite(
            uid: UUID().uuidString,
            createdAt: Date(),
            senderUid: currentUserId,
            recipientUid: recipient.uid,
            senderEmail: currentUser.email,
            senderDisplayName: currentUser.displayName,
            senderPhotoURL: currentUser.photoURL,
            recipientEmail: recipient.email,
            recipientDisplayName: recipient.displayName,
            recipientPhotoURL: recipient.photoURL
        )

        apiClient.sendInvite(invite)
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

                // Add to local model
                DispatchQueue.main.async {
                    currentUser.sentInvites.append(invite)
                    self.modelContext.insert(invite)

                    do {
                        try self.modelContext.save()
                        self.sentInvites.append(invite)
                        completion(true)
                    } catch {
                        self.logger.error(
                            "Failed to save local invite: \(error.localizedDescription)")
                        completion(false)
                    }
                }
            }
            .store(in: &cancellables)
    }

    /// Accepts an invite from another user
    /// - Parameters:
    ///   - invite: The invite to accept
    /// Accepts an invite from another user
    /// - Parameters:
    ///   - invite: The invite to accept
    ///   - currentUser: The current user accepting the invite
    ///   - completion: Completion handler called after the operation
    func acceptInvite(invite: Invite, currentUser: User, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = currentUser.uid else {
            logger.error("Cannot accept invite: missing user ID")
            completion(false)
            return
        }
        
        isLoading = true
        errorMessage = nil

        // Call Firebase API
        apiClient.acceptInvite(invite)
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
            self.logger.info("Successfully accepted invite from \(invite.senderUid)")

            // Handle local model updates
            DispatchQueue.main.async {
                // Find the sender user or create a placeholder if not in our local database yet
                let senderId = invite.senderUid
                let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.uid == senderId })

                do {
                    let users = try self.modelContext.fetch(descriptor)
                    let sender: User

                    if let existingUser = users.first {
                        sender = existingUser
                    } else {
                        // Create a placeholder user that will be updated when data syncs
                        sender = User(uid: invite.senderUid)
                        sender.displayName = invite.senderDisplayName
                        sender.email = invite.senderEmail
                        sender.photoURL = invite.senderPhotoURL
                        self.modelContext.insert(sender)
                    }

                    // Add relationship in both directions
                    if !currentUser.friends.contains(where: { $0.uid == invite.senderUid }) {
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
            logger.error("Cannot decline invite: missing user ID")
            completion(false)
            return
        }

        isLoading = true
        errorMessage = nil

        // Call Firebase API
        apiClient.declineInvite(invite)
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
            self.logger.info("Successfully declined invite from \(invite.senderUid)")

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
                            if let invite = Invite.fromDTO(inviteData, owner: currentUser) {
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
                            if let invite = Invite.fromDTO(inviteData, owner: currentUser) {
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
