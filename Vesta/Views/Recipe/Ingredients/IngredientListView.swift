import SwiftUI

struct IngredientListView<IngredientType: Identifiable>: View {
    var ingredients: [IngredientType]
    let onRemove: (IngredientType) -> Void
    let onMove: (IndexSet, Int) -> Void
    let quantityText: (IngredientType) -> String
    let nameText: (IngredientType) -> String

    var body: some View {
        ForEach(ingredients) { ingredient in
            HStack {
                Text("•")
                Text(nameText(ingredient))
                Spacer()
                Text(quantityText(ingredient))
                    .foregroundColor(.secondary)
            }
        }
        .onDelete { indexSet in
            indexSet.forEach { index in
                let ingredient = ingredients[index]
                onRemove(ingredient)
            }
        }
        .onMove(perform: onMove)
    }
}
