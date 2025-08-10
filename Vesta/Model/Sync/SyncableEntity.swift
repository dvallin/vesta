import Foundation
import SwiftData

protocol SyncableEntity: AnyObject {
    var uid: String { get set }
    var owner: User? { get set }
    var isShared: Bool { get set }
    var dirty: Bool { get set }
    var deletedAt: Date? { get set }
    var expireAt: Date? { get set }

    func markAsDirty()
    func softDelete(currentUser: User)
    func restore(currentUser: User)

    func toDTO() -> [String: Any]
}

extension SyncableEntity {
    func markAsDirty() {
        self.dirty = true
    }
    func markAsSynced() {
        self.dirty = false
    }

    /// Sets expireAt to 30 days from now for Firestore TTL cleanup
    func setExpiration(from date: Date = Date()) {
        self.expireAt = Calendar.current.date(byAdding: .day, value: 30, to: date)
    }

    /// Clears expiration date when restoring
    func clearExpiration() {
        self.expireAt = nil
    }
}
