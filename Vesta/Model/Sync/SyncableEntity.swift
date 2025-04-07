import Foundation
import SwiftData

protocol SyncableEntity: AnyObject {
    var uid: String? { get set }
    var owner: User? { get set }
    var lastModified: Date { get set }
    var dirty: Bool { get set }

    func markAsDirty()

    func toDTO() -> [String: Any]
}

extension SyncableEntity {
    func markAsDirty() {
        self.lastModified = Date()
        self.dirty = true
    }
    func markAsSynced() {
        self.dirty = false
    }
}
