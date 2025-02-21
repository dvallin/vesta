import SwiftUI

struct DueDateRecurrenceSection: View {
    @Binding var dueDate: Date?
    @Binding var recurrenceFrequency: RecurrenceFrequency?
    @Binding var recurrenceType: RecurrenceType?

    var body: some View {
        Section(header: Text("Due Date & Recurrence")) {
            Toggle(
                "Enable Due Date",
                isOn: Binding(
                    get: { dueDate != nil },
                    set: { newValue in
                        dueDate = newValue ? Date() : nil
                    }
                )
            )

            if let actualDueDate = dueDate {
                DatePicker(
                    "Due Date",
                    selection: Binding(
                        get: { actualDueDate },
                        set: { newValue in
                            dueDate = newValue
                        }
                    ),
                    displayedComponents: .date
                )

                Picker("Recurrence", selection: $recurrenceFrequency) {
                    Text("None").tag(Optional<RecurrenceFrequency>.none)
                    Text("Daily").tag(RecurrenceFrequency?.some(.daily))
                    Text("Weekly").tag(RecurrenceFrequency?.some(.weekly))
                    Text("Monthly").tag(RecurrenceFrequency?.some(.monthly))
                    Text("Yearly").tag(RecurrenceFrequency?.some(.yearly))
                }
                .pickerStyle(.segmented)

                Toggle(
                    "Fixed Recurrence",
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
