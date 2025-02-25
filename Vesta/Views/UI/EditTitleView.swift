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
        NavigationView {
            Form {
                TextField("Title", text: $value)
                    .font(.title)
                    .submitLabel(.done)
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
        .presentationDetents([.medium, .large])
    }

    func onSave() {
        title = value
        presentationMode.wrappedValue.dismiss()
    }
}
