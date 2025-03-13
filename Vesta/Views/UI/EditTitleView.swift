import SwiftUI

struct EditTitleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) var presentationMode
    @Binding var title: String
    @State private var value: String
    var navigationBarTitle: String

    init(navigationBarTitle: String, title: Binding<String>) {
        self.navigationBarTitle = navigationBarTitle
        self._title = title
        self._value = State(initialValue: title.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(
                    NSLocalizedString("Title", comment: "Title input placeholder"), text: $value
                )
                .font(.title)
                .submitLabel(.done)
                .onSubmit {
                    onSave()
                }
            }
            .navigationTitle(navigationBarTitle)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(NSLocalizedString("Save", comment: "Save button")) {
                            onSave()
                        }
                    }
                #endif
            }
        }
        .presentationDetents([.medium, .large])
    }

    func onSave() {
        title = value
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    EditTitleView(
        navigationBarTitle: "Edit Title",
        title: .constant("Sample Task Title")
    )
    .modelContainer(for: TodoItem.self)
}

#Preview("Empty") {
    EditTitleView(
        navigationBarTitle: "Edit Title",
        title: .constant("")
    )
    .modelContainer(for: TodoItem.self)
}

#Preview("Long Title") {
    EditTitleView(
        navigationBarTitle: "Edit Title",
        title: .constant(
            "This is a very long task title that might need to wrap to multiple lines or be truncated depending on the available space"
        )
    )
    .modelContainer(for: TodoItem.self)
}
