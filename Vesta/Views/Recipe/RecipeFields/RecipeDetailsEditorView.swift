import SwiftUI

struct RecipeDetailsEditorView: View {
    @Binding var details: String

    var body: some View {
        Section(header: Text("Description")) {
            TextEditor(text: $details)
                .frame(minHeight: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.tertiary, lineWidth: 1)
                )
        }
    }
}
