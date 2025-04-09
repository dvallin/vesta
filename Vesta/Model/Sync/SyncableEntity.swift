import Foundation
import SwiftData

protocol SyncableEntity: AnyObject {
    var uid: String? { get set }
    var owner: User? { get set }
    var lastModifiedBy: User? { get set }
    var dirty: Bool { get set }

    func markAsDirty(_ currentUser: User)

    func toDTO() -> [String: Any]
}

extension SyncableEntity {
    func markAsDirty(_ currentUser: User) {
        self.dirty = true
        self.lastModifiedBy = currentUser
    }
    func markAsSynced() {
        self.dirty = false
    }
}
