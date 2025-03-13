import SwiftUI

struct DueDateRecurrenceSection: View {
    @Binding var dueDate: Date?
    @Binding var recurrenceFrequency: RecurrenceFrequency?
    @Binding var recurrenceType: RecurrenceType?

    var body: some View {
        Section(
            header: Text(
                NSLocalizedString(
                    "DueDateRecurrenceHeader", comment: "Section header for due date and recurrence"
                ))
        ) {
            Toggle(
                NSLocalizedString("Enable Due Date", comment: "Toggle for enabling due date"),
                isOn: Binding(
                    get: { dueDate != nil },
                    set: { newValue in
                        dueDate = newValue ? Date() : nil
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
                    displayedComponents: [.date, .hourAndMinute]
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
