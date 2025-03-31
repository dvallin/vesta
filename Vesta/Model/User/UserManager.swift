import Combine
import FirebaseAuth
import Foundation
import SwiftData

class UserManager: ObservableObject {
    static let shared = UserManager()

    @Published private(set) var currentUser: User?
    private var cancellables = Set<AnyCancellable>()
    private var modelContext: ModelContext?

    private init() {
        // Listen for Firebase auth state changes
        // Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
        //     self?.handleAuthStateChange(firebaseUser: firebaseUser)
        // }
    }

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        // Check if there's already a user signed in
        // if let firebaseUser = Auth.auth().currentUser {
        //     handleAuthStateChange(firebaseUser: firebaseUser)
        // }
    }

    private func handleAuthStateChange(firebaseUser: FirebaseAuth.User?) {
        guard let modelContext = modelContext else {
            print("Model context not configured in UserManager")
            return
        }

        Task { @MainActor in
            if let firebaseUser = firebaseUser {
                // User signed in
                if let existingUser = fetchUserByUID(firebaseUser.uid) {
                    // Update existing user
                    existingUser.update(from: firebaseUser)
                    self.currentUser = existingUser
                } else {
                    // Create new user
                    let newUser = User(firebaseUser: firebaseUser)
                    modelContext.insert(newUser)
                    self.currentUser = newUser
                }

                try? modelContext.save()
            } else {
                // User signed out
                self.currentUser = nil
            }
        }
    }

    private func fetchUserByUID(_ uid: String) -> User? {
        guard let modelContext = modelContext else { return nil }

        let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.uid == uid })
        do {
            let users = try modelContext.fetch(descriptor)
            return users.first
        } catch {
            print("Error fetching user: \(error)")
            return nil
        }
    }

    // Add a method to get current user, creating one if needed for offline development
    func getCurrentUser() -> User {
        if let user = currentUser {
            return user
        }

        guard let modelContext = modelContext else {
            fatalError("Model context not configured in UserManager")
        }

        // For development/offline use, create a dummy user
        let dummyUser = User(
            uid: "offline-user",
            email: "offline@example.com",
            displayName: "Offline User"
        )
        modelContext.insert(dummyUser)
        self.currentUser = dummyUser
        return dummyUser
    }

    func setCurrentUser(user: User) {
        self.currentUser = user
    }
}
