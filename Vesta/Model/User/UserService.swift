import Combine
import FirebaseAuth
import Foundation
import OSLog
import SwiftData

class UserService: ObservableObject {
    // MARK: - Logging
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.vesta",
        category: "UserService"
    )

    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticating = false

    private var cancellables = Set<AnyCancellable>()
    private var modelContext: ModelContext?
    private var authStateHandler: AuthStateDidChangeListenerHandle?

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        logger.info("UserService configured with ModelContext")

        // Listen for Firebase auth state changes
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            self?.handleAuthStateChange(firebaseUser: firebaseUser)
        }
        logger.debug("Firebase auth state listener registered")
    }

    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
            logger.debug("Firebase auth state listener removed")
        }
    }

    private func handleAuthStateChange(firebaseUser: FirebaseAuth.User?) {
        guard let modelContext = modelContext else {
            logger.error("Model context not configured in UserService")
            return
        }

        Task { @MainActor in
            if let firebaseUser = firebaseUser {
                // User signed in
                logger.info("Auth state changed: user signed in with UID: \(firebaseUser.uid)")

                if let existingUser = fetchUserByUID(firebaseUser.uid) {
                    // Update existing user
                    logger.debug("Updating existing user with UID: \(firebaseUser.uid)")
                    existingUser.update(from: firebaseUser)
                    self.currentUser = existingUser
                } else {
                    // Create new user
                    logger.debug("Creating new user with UID: \(firebaseUser.uid)")
                    let newUser = User(firebaseUser: firebaseUser)
                    self.currentUser = newUser
                    modelContext.insert(newUser)
                }

                do {
                    try modelContext.save()
                    logger.debug("User data saved successfully")
                } catch {
                    logger.error("Failed to save user data: \(error.localizedDescription)")
                }
            } else {
                // User signed out
                logger.info("Auth state changed: user signed out")
                self.currentUser = nil
            }
        }
    }

    private func fetchUserByUID(_ uid: String) -> User? {
        guard let modelContext = modelContext else {
            logger.error("Model context not configured when fetching user by UID")
            return nil
        }

        let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.uid == uid })
        do {
            let users = try modelContext.fetch(descriptor)
            if let user = users.first {
                logger.debug("Found existing user with UID: \(uid)")
                return user
            } else {
                logger.debug("No user found with UID: \(uid)")
                return nil
            }
        } catch {
            logger.error("Error fetching user: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Authentication Methods

    func signIn(email: String, password: String) -> Future<User, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                let error = NSError(
                    domain: "UserService", code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "UserService instance is nil"])
                self?.logger.error("Sign in failed: UserService instance is nil")
                promise(.failure(error))
                return
            }

            self.logger.info("Attempting sign in for email: \(email)")
            self.isAuthenticating = true

            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                self.isAuthenticating = false

                if let error = error {
                    self.logger.error("Sign in failed: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }

                guard let firebaseUser = authResult?.user else {
                    let error = NSError(
                        domain: "UserService", code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "User not found after authentication"]
                    )
                    self.logger.error("Sign in succeeded but user is nil")
                    promise(.failure(error))
                    return
                }

                self.logger.info("Sign in successful for user: \(firebaseUser.uid)")

                // Directly handle the auth change to ensure the user is set
                guard let user = self.currentUser else {
                    let error = NSError(
                        domain: "UserService", code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "User not found after authentication"
                        ])
                    self.logger.error("User not set in currentUser after successful sign in")
                    promise(.failure(error))
                    return
                }

                self.logger.debug("Sign in process completed successfully")
                promise(.success(user))
            }
        }
    }

    func signUp(email: String, password: String, displayName: String) -> Future<User, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                let error = NSError(
                    domain: "UserService", code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "UserService instance is nil"])
                self?.logger.error("Sign up failed: UserService instance is nil")
                promise(.failure(error))
                return
            }

            self.logger.info("Starting sign up process for email: \(email)")
            self.isAuthenticating = true

            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    self.logger.error("Firebase createUser failed: \(error.localizedDescription)")
                    if let errorCode = AuthErrorCode(rawValue: (error as NSError).code) {
                        self.logger.error("Firebase Auth Error Code: \(errorCode.rawValue)")
                    }
                    self.isAuthenticating = false
                    promise(.failure(error))
                    return
                }

                guard let firebaseUser = authResult?.user else {
                    self.logger.error("authResult?.user is nil after successful createUser")
                    self.isAuthenticating = false
                    let error = NSError(
                        domain: "UserService", code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "User not created"])
                    promise(.failure(error))
                    return
                }

                self.logger.info(
                    "User created successfully in Firebase with UID: \(firebaseUser.uid)")
                self.logger.debug("Updating profile with displayName: \(displayName)")

                // Update display name
                let changeRequest = firebaseUser.createProfileChangeRequest()
                changeRequest.displayName = displayName

                changeRequest.commitChanges { error in
                    if let error = error {
                        self.logger.error("Failed to update profile: \(error.localizedDescription)")
                        self.isAuthenticating = false
                        promise(.failure(error))
                        return
                    }

                    self.logger.debug("Profile updated successfully, reloading user")

                    // Refresh the user to get updated profile
                    firebaseUser.reload { error in
                        if let error = error {
                            self.logger.error(
                                "Failed to reload user: \(error.localizedDescription)")
                            self.isAuthenticating = false
                            promise(.failure(error))
                            return
                        }

                        // Now handle the updated user
                        Task { @MainActor in
                            self.handleAuthStateChange(firebaseUser: firebaseUser)

                            guard let user = self.currentUser else {
                                self.logger.error("User not found after creation and reload")
                                let error = NSError(
                                    domain: "UserService", code: 2,
                                    userInfo: [
                                        NSLocalizedDescriptionKey: "User not found after creation"
                                    ])
                                promise(.failure(error))
                                return
                            }
                            self.isAuthenticating = false
                            self.logger.info(
                                "Sign up completed successfully for user: \(user.uid ?? "-")")
                            promise(.success(user))
                        }
                    }
                }
            }
        }
    }

    func signOut() -> Future<Void, Error> {
        return Future { [weak self] promise in
            self?.logger.info("Attempting to sign out user")
            do {
                try Auth.auth().signOut()
                self?.logger.info("User signed out successfully")
                promise(.success(()))
            } catch {
                self?.logger.error("Sign out failed: \(error.localizedDescription)")
                promise(.failure(error))
            }
        }
    }

    func setCurrentUser(user: User) {
        logger.debug("Manually setting current user: \(user.uid ?? "-")")
        self.currentUser = user
    }
}
