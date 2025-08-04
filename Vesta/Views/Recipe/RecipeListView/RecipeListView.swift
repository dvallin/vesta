import SwiftData
import SwiftUI

struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query<Recipe>(
        filter: #Predicate { recipe in recipe.deletedAt == nil },
    ) private var recipes: [Recipe]

    @State private var searchText: String = ""
    @State private var isPresentingAddRecipeView = false

    var body: some View {
        NavigationView {
            ZStack {
                RecipeList(
                    recipes: recipes,
                    searchText: searchText,
                    deleteRecipes: deleteRecipes
                )

                FloatingAddButton {
                    isPresentingAddRecipeView = true
                }
            }
            .navigationTitle(NSLocalizedString("Recipes", comment: "Navigation title"))
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    TextField(
                        NSLocalizedString("Search", comment: "Search field placeholder"),
                        text: $searchText
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 200)
                }
            }
        }
        .sheet(isPresented: $isPresentingAddRecipeView) {
            AddRecipeView()
        }
    }

    private func deleteRecipes(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                recipes[index].deletedAt = Date()
            }
            if saveContext() {
                HapticFeedbackManager.shared.generateImpactFeedback(style: .heavy)
            }
        }
    }

    private func saveContext() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            return false
        }
    }
}

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)

        let context = container.mainContext
        let user = Fixtures.createUser()
        let recipes = [
            Fixtures.bolognese(owner: user),
            Fixtures.curry(owner: user),
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
