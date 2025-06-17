import Combine
import FirebaseFirestore
import Foundation
import os

class FirebaseAPIClient {
    let db = Firestore.firestore()
    let logger = Logger(subsystem: "com.app.Vesta", category: "Synchronization")
    var listeners: [String: ListenerRegistration] = [:]
    
    func sanitizeDTO(_ dto: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]

        for (key, value) in dto {
            if let date = value as? Date {
                // Convert Date to Timestamp for Firestore
                result[key] = Timestamp(date: date)
            } else if let array = value as? [[String: Any]] {
                // Recursively sanitize arrays of dictionaries
                result[key] = array.map { sanitizeDTO($0) }
            } else if let nestedDict = value as? [String: Any] {
                // Recursively sanitize nested dictionaries
                result[key] = sanitizeDTO(nestedDict)
            } else {
                // Use the value as is
                result[key] = value
            }
        }

        return result
    }
    
    /// Converts Firestore data types to Swift native types
    /// - Parameter data: Raw data from Firestore
    /// - Returns: Data with converted types
    func desanitizeDTO(_ data: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        
        for (key, value) in data {
            if let timestamp = value as? Timestamp {
                // Convert Timestamp to Date
                result[key] = timestamp.dateValue()
            } else if let array = value as? [[String: Any]] {
                // Recursively desanitize arrays of dictionaries
                result[key] = array.map { desanitizeDTO($0) }
            } else if let nestedDict = value as? [String: Any] {
                // Recursively desanitize nested dictionaries
                result[key] = desanitizeDTO(nestedDict)
            } else {
                // Use the value as is
                result[key] = value
            }
        }
        
        return result
    }
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
