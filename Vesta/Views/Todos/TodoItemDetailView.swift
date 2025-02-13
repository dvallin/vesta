import SwiftData
import SwiftUI

struct TodoItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: TodoItem

    var body: some View {
        Form {
            Section {
                TextField("Title", text: $item.title)
                TextField("Description", text: $item.details)
                DatePicker(
                    "Due Date",
                    selection: Binding(
                        get: { item.dueDate ?? Date() },
                        set: { item.dueDate = $0 }
                    ),
                    displayedComponents: .date)
                Toggle("Completed", isOn: $item.isCompleted)
                Picker("Recurrence", selection: $item.recurrenceFrequency) {
                    Text("None").tag(Optional<RecurrenceFrequency>.none)
                    Text("Daily").tag(RecurrenceFrequency?.some(.daily))
                    Text("Weekly").tag(RecurrenceFrequency?.some(.weekly))
                    Text("Monthly").tag(RecurrenceFrequency?.some(.monthly))
                    Text("Yearly").tag(RecurrenceFrequency?.some(.yearly))
                }
            }
            Section {
                Button(action: markAsDone) {
                    Label("Mark as Done", systemImage: "checkmark.circle")
                }
                .disabled(item.isCompleted)
            }
        }
        .navigationTitle(item.title)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func markAsDone() {
        withAnimation {
            item.markAsDone(modelContext: modelContext)
        }
    }
}
