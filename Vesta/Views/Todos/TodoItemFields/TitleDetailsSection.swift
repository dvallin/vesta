import SwiftUI

struct TitleDetailsSection: View {
    @Binding var title: String
    @Binding var details: String
    @FocusState.Binding var focusedField: String?

    var body: some View {
        Section(
            header: Text(
                NSLocalizedString("Todo Details", comment: "Section header for todo details"))
        ) {
            TextField(NSLocalizedString("Title", comment: "Title field placeholder"), text: $title)
                .focused($focusedField, equals: "title")
                .font(.title)
                .submitLabel(.next)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.words)
                .onSubmit {
                    // Move focus to details on return.
                    focusedField = "details"
                }

            TextEditor(text: $details)
                .focused($focusedField, equals: "details")
                .frame(minHeight: 70)
        }
    }
}
