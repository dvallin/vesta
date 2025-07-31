import Foundation
import SwiftData

protocol SyncableEntity: AnyObject {
    var uid: String { get set }
    var owner: User? { get set }
    var isShared: Bool { get set }
    var dirty: Bool { get set }
    var deletedAt: Date? { get set }

    func markAsDirty()

    func toDTO() -> [String: Any]
}

extension SyncableEntity {
    func markAsDirty() {
        self.dirty = true
    }
    func markAsSynced() {
        self.dirty = false
    }
}
