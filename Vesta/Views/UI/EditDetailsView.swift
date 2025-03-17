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

#Preview {
    // Create a sample binding for details
    @Previewable @State var details =
        "Sample recipe details: \n\n1. Preheat oven to 350°F\n2. Mix ingredients\n3. Bake for 30 minutes"

    return NavigationStack {
        EditDetailsView(
            navigationBarTitle: "Edit Recipe Details",
            details: $details
        )
    }
}

#Preview("Empty Details") {
    @Previewable @State var emptyDetails = ""

    return NavigationStack {
        EditDetailsView(
            navigationBarTitle: "Add Description",
            details: $emptyDetails
        )
    }
}

#Preview("Long Details") {
    @Previewable @State var longDetails = """
        Detailed Instructions:

        1. Gather all ingredients
        2. Prepare the workspace
        3. Follow each step carefully
        4. Mix dry ingredients first
        5. Combine wet ingredients separately
        6. Fold everything together
        7. Transfer to baking dish
        8. Bake until golden brown
        9. Let cool for 10 minutes
        10. Serve and enjoy!

        Notes:
        - Keep an eye on temperature
        - Don't overmix
        - Best served warm
        """

    return NavigationStack {
        EditDetailsView(
            navigationBarTitle: "Edit Instructions",
            details: $longDetails
        )
    }
}
