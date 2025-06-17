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
        isLoading = true
        errorMessage = nil

        // Create the invite with all the necessary information
        let invite = Invite(
            uid: UUID().uuidString,
            createdAt: Date(),
            senderUid: currentUser.uid,
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
                completion(true)
            }
            .store(in: &cancellables)
    }

    /// Declines an invite from another user
    /// - Parameters:
    ///   - invite: The invite to decline
    ///   - currentUser: The current user declining the invite
    ///   - completion: Completion handler called after the operation
    func declineInvite(invite: Invite, currentUser: User, completion: @escaping (Bool) -> Void) {

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
                completion(true)
            }
            .store(in: &cancellables)
    }
}
