import Foundation

/// A struct representing user search results
/// This is used to display search results without adding them to the SwiftData store
struct UserSearchResult: Identifiable, Hashable {
    let id: String
    let uid: String
    let email: String?
    let displayName: String?
    let photoURL: String?
    
    init(uid: String, email: String? = nil, displayName: String? = nil, photoURL: String? = nil) {
        self.id = uid
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
    }
    
    /// Creates an Invite object from this search result
    func toInvite(from sender: User) -> Invite {
        // Create a unique ID with timestamp to match Firebase format
        let timestamp = Date().timeIntervalSince1970    
        return Invite(
            uid: "invite_\(sender.uid)_\(uid)_\(timestamp)",
            createdAt: Date(),
            senderUid: sender.uid,
            recipientUid: uid,
            senderEmail: sender.email,
            senderDisplayName: sender.displayName,
            senderPhotoURL: sender.photoURL,
            recipientEmail: email,
            recipientDisplayName: displayName,
            recipientPhotoURL: photoURL
        )
    }
}
