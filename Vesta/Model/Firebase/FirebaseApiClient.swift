import Combine
import FirebaseFirestore
import Foundation
import os

class FirebaseAPIClient {
    let db = Firestore.firestore()
    let logger = Logger(subsystem: "com.app.Vesta", category: "Synchronization")
    var listeners: [String: ListenerRegistration] = [:]
}

// MARK: - Error Types
extension FirebaseAPIClient {
    enum FirebaseError: Error, LocalizedError {
        case batchWriteFailure
        case invalidEntityData
        case unauthorizedSharedEntityModification
        case notFound
        case unknown

        var errorDescription: String? {
            switch self {
            case .batchWriteFailure:
                return "Failed to write batch to Firestore"
            case .invalidEntityData:
                return "Invalid or incomplete entity data"
            case .unauthorizedSharedEntityModification:
                return "Unauthorized modification of shared entity"
            case .notFound:
                return "Resource not found"
            case .unknown:
                return "An unknown error occurred"
            }
        }
    }
}
