import SwiftUI

enum RepeatOption: String, CaseIterable {
    case never = "never"
    case afterCompletion = "after_completion"
    case onSchedule = "on_schedule"

    var displayName: String {
        switch self {
        case .never:
            return NSLocalizedString("Never", comment: "No repeat option")
        case .afterCompletion:
            return NSLocalizedString("After completion", comment: "Repeat after completion option")
        case .onSchedule:
            return NSLocalizedString("On a schedule", comment: "Repeat on schedule option")
        }
    }
}

enum ScheduleOption: String, CaseIterable {
    case interval = "interval"
    case weekdays = "weekdays"

    var displayName: String {
        switch self {
        case .interval:
            return NSLocalizedString(
                "Interval", comment: "Interval schedule option")
        case .weekdays:
            return NSLocalizedString("Weekdays", comment: "Weekdays schedule option")
        }
    }
}

struct DueDateRecurrenceSection: View {
    @Binding var dueDate: Date?
    @Binding var recurrenceFrequency: RecurrenceFrequency?
    @Binding var recurrenceInterval: Int?
    @Binding var recurrenceType: RecurrenceType?
    @Binding var repeatOn: [DayOfWeek]?
    @Binding var ignoreTimeComponent: Bool

    @State private var repeatOption: RepeatOption = .never
    @State private var scheduleOption: ScheduleOption = .interval
    @State private var localInterval: Int = 1
    @State private var localFrequency: RecurrenceFrequency = .daily

