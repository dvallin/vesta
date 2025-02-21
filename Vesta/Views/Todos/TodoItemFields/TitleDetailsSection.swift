import SwiftUI

struct TitleDetailsSection: View {
    @Binding var title: String
    @Binding var details: String
    @FocusState.Binding var focusedField: String?

    var body: some View {
        Section(header: Text("Todo Details")) {
            TextField("Title", text: $title)
                .focused($focusedField, equals: "title")
                .font(.title)
                .submitLabel(.next)
                .onSubmit {
                    // Move focus to details on return.
                    focusedField = "details"
                }

            TextEditor(text: $details)
                .focused($focusedField, equals: "details")
                .frame(minHeight: 100)
        }
    }
}
