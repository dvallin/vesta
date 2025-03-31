import Foundation

struct DateUtils {
    static let calendar = Calendar.current

    static func setTime(hour: Int, minute: Int, for date: Date? = nil) -> Date? {
        let baseDate = date ?? Date()
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)
    }

    static func preserveTime(from sourceDate: Date?, applying newDate: Date) -> Date? {
        guard let sourceDate = sourceDate else { return newDate }
        let timeComponents = calendar.dateComponents([.hour, .minute], from: sourceDate)
        return setTime(
            hour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, for: newDate)
    }

    static func todayStartOfday() -> Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: Date())
    }

    static func mealTime(for mealType: MealType) -> (hour: Int, minute: Int) {
        switch mealType {
        case .breakfast: return (8, 0)
        case .lunch: return (12, 0)
        case .dinner: return (18, 0)
        }
    }

    static func formattedDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}
