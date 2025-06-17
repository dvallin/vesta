import SwiftData
import SwiftUI
import os

struct InvitesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: UserAuthService
    @EnvironmentObject private var invites: UserInviteService

    private let logger = Logger(subsystem: "com.app.Vesta", category: "InvitesView")
    @State private var selectedTab = 0
    @State private var refreshing = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            VStack {
                Picker("Invite Type", selection: $selectedTab) {
                    Text(NSLocalizedString("Received", comment: "Received invites tab"))
                        .tag(0)
                    Text(NSLocalizedString("Sent", comment: "Sent invites tab"))
                        .tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if invites.isLoading {
                    ProgressView()
                        .padding()
                } else if selectedTab == 0 {
                    receivedInvitesView
                } else {
                    sentInvitesView
                }

                Spacer()
            }
            .navigationTitle(NSLocalizedString("Invites", comment: "Invites screen title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Done", comment: "Done button")) {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $showingError) {
                Alert(
                    title: Text(NSLocalizedString("Error", comment: "Error alert title")),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private var receivedInvitesView: some View {
        ScrollView {
            LazyVStack {
                if auth.currentUser?.receivedInvites.isEmpty ?? true {
                    ContentUnavailableView(
                        NSLocalizedString("No Invites", comment: "No invites title"),
                        systemImage: "person.crop.circle.badge.xmark",
                        description: Text(
                            NSLocalizedString(
                                "You don't have any received invites",
                                comment: "No received invites description")
                        )
                    )
                    .padding()
                } else if let receivedInvites = auth.currentUser?.receivedInvites {
                    ForEach(receivedInvites, id: \.uid) { invite in
                        ReceivedInviteRow(invite: invite) { action in
                            handleInviteAction(invite: invite, action: action)
                        }
                        .padding(.horizontal)
                        Divider()
                    }
                }
            }
        }
    }

    private var sentInvitesView: some View {
        ScrollView {
            LazyVStack {
                if auth.currentUser?.sentInvites.isEmpty ?? true {
                    ContentUnavailableView(
                        NSLocalizedString("No Invites", comment: "No invites title"),
                        systemImage: "person.crop.circle.badge.xmark",
                        description: Text(
                            NSLocalizedString(
                                "You haven't sent any invites",
                                comment: "No sent invites description")
                        )
                    )
                    .padding()
                } else if let sentInvites = auth.currentUser?.sentInvites {
                    ForEach(sentInvites, id: \.uid) { invite in
                        SentInviteRow(invite: invite)
                            .padding(.horizontal)
                        Divider()
                    }
                }
            }
        }
    }

    private func handleInviteAction(invite: Invite, action: InviteAction) {
        guard let currentUser = auth.currentUser else {
            showError(NSLocalizedString("You need to be logged in", comment: "Auth error"))
            return
        }

        switch action {
        case .accept:
            invites.acceptInvite(invite: invite, currentUser: currentUser) { success in
                if success {
                    logger.info("Successfully accepted invite")
                } else {
                    showError(NSLocalizedString("Failed to accept invite", comment: "Accept error"))
                }
            }

        case .decline:
            invites.declineInvite(invite: invite, currentUser: currentUser) { success in
                if success {
                    logger.info("Successfully declined invite")
                } else {
                    showError(
                        NSLocalizedString("Failed to decline invite", comment: "Decline error"))
                }
            }
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

enum InviteAction {
    case accept
    case decline
}

struct ReceivedInviteRow: View {
    let invite: Invite
    let onAction: (InviteAction) -> Void

    @State private var isProcessing = false

    var body: some View {
        HStack {
            if let photoURL = invite.senderPhotoURL, !photoURL.isEmpty {
                AsyncImage(url: URL(string: photoURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    case .failure:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 50, height: 50)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading) {
                Text(
                    invite.senderDisplayName
                        ?? NSLocalizedString("No Name", comment: "Default display name")
                )
                .font(.headline)

                Text(invite.senderEmail ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(
                    String(
                        format: NSLocalizedString("Sent %@", comment: "Invite sent date"),
                        invite.createdAt.formatted(date: .abbreviated, time: .shortened)
                    )
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            if isProcessing {
                ProgressView()
            } else {
                HStack {
                    Button {
                        isProcessing = true
                        onAction(.accept)
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    }

                    Button {
                        isProcessing = true
                        onAction(.decline)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct SentInviteRow: View {
    let invite: Invite

    var body: some View {
        HStack {
            if let photoURL = invite.recipientPhotoURL, !photoURL.isEmpty {
                AsyncImage(url: URL(string: photoURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    case .failure:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 50, height: 50)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading) {
                Text(
                    invite.recipientDisplayName
                        ?? NSLocalizedString("No Name", comment: "Default display name")
                )
                .font(.headline)

                Text(invite.recipientEmail ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(
                    String(
                        format: NSLocalizedString("Sent %@", comment: "Invite sent date"),
                        invite.createdAt.formatted(date: .abbreviated, time: .shortened)
                    )
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "hourglass")
                .foregroundColor(.orange)
                .font(.title3)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext

        // Create a sample user with invites
        let user = Fixtures.createUser()

        // Add some sample received invites
        let invite1 = Invite(
            uid: "user_from_sender1_123456789",
            createdAt: Date(),
            senderUid: "sender1_uid",
            recipientUid: user.uid ?? "current_user",
            senderEmail: "sender1@example.com",
            senderDisplayName: "Sender One",
            senderPhotoURL: nil,
            recipientEmail: user.email,
            recipientDisplayName: user.displayName,
            recipientPhotoURL: user.photoURL
        )

        let invite2 = Invite(
            uid: "user_from_sender2_123456789",
            createdAt: Date().addingTimeInterval(-86400),  // Yesterday
            senderUid: "sender2_uid",
            recipientUid: user.uid ?? "current_user",
            senderEmail: "sender2@example.com",
            senderDisplayName: "Sender Two",
            senderPhotoURL: nil,
            recipientEmail: user.email,
            recipientDisplayName: user.displayName,
            recipientPhotoURL: user.photoURL
        )

        invite1.owner = user
        invite2.owner = user
        user.receivedInvites = [invite1, invite2]

        context.insert(user)
        context.insert(invite1)
        context.insert(invite2)

        // Create the user auth service
        let authService = UserAuthService(modelContext: context)

        // Create the mock Firebase API client
        let mockAPIClient = FirebaseAPIClient()

        // Create the invite service
        let inviteService = UserInviteService(modelContext: context, apiClient: mockAPIClient)
        
        // Set the current user on the auth service for preview
        authService.setCurrentUser(user: user)

        return InvitesView()
            .modelContainer(container)
            .environmentObject(authService)
            .environmentObject(inviteService)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
