import FirebaseAuth

extension User {

    convenience init(firebaseUser: FirebaseAuth.User) {
        self.init(
            uid: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL?.absoluteString,
            isEmailVerified: firebaseUser.isEmailVerified,
            createdAt: firebaseUser.metadata.creationDate ?? Date(),
            lastSignInAt: firebaseUser.metadata.lastSignInDate ?? Date()
        )
    }

    func update(from firebaseUser: FirebaseAuth.User) {
        self.email = firebaseUser.email
        self.displayName = firebaseUser.displayName
        self.photoURL = firebaseUser.photoURL?.absoluteString
        self.isEmailVerified = firebaseUser.isEmailVerified
        self.lastSignInAt = firebaseUser.metadata.lastSignInDate ?? Date()
    }
}
