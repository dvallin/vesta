import SwiftUI

struct DayHeaderView: View {
    let date: Date

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(date)
    }

    private var isYesterday: Bool {
        Calendar.current.isDateInYesterday(date)
    }

    private var dayName: String {
        if isToday {
            return NSLocalizedString("Today", comment: "Today header")
        } else if isTomorrow {
            return NSLocalizedString("Tomorrow", comment: "Tomorrow header")
        } else if isYesterday {
            return NSLocalizedString("Yesterday", comment: "Yesterday header")
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(dayName)
                .font(.headline)
                .foregroundColor(isToday ? .accentColor : .primary)

            Text(formattedDate)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

#Preview {
    List {
        Section {
            Text("Meal 1")
            Text("Meal 2")
        } header: {
            DayHeaderView(date: Date())
        }

        Section {
            Text("Meal 3")
        } header: {
            DayHeaderView(date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
        }

        Section {
            Text("Meal 4")
        } header: {
            DayHeaderView(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        }

        Section {
            Text("Meal 5")
        } header: {
            DayHeaderView(date: Calendar.current.date(byAdding: .day, value: 3, to: Date())!)
        }
    }
}
