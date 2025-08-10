import SwiftUI

struct RecipeList: View {
    let recipes: [Recipe]
    let onDeleteRecipes: (IndexSet) -> Void

    var body: some View {
        List {
            ForEach(recipes) { recipe in
                NavigationLink {
                    RecipeDetailView(recipe: recipe)
                } label: {
                    RecipeRow(recipe: recipe)
                }
            }
            .onDelete(perform: onDeleteRecipes)
        }
    }
}
