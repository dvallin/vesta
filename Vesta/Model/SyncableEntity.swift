import Foundation
import SwiftData

protocol SyncableEntity: AnyObject {
    var owner: User? { get set }
    var lastModified: Date { get set }
    var dirty: Bool { get set }

    func markAsDirty()
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
