import SwiftUI

struct DueDateRecurrenceSection: View {
    @Binding var dueDate: Date?
    @Binding var recurrenceFrequency: RecurrenceFrequency?
    @Binding var recurrenceType: RecurrenceType?
    @Binding var ignoreTimeComponent: Bool

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
                        dueDate = newValue ? DateUtils.tomorrowAtMidnight() : nil
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
                    NSLocalizedString(
                        "Ignore Time Component", comment: "Toggle for ignoring time component"),
                    isOn: $ignoreTimeComponent
                )

                Picker(
                    NSLocalizedString("Recurrence", comment: "Label for recurrence picker"),
                    selection: $recurrenceFrequency
                ) {
                    Text(NSLocalizedString("None", comment: "No recurrence option"))
                        .tag(Optional<RecurrenceFrequency>.none)
                    ForEach(RecurrenceFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.displayName).tag(Optional(frequency))
                    }
                }
                .pickerStyle(.segmented)

                Toggle(
                    NSLocalizedString("Fixed Recurrence", comment: "Toggle for fixed recurrence"),
                    isOn: Binding(
                        get: { recurrenceType == .some(.fixed) },
                        set: { newValue in
                            recurrenceType = newValue ? .fixed : .flexible
                        }
                    )
                )
            }
        }
    }
}

#Preview {
    Form {
        DueDateRecurrenceSection(
            dueDate: .constant(Date()),
            recurrenceFrequency: .constant(.weekly),
            recurrenceType: .constant(.fixed),
            ignoreTimeComponent: .constant(true)
        )
    }
}

#Preview("No Due Date") {
    Form {
        DueDateRecurrenceSection(
            dueDate: .constant(nil),
            recurrenceFrequency: .constant(nil),
            recurrenceType: .constant(nil),
            ignoreTimeComponent: .constant(true)
        )
    }
}

#Preview("With Different Recurrence") {
    Form {
        DueDateRecurrenceSection(
            dueDate: .constant(Date()),
            recurrenceFrequency: .constant(.monthly),
            recurrenceType: .constant(.flexible),
            ignoreTimeComponent: .constant(false)
        )
    }
}

#Preview("Due Date Only") {
    Form {
        DueDateRecurrenceSection(
            dueDate: .constant(Date()),
            recurrenceFrequency: .constant(nil),
            recurrenceType: .constant(nil),
            ignoreTimeComponent: .constant(true)
        )
    }
}
