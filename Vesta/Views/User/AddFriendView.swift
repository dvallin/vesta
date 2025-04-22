import SwiftData
import SwiftUI
import os

struct AddFriendView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: UserAuthService

    @StateObject private var viewModel = AddFriendViewModel()

    var body: some View {
        NavigationView {
            VStack {
                VStack(alignment: .leading) {
                    Text(
                        NSLocalizedString(
                            "Enter email or username to find friends",
                            comment: "Add friend instruction")
                    )
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                    HStack {
                        TextField(
                            NSLocalizedString(
                                "Email or username", comment: "Email or username field placeholder"),
                            text: $viewModel.searchText
                        )
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onSubmit {
                            viewModel.searchForFriends()
                        }

                        Button(action: {
                            viewModel.searchForFriends()
                        }) {
                            Text(NSLocalizedString("Search", comment: "Search button"))
                        }
                        .disabled(
                            viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal)
                }
                .padding(.top)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                if viewModel.isSearching {
                    ProgressView()
                        .padding()
                } else if !viewModel.searchResults.isEmpty {
                    List {
                        ForEach(viewModel.searchResults) { result in
                            UserSearchResultRow(result: result) {
                                viewModel.sendInvite(to: result, currentUser: auth.currentUser)
                            }
                        }
                    }
                } else if !viewModel.searchText.isEmpty && viewModel.hasSearched {
                    ContentUnavailableView(
                        NSLocalizedString("No Results", comment: "No search results title"),
                        systemImage: "person.slash",
                        description: Text(
                            NSLocalizedString(
                                "No users found with that email or username",
                                comment: "No search results description"))
                    )
                    .padding()
                } else {
                    ContentUnavailableView(
                        NSLocalizedString(
                            "Search for Friends", comment: "Search friends placeholder title"),
                        systemImage: "person.badge.plus",
                        description: Text(
                            NSLocalizedString(
                                "Enter an email or username to find friends",
                                comment: "Search friends placeholder description"))
                    )
                    .padding()
                }

                Spacer()
            }
            .navigationTitle(NSLocalizedString("Add Friend", comment: "Add friend screen title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $viewModel.showingInviteSent) {
                Alert(
                    title: Text(NSLocalizedString("Invite Sent", comment: "Invite sent alert title")),
                    message: Text(NSLocalizedString("Your invite has been sent successfully", comment: "Invite sent message")),
                    dismissButton: .default(Text("OK")) {
                        dismiss()
                    }
                )
            }
        }
        .onAppear {
            viewModel.modelContext = modelContext
        }
    }
}

struct UserSearchResultRow: View {
    let result: UserSearchResult
    let onSendInvite: () -> Void
    
    @State private var isSending = false
    
    var body: some View {
        HStack {
            if let photoURL = result.photoURL, !photoURL.isEmpty {
                AsyncImage(url: URL(string: photoURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    case .failure:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 40, height: 40)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading) {
                Text(
                    result.displayName
                        ?? NSLocalizedString("No Name", comment: "Default user display name")
                )
                .font(.body)

                Text(result.email ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                isSending = true
                onSendInvite()
            }) {
                if isSending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .disabled(isSending)
        }
        .padding(.vertical, 5)
    }
}

class AddFriendViewModel: ObservableObject {
    private let searchService = UserSearchService()
    private let logger = Logger(subsystem: "com.app.Vesta", category: "AddFriend")
    
    var modelContext: ModelContext?
    
    @Published var searchText: String = ""
    @Published var searchResults: [UserSearchResult] = []
    @Published var isSearching = false
    @Published var errorMessage: String? = nil
    @Published var hasSearched = false
    @Published var showingInviteSent = false
    
    func searchForFriends() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        hasSearched = true
        
        searchService.searchUsers(query: query) { [weak self] result in
            guard let self = self else { return }
            
            self.isSearching = false
            
            switch result {
            case .success(let results):
                self.searchResults = results
                self.logger.info("Found \(results.count) users matching query: \(query)")
                
            case .failure(let error):
                self.searchResults = []
                self.errorMessage = NSLocalizedString("Error searching users", comment: "Search error message")
                self.logger.error("User search failed: \(error.localizedDescription)")
            }
        }
    }
    
    func sendInvite(to user: UserSearchResult, currentUser: User?) {
        guard let currentUser = currentUser, let context = modelContext else {
            errorMessage = NSLocalizedString("You need to be logged in to send invites", comment: "Not logged in error")
            return
        }
        
        // Check if already friends
        if currentUser.friends.contains(where: { $0.uid == user.uid }) {
            errorMessage = NSLocalizedString(
                "This user is already in your friends list", comment: "Already friends error")
            return
        }
        
        // Check if invite already sent
        if currentUser.sentInvites.contains(where: { $0.uid == user.uid }) {
            errorMessage = NSLocalizedString(
                "You've already sent an invite to this user", comment: "Invite already sent error")
            return
        }
        
        // Create the invite
        let invite = user.toInvite()
        invite.owner = currentUser
        
        // Add to current user's sent invites
        currentUser.sentInvites.append(invite)
        currentUser.dirty = true
        
        // Save to database
        do {
            context.insert(invite)
            try context.save()
            logger.info("Invite sent successfully to: \(user.uid)")
            showingInviteSent = true
        } catch {
            errorMessage = NSLocalizedString("Failed to send invite", comment: "Send invite error")
            logger.error("Failed to save invite: \(error.localizedDescription)")
        }
    }
}

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext
        return AddFriendView()
            .environmentObject(UserAuthService(modelContext: context))
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
