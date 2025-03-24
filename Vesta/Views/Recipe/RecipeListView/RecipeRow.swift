import SwiftUI

struct RecipeRow: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading) {
            Text(recipe.title)
                .font(.headline)
            Text(LocalizedStringKey(recipe.details))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .truncationMode(.tail)
        }
    }
}
