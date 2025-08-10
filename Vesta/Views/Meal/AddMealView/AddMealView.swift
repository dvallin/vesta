import SwiftData
import SwiftUI

struct AddMealView: View {
    @EnvironmentObject private var auth: UserAuthService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query<Recipe>(
        filter: #Predicate { recipe in recipe.deletedAt == nil },
    ) private var recipes: [Recipe]
    @Query<Meal>(
        filter: #Predicate { recipe in recipe.deletedAt == nil },
    ) private var meals: [Meal]

    @StateObject private var recipeViewModel = RecipeListViewModel()
    @StateObject private var mealViewModel = AddMealViewModel()
    @State private var isSearchActive = false
    @FocusState private var isSearchFocused: Bool

    private var filteredRecipes: [Recipe] {
        recipeViewModel.filteredAndSortedRecipes(from: recipes)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                RecipeQuickFilterView(viewModel: recipeViewModel, recipes: recipes)
                    .padding(.top, 8)

                if filteredRecipes.isEmpty {
                    VStack(spacing: 16) {
                        Image(
                            systemName: recipeViewModel.searchText.isEmpty
                                ? "book.closed" : "magnifyingglass"
                        )
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                        Text(
                            recipeViewModel.searchText.isEmpty
                                ? "No recipes yet" : "No recipes found"
                        )
                        .font(.title2)
                        .fontWeight(.medium)

                        Text(
                            recipeViewModel.searchText.isEmpty
                                ? "Add some recipes first to create meals"
                                : "Try adjusting your search terms or filters"
                        )
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredRecipes) { recipe in
                            recipeButton(for: recipe)
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        if isSearchActive {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 16))

                                TextField("Search recipes...", text: $recipeViewModel.searchText)
                                    .focused($isSearchFocused)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.headline)

                                Button("Cancel") {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isSearchActive = false
                                        recipeViewModel.searchText = ""
                                        isSearchFocused = false
                                    }
                                }
                                .font(.system(size: 16))
                                .foregroundColor(.accentColor)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .transition(.scale.combined(with: .opacity))
                        } else {
                            HStack {
                                Text(
                                    NSLocalizedString("Add Meal", comment: "Add meal screen title")
                                )
                                .font(.headline)
                                .fontWeight(.semibold)

                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isSearchActive = true
                                        isSearchFocused = true
                                    }
                                } label: {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .alert(
                NSLocalizedString("Error", comment: "Error alert title"),
                isPresented: $mealViewModel.showingErrorAlert
            ) {
                Button(
                    NSLocalizedString("OK", comment: "Error alert OK button"),
                    role: .cancel
                ) {}
            } message: {
                Text(mealViewModel.errorMessage)
            }
        }
        .onAppear {
            recipeViewModel.configureContext(modelContext, auth)
            mealViewModel.configureEnvironment(modelContext, dismiss, auth)

            // Set default filter to show recipes that aren't already planned
            recipeViewModel.filterMode = .notPlanned
        }
    }

    @ViewBuilder
    private func recipeButton(for recipe: Recipe) -> some View {
        Button(action: { selectRecipe(recipe) }) {
            RecipeRow(
                recipe: recipe
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func selectRecipe(_ recipe: Recipe) {
        Task {
            await mealViewModel.createMeal(with: recipe)
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
            Recipe(title: "Apple Pie", details: "Classic dessert", owner: user),
        ]

        for recipe in recipes {
            context.insert(recipe)
        }

        let authService = UserAuthService(modelContext: context)
        return AddMealView()
            .modelContainer(container)
            .environmentObject(authService)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
