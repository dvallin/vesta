import SwiftUI

struct AddTodoItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var details: String = ""

    @State private var dueDate: Date? = nil
    @State private var recurrenceFrequency: RecurrenceFrequency? = nil
    @State private var recurrenceType: RecurrenceType? = nil

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Title", text: $title)
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)

                TextEditor(text: $details)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8).stroke(.tertiary, lineWidth: 1)
                    )
                    .padding(.horizontal)

                Spacer()

                Toggle(
                    "Enable Due Date",
                    isOn: Binding(
                        get: { dueDate != nil },
                        set: { newValue in dueDate = newValue ? Date() : nil }
                    )
                )
                .padding(.horizontal)

                if let dd = dueDate {
                    VStack(alignment: .leading, spacing: 8) {
                        DatePicker(
                            "Due Date",
                            selection: Binding(
                                get: { dd },
                                set: { newValue in dueDate = newValue }
                            ),
                            displayedComponents: .date
                        )
                        .padding(.horizontal)

                        Picker(
                            "Recurrence",
                            selection: Binding(
                                get: { recurrenceFrequency },
                                set: { newValue in recurrenceFrequency = newValue }
                            )
                        ) {
                            Text("None").tag(Optional<RecurrenceFrequency>.none)
                            Text("Daily").tag(RecurrenceFrequency?.some(.daily))
                            Text("Weekly").tag(RecurrenceFrequency?.some(.weekly))
                            Text("Monthly").tag(RecurrenceFrequency?.some(.monthly))
                            Text("Yearly").tag(RecurrenceFrequency?.some(.yearly))
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)

                        Toggle(
                            "Fixed Recurrence",
                            isOn: Binding(
                                get: { recurrenceType == .some(.fixed) },
                                set: { newValue in
                                    recurrenceType = newValue ? .fixed : .flexible
                                }
                            )
                        )
                        .padding(.horizontal)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Add Todo Item")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("Cancel") {
                        dismiss()
                    },
                    trailing: Button("Save") {
                        addTodoItem()
                        dismiss()
                    }
                )
            #endif
        }
    }

    private func addTodoItem() {
        let newItem = TodoItem(
            title: title,
            details: details
        )
        modelContext.insert(newItem)
    }
}

#Preview {
    return AddTodoItemView()
}
