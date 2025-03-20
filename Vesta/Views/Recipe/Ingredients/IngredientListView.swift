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
                Text(quantityText(ingredient))
                    .frame(width: 100, alignment: .leading)
                Text(nameText(ingredient))
                    .frame(maxWidth: .infinity, alignment: .leading)
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
