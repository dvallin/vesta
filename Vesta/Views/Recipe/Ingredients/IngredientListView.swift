import SwiftUI

struct IngredientListView<IngredientType: Identifiable>: View {
    let ingredients: [IngredientType]
    let onRemove: (IngredientType) -> Void
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
    }
}
