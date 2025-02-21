import SwiftUI

struct RecipeTitleInputView: View {
    @Binding var title: String

    var body: some View {
        Section(header: Text("Title")) {
            TextField("Enter recipe title", text: $title)
                .font(.largeTitle)
                .bold()
                .disableAutocorrection(true)
        }
    }
}
