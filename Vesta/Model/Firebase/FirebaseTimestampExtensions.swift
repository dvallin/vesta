//
//  FirebaseTimestampExtensions.swift
//  Vesta
//
//  Created for Vesta
//

import FirebaseFirestore
import Foundation

// MARK: - Timestamp Extensions

extension Timestamp: @retroactive Comparable {
    public static func < (lhs: Timestamp, rhs: Timestamp) -> Bool {
        if lhs.seconds != rhs.seconds {
            return lhs.seconds < rhs.seconds
        }
        return lhs.nanoseconds < rhs.nanoseconds
    }

    public static func > (lhs: Timestamp, rhs: Timestamp) -> Bool {
        if lhs.seconds != rhs.seconds {
            return lhs.seconds > rhs.seconds
        }
        return lhs.nanoseconds > rhs.nanoseconds
    }

    public static func <= (lhs: Timestamp, rhs: Timestamp) -> Bool {
        if lhs.seconds != rhs.seconds {
            return lhs.seconds < rhs.seconds
        }
        return lhs.nanoseconds <= rhs.nanoseconds
    }

    public static func >= (lhs: Timestamp, rhs: Timestamp) -> Bool {
        if lhs.seconds != rhs.seconds {
            return lhs.seconds > rhs.seconds
        }
        return lhs.nanoseconds >= rhs.nanoseconds
    }
}

// MARK: - UserDefaults Extension for Timestamp

extension UserDefaults {
    func setTimestamp(_ timestamp: Timestamp, forKey key: String) {
        set(timestamp.seconds, forKey: "\(key)_seconds")
        set(timestamp.nanoseconds, forKey: "\(key)_nanoseconds")

        // Also store as Date for backward compatibility
        set(timestamp.dateValue(), forKey: key)
    }

    func timestamp(forKey key: String) -> Timestamp? {
        if let seconds = object(forKey: "\(key)_seconds") as? Int64,
            let nanoseconds = object(forKey: "\(key)_nanoseconds") as? Int32
        {
            return Timestamp(seconds: seconds, nanoseconds: nanoseconds)
        }

        // Fallback to Date if available
        if let date = object(forKey: key) as? Date {
            return Timestamp(date: date)
        }

        return nil
    }

    func timestampOrEpoch(forKey key: String) -> Timestamp {
        return timestamp(forKey: key) ?? Timestamp(date: Date(timeIntervalSince1970: 0))
    }
}