    var body: some View {
        Section(
            header: Text(
                NSLocalizedString(
                    "Due Date & Recurrence", comment: "Section header for due date and recurrence"
                ))
        ) {
            Toggle(
                NSLocalizedString("Enable Due Date", comment: "Toggle for enabling due date"),
                isOn: Binding(
                    get: { dueDate != nil },
                    set: { newValue in
                        dueDate = newValue ? DateUtils.todayStartOfday() : nil
                        if !newValue {
                            resetRecurrenceSettings()
                        }
                    }
                )
            )

            if let actualDueDate = dueDate {
                DatePicker(
                    NSLocalizedString("Due Date", comment: "Label for due date picker"),
                    selection: Binding(
                        get: { actualDueDate },
                        set: { newValue in
                            dueDate = newValue
                        }
                    ),
                    displayedComponents: ignoreTimeComponent ? [.date] : [.date, .hourAndMinute]
                )

                Toggle(
                    NSLocalizedString("All-day", comment: "Toggle for all-day events"),
                    isOn: $ignoreTimeComponent
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("Repeat", comment: "Repeat section header"))
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Picker("Repeat", selection: $repeatOption) {
                        ForEach(RepeatOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: repeatOption) { _, newValue in
                        handleRepeatOptionChange(newValue)
                    }

                    if repeatOption == .afterCompletion {
                        HStack {
                            Text(NSLocalizedString("Every", comment: "Every interval label"))
                            TextField(
                                NSLocalizedString("1", comment: "Default interval"),
                                value: $localInterval,
                                formatter: NumberFormatter()
                            )
                            .keyboardType(.numberPad)
                            .frame(width: 50)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                            Picker("", selection: $localFrequency) {
                                ForEach(RecurrenceFrequency.allCases, id: \.self) { frequency in
                                    Text(
                                        getFrequencyDisplayName(frequency, interval: localInterval)
                                    )
                                    .tag(frequency)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: localFrequency) { _, newValue in
                                updateRecurrenceSettings()
                            }
                            .onChange(of: localInterval) { _, newValue in
                                updateRecurrenceSettings()
                            }

                            Spacer()
                        }
                    }

                    if repeatOption == .onSchedule {
                        Picker("Schedule Type", selection: $scheduleOption) {
                            ForEach(ScheduleOption.allCases, id: \.self) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: scheduleOption) { _, newValue in
                            handleScheduleOptionChange(newValue)
                        }

                        if scheduleOption == .interval {
                            HStack {
                                Text(NSLocalizedString("Every", comment: "Every interval label"))
                                TextField(
                                    NSLocalizedString("1", comment: "Default interval"),
                                    value: $localInterval,
                                    formatter: NumberFormatter()
                                )
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                                Picker("", selection: $localFrequency) {
                                    ForEach(RecurrenceFrequency.allCases, id: \.self) { frequency in
                                        Text(
                                            getFrequencyDisplayName(
                                                frequency, interval: localInterval)
                                        )
                                        .tag(frequency)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .onChange(of: localFrequency) { _, newValue in
                                    updateRecurrenceSettings()
                                }
                                .onChange(of: localInterval) { _, newValue in
                                    updateRecurrenceSettings()
                                }

                                Spacer()
                            }
                        } else if scheduleOption == .weekdays {
                            VStack(alignment: .leading) {
                                LazyVGrid(
                                    columns: Array(repeating: GridItem(.flexible()), count: 7),
                                    spacing: 8
                                ) {
                                    ForEach(DayOfWeek.allCases, id: \.self) { day in
                                        WeekdayToggle(
                                            day: day,
                                            isSelected: Binding(
                                                get: { repeatOn?.contains(day) == true },
                                                set: { isSelected in
                                                    toggleWeekday(day, isSelected: isSelected)
                                                }
                                            )
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            initializeLocalState()
        }
    }

    private func getFrequencyDisplayName(_ frequency: RecurrenceFrequency, interval: Int) -> String
    {
        let plural = interval != 1

        switch frequency {
        case .daily:
            return plural
                ? NSLocalizedString("days", comment: "Days plural")
                : NSLocalizedString("day", comment: "Day singular")
        case .weekly:
            return plural
                ? NSLocalizedString("weeks", comment: "Weeks plural")
                : NSLocalizedString("week", comment: "Week singular")
        case .monthly:
            return plural
                ? NSLocalizedString("months", comment: "Months plural")
                : NSLocalizedString("month", comment: "Month singular")
        case .yearly:
            return plural
                ? NSLocalizedString("years", comment: "Years plural")
                : NSLocalizedString("year", comment: "Year singular")
        }
    }

    private func initializeLocalState() {
        if recurrenceFrequency != nil {
            if recurrenceType == .flexible {
                repeatOption = .afterCompletion
            } else {
                repeatOption = .onSchedule
                if repeatOn != nil && !repeatOn!.isEmpty {
                    scheduleOption = .weekdays
                } else {
                    scheduleOption = .interval
                }
            }
            localInterval = recurrenceInterval ?? 1
            localFrequency = recurrenceFrequency ?? .daily
        } else {
            repeatOption = .never
        }
    }

    private func handleRepeatOptionChange(_ newOption: RepeatOption) {
        switch newOption {
        case .never:
            resetRecurrenceSettings()
        case .afterCompletion:
            recurrenceType = .flexible
            recurrenceFrequency = localFrequency
            recurrenceInterval = localInterval
            repeatOn = nil
        case .onSchedule:
            recurrenceType = .fixed
            if scheduleOption == .weekdays && localFrequency == .weekly {
                // Keep existing weekday selection or set default
                if repeatOn == nil || repeatOn!.isEmpty {
                    repeatOn = [.monday]  // Default to Monday
                }
            } else {
                repeatOn = nil
            }
            recurrenceFrequency = localFrequency
            recurrenceInterval = localInterval
        }
    }

    private func handleScheduleOptionChange(_ newOption: ScheduleOption) {
        if newOption == .weekdays {
            localFrequency = .weekly
            if repeatOn == nil || repeatOn!.isEmpty {
                repeatOn = [.monday]  // Default to Monday
            }
        } else {
            repeatOn = nil
        }
        updateRecurrenceSettings()
    }

    private func updateRecurrenceSettings() {
        if repeatOption != .never {
            recurrenceFrequency = localFrequency
            recurrenceInterval = localInterval
        }
    }

    private func resetRecurrenceSettings() {
        recurrenceFrequency = nil
        recurrenceInterval = nil
        recurrenceType = nil
        repeatOn = nil
    }

    private func toggleWeekday(_ day: DayOfWeek, isSelected: Bool) {
        var currentDays = repeatOn ?? []

        if isSelected {
            if !currentDays.contains(day) {
                currentDays.append(day)
            }
        } else {
            currentDays.removeAll { $0 == day }
        }

        repeatOn =
            currentDays.isEmpty
            ? nil
            : currentDays.sorted {
                DayOfWeek.allCases.firstIndex(of: $0)! < DayOfWeek.allCases.firstIndex(of: $1)!
            }

        // Ensure we have weekly frequency when using weekdays
        if !currentDays.isEmpty {
            localFrequency = .weekly
            updateRecurrenceSettings()
        }
    }
}

struct WeekdayToggle: View {
    let day: DayOfWeek
    @Binding var isSelected: Bool

    private var shortDayName: String {
        switch day {
        case .sunday:
            return NSLocalizedString("Sun", comment: "Sunday short")
        case .monday:
            return NSLocalizedString("Mon", comment: "Monday short")
        case .tuesday:
            return NSLocalizedString("Tue", comment: "Tuesday short")
        case .wednesday:
            return NSLocalizedString("Wed", comment: "Wednesday short")
        case .thursday:
            return NSLocalizedString("Thu", comment: "Thursday short")
        case .friday:
            return NSLocalizedString("Fri", comment: "Friday short")
        case .saturday:
            return NSLocalizedString("Sat", comment: "Saturday short")
        }
    }

    var body: some View {
        Button(action: {
            isSelected.toggle()
        }) {
            Text(shortDayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 35, height: 35)
                .background(
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    Form {
        DueDateRecurrenceSection(
            dueDate: .constant(Date()),
            recurrenceFrequency: .constant(.weekly),
            recurrenceInterval: .constant(1),
            recurrenceType: .constant(.fixed),
            repeatOn: .constant([.monday, .wednesday, .friday]),
            ignoreTimeComponent: .constant(true)
        )
    }
}

#Preview("No Due Date") {
    Form {
        DueDateRecurrenceSection(
            dueDate: .constant(nil),
            recurrenceFrequency: .constant(nil),
            recurrenceInterval: .constant(nil),
            recurrenceType: .constant(nil),
            repeatOn: .constant(nil),
            ignoreTimeComponent: .constant(true)
        )
    }
}

#Preview("After Completion") {
    Form {
        DueDateRecurrenceSection(
            dueDate: .constant(Date()),
            recurrenceFrequency: .constant(.daily),
            recurrenceInterval: .constant(3),
            recurrenceType: .constant(.flexible),
            repeatOn: .constant(nil),
            ignoreTimeComponent: .constant(true)
        )
    }
}

#Preview("Weekdays Schedule") {
    Form {
        DueDateRecurrenceSection(
            dueDate: .constant(Date()),
            recurrenceFrequency: .constant(.weekly),
            recurrenceInterval: .constant(1),
            recurrenceType: .constant(.fixed),
            repeatOn: .constant([.monday, .tuesday, .thursday]),
            ignoreTimeComponent: .constant(false)
        )
    }
}

#Preview("Due Date Only") {
    Form {
        DueDateRecurrenceSection(
            dueDate: .constant(Date()),
            recurrenceFrequency: .constant(nil),
            recurrenceInterval: .constant(nil),
            recurrenceType: .constant(nil),
            repeatOn: .constant(nil),
            ignoreTimeComponent: .constant(true)
        )
    }
}
