import SwiftUI

struct EditDetailsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) var presentationMode
    @Binding var details: String
    @State private var value: String
    var navigationBarTitle: String

    init(navigationBarTitle: String, details: Binding<String>) {
        self.navigationBarTitle = navigationBarTitle
        self._details = details
        self._value = State(initialValue: details.wrappedValue)
    }

    var body: some View {
        NavigationView {
            Form {
                TextEditor(text: $value)
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
    }

    func onSave() {
        details = value
        presentationMode.wrappedValue.dismiss()
    }
}
