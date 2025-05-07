import SwiftData
import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject private var auth: UserAuthService
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [TodoItemCategory]
    
    @StateObject var viewModel = UserProfileViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    userInfoSection
                    
                    Divider()
                    
                    friendsSection
                    
                    Divider()
                    
                    sharingPreferencesSection
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("Profile", comment: "User profile screen title"))
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.updateSharingPreferences()
                    }) {
                        Text(NSLocalizedString("Save", comment: "Save button"))
                    }
                }
                #endif
            }
        }
        .sheet(isPresented: $viewModel.isPresentingAddFriendView) {
            AddFriendView()
        }
        .sheet(isPresented: $viewModel.isPresentingInvitesView) {
            InvitesView()
        }
        .toast(messages: $viewModel.toastMessages)
        .onAppear {
            viewModel.configureContext(modelContext, auth)
        }
    }
    
    private var userInfoSection: some View {
        VStack(alignment: .center, spacing: 10) {
            if let currentUser = auth.currentUser {
                if let photoURL = currentUser.photoURL, !photoURL.isEmpty {
                    AsyncImage(url: URL(string: photoURL)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        case .failure:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                }
                
                Text(currentUser.displayName ?? NSLocalizedString("No Name", comment: "Default display name"))
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(currentUser.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text(NSLocalizedString("Not signed in", comment: "Not signed in status"))
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(NSLocalizedString("Friends", comment: "Friends section header"))
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    HapticFeedbackManager.shared.generateSelectionFeedback()
                    viewModel.isPresentingInvitesView = true
                }) {
                    Label(
                        NSLocalizedString("Invites", comment: "View invites button"),
                        systemImage: "envelope"
                    )
                }
                
                Button(action: {
                    HapticFeedbackManager.shared.generateSelectionFeedback()
                    viewModel.isPresentingAddFriendView = true
                }) {
                    Label(
                        NSLocalizedString("Add Friend", comment: "Add friend button"),
                        systemImage: "person.badge.plus"
                    )
                }
            }
            
            if let currentUser = auth.currentUser, !currentUser.friends.isEmpty {
                ForEach(currentUser.friends) { friend in
                    FriendRowView(friend: friend)
                }
            } else {
                Text(NSLocalizedString("No friends added yet", comment: "Empty friends list message"))
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
            }
        }
    }
    
    private var sharingPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(NSLocalizedString("Sharing Preferences", comment: "Sharing preferences section header"))
                .font(.headline)
            
            Toggle(NSLocalizedString("Share Meal Plans", comment: "Share meal plans toggle"), isOn: $viewModel.shareMeals)
                .padding(.vertical, 5)
            
            Toggle(NSLocalizedString("Share Shopping List", comment: "Share shopping list toggle"), isOn: $viewModel.shareShoppingItems)
                .padding(.vertical, 5)
            
            Text(NSLocalizedString("Share Todo Categories", comment: "Share todo categories section"))
                .font(.subheadline)
                .padding(.top, 10)
            
            if categories.isEmpty {
                Text(NSLocalizedString("No categories available", comment: "Empty todo categories message"))
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.vertical, 5)
            } else {
                ForEach(categories) { category in
                    CategoryToggleView(
                        category: category, 
                        isSelected: isCategorySelected(category),
                        onToggle: { isSelected in
                            toggleCategory(category, isSelected: isSelected)
                        }
                    )
                }
            }
        }
    }
    
    private func isCategorySelected(_ category: TodoItemCategory) -> Bool {
        viewModel.selectedCategories.contains { $0.id == category.id }
    }
    
    private func toggleCategory(_ category: TodoItemCategory, isSelected: Bool) {
        if isSelected {
            if !viewModel.selectedCategories.contains(where: { $0.id == category.id }) {
                viewModel.selectedCategories.append(category)
            }
        } else {
            viewModel.selectedCategories.removeAll { $0.id == category.id }
        }
    }
}

struct FriendRowView: View {
    let friend: User
    
    var body: some View {
        HStack {
            if let photoURL = friend.photoURL, !photoURL.isEmpty {
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
                Text(friend.displayName ?? NSLocalizedString("No Name", comment: "Default friend display name"))
                    .font(.body)
                
                Text(friend.email ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 5)
    }
}

struct CategoryToggleView: View {
    let category: TodoItemCategory
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Toggle(isOn: Binding(
            get: { isSelected },
            set: { onToggle($0) }
        )) {
            HStack {
                if let colorHex = category.color, let color = Color(hex: colorHex) {
                    Circle()
                        .fill(color)
                        .frame(width: 16, height: 16)
                }
                
                Text(category.name)
                    .font(.body)
            }
        }
        .padding(.vertical, 2)
    }
}


#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext
        
        let user = Fixtures.createUser()
        
        // Add some friends
        let friend1 = User(uid: "friend1", email: "friend1@example.com", displayName: "Friend One")
        let friend2 = User(uid: "friend2", email: "friend2@example.com", displayName: "Friend Two")
        user.friends = [friend1, friend2]
        
        // Add some categories
        let categories = [
            TodoItemCategory(name: "Work", color: "#FF0000"),
            TodoItemCategory(name: "Personal", color: "#00FF00"),
            TodoItemCategory(name: "Shopping", color: "#0000FF")
        ]
        
        for category in categories {
            context.insert(category)
        }
        
        context.insert(user)
        
        let authService = UserAuthService(modelContext: context)
        
        return UserProfileView()
            .modelContainer(container)
            .environmentObject(authService)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
