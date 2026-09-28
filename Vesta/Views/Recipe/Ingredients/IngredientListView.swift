import SwiftUI

struct IngredientListView<IngredientType: Identifiable>: View {
    var ingredients: [IngredientType]
    let onRemove: (IngredientType) -> Void
    let onMove: (IndexSet, Int) -> Void
    let quantityText: (IngredientType) -> String
    let nameText: (IngredientType) -> String
    var groupText: ((IngredientType) -> String?)? = nil
    var onEdit: ((IngredientType) -> Void)? = nil

    var body: some View {
        ForEach(ingredients) { ingredient in
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(nameText(ingredient))
                    if let groupFn = groupText, let group = groupFn(ingredient) {
                        Text(group)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Text(quantityText(ingredient))
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onEdit?(ingredient)
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
