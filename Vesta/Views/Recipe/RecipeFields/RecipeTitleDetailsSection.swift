import SwiftUI

struct RecipeTitleDetailsSection: View {
    @Binding var title: String
    @Binding var details: String
    @FocusState.Binding var focusedField: String?
    @State private var isEditing = false

    var body: some View {
        Section(
            header: Text(
                NSLocalizedString("Recipe Details", comment: "Section header for recipe details"))
        ) {
            TextField(
                NSLocalizedString("Enter recipe title", comment: "Title field placeholder"),
                text: $title
            )
            .focused($focusedField, equals: "title")
            .font(.title)
            .bold()
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.words)
            .submitLabel(.next)
            .onSubmit {
                // Move focus to details on return.
                focusedField = "details"
            }

            if isEditing {
                TextEditor(text: $details)
                    .focused($focusedField, equals: "details")
                    .frame(minHeight: 100)
            } else {
                Text(LocalizedStringKey(details))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isEditing = true
                        focusedField = "details"
                    }
            }
        }
        .onAppear {
            isEditing = details.isEmpty
        }
    }
}
