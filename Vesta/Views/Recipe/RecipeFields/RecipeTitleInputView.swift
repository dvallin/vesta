import SwiftUI

struct RecipeTitleInputView: View {
    @Binding var title: String

    var body: some View {
        Section(header: Text(NSLocalizedString("Title", comment: "Section header"))) {
            TextField(
                NSLocalizedString("Enter recipe title", comment: "Title field placeholder"),
                text: $title
            )
            .font(.largeTitle)
            .bold()
            .disableAutocorrection(true)
        }
    }
}

#Preview("Empty") {
    Form {
        RecipeTitleInputView(title: .constant(""))
    }
}

#Preview("With Title") {
    Form {
        RecipeTitleInputView(title: .constant("Spaghetti Carbonara"))
    }
}
