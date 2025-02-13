import SwiftUI

struct AddTodoItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var details: String = ""
    @State private var dueDate: Date? = nil
    @State private var recurrenceFrequency: RecurrenceFrequency? = nil

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Description", text: $details)
                    DatePicker(
                        "Due Date",
                        selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ),
                        displayedComponents: .date)
                    Picker("Recurrence", selection: $recurrenceFrequency) {
                        Text("None").tag(Optional<RecurrenceFrequency>.none)
                        Text("Daily").tag(RecurrenceFrequency?.some(.daily))
                        Text("Weekly").tag(RecurrenceFrequency?.some(.weekly))
                        Text("Monthly").tag(RecurrenceFrequency?.some(.monthly))
                        Text("Yearly").tag(RecurrenceFrequency?.some(.yearly))
                    }
                }
            }
            .navigationTitle("Add Todo Item")
            #if os(iOS)
                .navigationBarItems(
                    leading: Button("Cancel") {
                        dismiss()
                    },
                    trailing: Button("Save") {
                        addTodoItem()
                        dismiss()
                    })
            #endif
        }
    }

    private func addTodoItem() {
        let newItem = TodoItem(
            title: title,
            details: details,
            dueDate: dueDate,
            recurrenceFrequency: recurrenceFrequency
        )
        modelContext.insert(newItem)
    }
}
