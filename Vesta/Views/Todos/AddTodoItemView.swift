import SwiftUI

struct AddTodoItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var details: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Details", text: $details)
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
