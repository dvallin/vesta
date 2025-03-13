import SwiftUI

struct RecipeDetailsEditorView: View {
    @Binding var details: String

    var body: some View {
        Section(header: Text(NSLocalizedString("Description", comment: "Section header"))) {
            TextEditor(text: $details)
                .frame(minHeight: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.tertiary, lineWidth: 1)
                )
        }
    }
}

#Preview {
    Form {
        RecipeDetailsEditorView(
            details: .constant(
                """
                1. Preheat oven to 350°F (175°C)
                2. Mix flour, sugar, and baking powder
                3. Add eggs and milk, stir until smooth
                4. Pour into greased pan
                5. Bake for 30-35 minutes

                Notes:
                - Can substitute milk with almond milk
                - Best served warm
                """))
    }
}
