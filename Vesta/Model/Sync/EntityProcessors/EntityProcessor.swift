import Foundation
import OSLog
import SwiftData

protocol EntityProcessor {
    var modelContext: ModelContext { get }
    var logger: Logger { get }

    func process(entities: [[String: Any]]) async throws
}

class BaseEntityProcessor {
    let modelContext: ModelContext
    let logger: Logger

    init(modelContext: ModelContext, logger: Logger) {
        self.modelContext = modelContext
        self.logger = logger
    }
}
