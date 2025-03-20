import SwiftUI

struct IngredientsSection<IngredientType: Identifiable>: View {
    let header: String

    var ingredients: [IngredientType]

    let moveHandler: (IndexSet, Int) -> Void
    let removeHandler: (IngredientType) -> Void
    let quantityText: (IngredientType) -> String
    let nameText: (IngredientType) -> String

    @Binding var ingredientName: String
    @Binding var ingredientQuantity: String
    @Binding var ingredientUnit: Unit?

    let onAdd: () -> Void

    var body: some View {
        Section(header: Text(header)) {
            IngredientListView(
                ingredients: ingredients,
                onRemove: removeHandler,
                onMove: moveHandler,
                quantityText: quantityText,
                nameText: nameText
            )
            IngredientInputRowView(
                ingredientQuantity: $ingredientQuantity,
                ingredientUnit: $ingredientUnit,
                ingredientName: $ingredientName,
                onAdd: onAdd
            )
        }
    }
}
