import SwiftData
import SwiftUI

struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var recipes: [Recipe]

    @State private var searchText: String = ""
    @State private var isPresentingAddRecipeView = false

    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(filteredRecipes) { recipe in
                        NavigationLink {
                            RecipeDetailView(recipe: recipe)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(recipe.title)
                                    .font(.headline)
                                Text(recipe.details)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                    .truncationMode(.tail)
                            }
                        }
                    }
                    .onDelete(perform: deleteRecipes)
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            isPresentingAddRecipeView = true
                        }) {
                            Image(systemName: "plus")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .shadow(radius: 10)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    TextField("Search", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 200)
                }
            }
        }
        .sheet(isPresented: $isPresentingAddRecipeView) {
            AddRecipeView()
        }
    }

    private var filteredRecipes: [Recipe] {
        recipes.filter { recipe in
            searchText.isEmpty || recipe.title.localizedCaseInsensitiveContains(searchText)
                || recipe.details.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func deleteRecipes(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(recipes[index])
            }
        }
    }
}

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)

        let context = container.mainContext
        let recipes = [
            Recipe(title: "Spaghetti Bolognese", details: "A classic Italian pasta dish."),
            Recipe(title: "Chicken Curry", details: "A spicy and flavorful dish."),
            Recipe(title: "Chocolate Cake", details: "A rich and moist dessert."),
        ]

        for recipe in recipes {
            context.insert(recipe)
        }

        return RecipeListView()
            .modelContainer(container)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
