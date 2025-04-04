import Combine
import FirebaseAuth
import Foundation
import SwiftData

class UserManager: ObservableObject {
    static let shared = UserManager()

    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticating = false

    private var cancellables = Set<AnyCancellable>()
    private var modelContext: ModelContext?
    private var authStateHandler: AuthStateDidChangeListenerHandle?

    private init() {}

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext

        // Listen for Firebase auth state changes
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            self?.handleAuthStateChange(firebaseUser: firebaseUser)
        }
    }

    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }

    var isAuthenticated: Bool {
        return currentUser != nil
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

    // MARK: - Authentication Methods

    func signIn(email: String, password: String) -> Future<User, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(
                    .failure(
                        NSError(
                            domain: "UserManager", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "UserManager instance is nil"])))
                return
            }

            self.isAuthenticating = true

            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                self.isAuthenticating = false

                if let error = error {
                    promise(.failure(error))
                    return
                }

                guard let firebaseUser = authResult?.user else {
                    promise(
                        .failure(
                            NSError(
                                domain: "UserManager", code: 1,
                                userInfo: [
                                    NSLocalizedDescriptionKey: "User not found after authentication"
                                ])))
                    return
                }

                // Directly handle the auth change to ensure the user is set
                Task { @MainActor in
                    self.handleAuthStateChange(firebaseUser: firebaseUser)

                    // Short delay to ensure database operations complete
                    try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

                    guard let user = self.currentUser else {
                        promise(
                            .failure(
                                NSError(
                                    domain: "UserManager", code: 1,
                                    userInfo: [
                                        NSLocalizedDescriptionKey:
                                            "User not found after authentication"
                                    ])))
                        return
                    }

                    promise(.success(user))
                }
            }
        }
    }

    func signUp(email: String, password: String, displayName: String) -> Future<User, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(
                    .failure(
                        NSError(
                            domain: "UserManager", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "UserManager instance is nil"])))
                return
            }

            print("Starting sign up process for email: \(email)")
            self.isAuthenticating = true

            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    print("ERROR during Firebase createUser: \(error.localizedDescription)")
                    if let errorCode = AuthErrorCode(rawValue: (error as NSError).code) {
                        print("Firebase Auth Error Code: \(errorCode)")
                    }
                    self.isAuthenticating = false
                    promise(.failure(error))
                    return
                }

                guard let firebaseUser = authResult?.user else {
                    print("ERROR: authResult?.user is nil after successful createUser")
                    self.isAuthenticating = false
                    promise(
                        .failure(
                            NSError(
                                domain: "UserManager", code: 1,
                                userInfo: [NSLocalizedDescriptionKey: "User not created"])))
                    return
                }

                print(
                    "User created successfully in Firebase, updating profile with displayName: \(displayName)"
                )

                // Update display name
                let changeRequest = firebaseUser.createProfileChangeRequest()
                changeRequest.displayName = displayName

                changeRequest.commitChanges { error in
                    self.isAuthenticating = false
                    // Refresh the user to get updated profile
                    do {
                        try await firebaseUser.reload()

                        // Now handle the updated user
                        self.handleAuthStateChange(firebaseUser: Auth.auth().currentUser)

                        // Short delay to ensure database operations complete
                        try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

                        guard let user = self.currentUser else {
                            promise(
                                .failure(
                                    NSError(
                                        domain: "UserManager", code: 2,
                                        userInfo: [
                                            NSLocalizedDescriptionKey:
                                                "User not found after creation"
                                        ])))
                            return
                        }
                        promise(.success(user))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }

    func signOut() -> Future<Void, Error> {
        return Future { promise in
            do {
                try Auth.auth().signOut()
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
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
