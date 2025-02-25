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
            .navigationBarTitle(navigationBarTitle, displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                }
            }
        }
    }

    func onSave() {
        details = value
        presentationMode.wrappedValue.dismiss()
    }
}
