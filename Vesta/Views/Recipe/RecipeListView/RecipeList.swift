import SwiftUI

struct RecipeList: View {
    let recipes: [Recipe]
    let searchText: String
    let deleteRecipes: (IndexSet) -> Void

    var body: some View {
        List {
            ForEach(filteredRecipes) { recipe in
                NavigationLink {
                    RecipeDetailView(recipe: recipe)
                } label: {
                    RecipeRow(recipe: recipe)
                }
            }
            .onDelete(perform: deleteRecipes)
        }
    }

    private var filteredRecipes: [Recipe] {
        recipes.filter { recipe in
            searchText.isEmpty || recipe.title.localizedCaseInsensitiveContains(searchText)
                || recipe.details.localizedCaseInsensitiveContains(searchText)
        }
    }
}
