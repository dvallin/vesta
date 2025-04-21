import SwiftData
import SwiftUI

struct AddFriendView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: UserAuthService

    @State private var emailOrUsername: String = ""
    @State private var isSearching = false
    @State private var searchResults: [User] = []
    @State private var errorMessage: String?

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
                            text: $emailOrUsername
                        )
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                        Button(action: {
                            searchForFriends()
                        }) {
                            Text(NSLocalizedString("Search", comment: "Search button"))
                        }
                        .disabled(
                            emailOrUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal)
                }
                .padding(.top)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                if isSearching {
                    ProgressView()
                        .padding()
                } else if !searchResults.isEmpty {
                    List {
                        ForEach(searchResults) { user in
                            UserResultRow(user: user, onAdd: { addFriend(user) })
                        }
                    }
                } else if !emailOrUsername.isEmpty {
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
        }
    }

    private func searchForFriends() {
        // For UI purposes only - in a real implementation, this would query your backend
        isSearching = true
        errorMessage = nil

        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // This is just a placeholder for UI demonstration
            // In a real implementation, you would search the database or call an API

            // Clear previous results
            searchResults = []

            // For now, just create a mock result if the text isn't empty
            let searchText = emailOrUsername.trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            if !searchText.isEmpty {
                // Create a mock user for demonstration
                let mockUser = User(
                    uid: "mock-\(UUID().uuidString)",
                    email: searchText.contains("@") ? searchText : "\(searchText)@example.com",
                    displayName: searchText.contains("@")
                        ? searchText.components(separatedBy: "@").first : searchText,
                    isEmailVerified: true
                )

                // Don't show the current user in results
                if let currentUser = auth.currentUser, mockUser.email != currentUser.email {
                    // Don't show users that are already friends
                    let isAlreadyFriend = currentUser.friends.contains {
                        $0.email == mockUser.email
                    }
                    if !isAlreadyFriend {
                        searchResults = [mockUser]
                    }
                }
            }

            isSearching = false
        }
    }

    private func addFriend(_ user: User) {
        guard let currentUser = auth.currentUser else { return }

        // Check if already friends
        if currentUser.friends.contains(where: { $0.uid == user.uid }) {
            errorMessage = NSLocalizedString(
                "This user is already in your friends list", comment: "Already friends error")
            return
        }

        // Add to friends list
        currentUser.friends.append(user)
        currentUser.dirty = true

        // Save to database
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = NSLocalizedString("Failed to add friend", comment: "Add friend error")
        }
    }
}

struct UserResultRow: View {
    let user: User
    let onAdd: () -> Void

    var body: some View {
        HStack {
            if let photoURL = user.photoURL, !photoURL.isEmpty {
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
                    user.displayName
                        ?? NSLocalizedString("No Name", comment: "Default user display name")
                )
                .font(.body)

                Text(user.email ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
        .padding(.vertical, 5)
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
