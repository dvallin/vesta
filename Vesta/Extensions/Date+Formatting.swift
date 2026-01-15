//
//  Date+Formatting.swift
//  Vesta
//
//  Created for Vesta
//

import Foundation

extension Date {
    /// Returns a formatted string representation for display in lists
    /// - Parameters:
    ///   - includeTime: Whether to include time component in the formatted string
    /// - Returns: A formatted string representation
    func formattedForDisplay(includeTime: Bool = true) -> String {
        // Handle relative dates (today, tomorrow, yesterday)
        if Calendar.current.isDateInToday(self) {
            if includeTime {
                let timeString = getLocalizedTimeString()
                let format = String(localized: "date.relative.today.with-time")
                return String(format: format, timeString)
            } else {
                return String(localized: "date.relative.today")
            }
        } else if Calendar.current.isDateInTomorrow(self) {
            if includeTime {
                let timeString = getLocalizedTimeString()
                let format = String(localized: "date.relative.tomorrow.with-time")
                return String(format: format, timeString)
            } else {
                return String(localized: "date.relative.tomorrow")
            }
        } else if Calendar.current.isDateInYesterday(self) {
            if includeTime {
                let timeString = getLocalizedTimeString()
                let format = String(localized: "date.relative.yesterday.with-time")
                return String(format: format, timeString)
            } else {
                return String(localized: "date.relative.yesterday")
            }
        }
        // Handle dates within the current week
        else if isWithinCurrentWeek() {
            let weekdayName = getLocalizedWeekdayName()
            if includeTime {
                let timeString = getLocalizedTimeString()
                let format = String(localized: "date.weekday.with-time")
                return String(format: format, weekdayName, timeString)
            } else {
                return weekdayName
            }
        }
        // Default formatting for other dates
        else {
            return formatStandardDate(includeTime: includeTime)
        }
    }

    /// Standard date format for dates not within current week
    private func formatStandardDate(includeTime: Bool) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = includeTime ? .short : .none
        return dateFormatter.string(from: self)
    }

    /// Gets the localized weekday name for this date
    private func getLocalizedWeekdayName() -> String {
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEEE"
        return weekdayFormatter.string(from: self)
    }

    /// Gets the localized time string for this date
    private func getLocalizedTimeString() -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        return timeFormatter.string(from: self)
    }

    /// Checks if the date is within the current calendar week
    private func isWithinCurrentWeek() -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get the start of the week containing today
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = (weekday - calendar.firstWeekday + 7) % 7

        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: today)
        else {
            return false
        }

        // Get end of the week
        guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            return false
        }

        // Check if self is between start and end of week
        let startOfSelfDay = calendar.startOfDay(for: self)
        return startOfSelfDay >= startOfWeek && startOfSelfDay <= endOfWeek
    }
}
