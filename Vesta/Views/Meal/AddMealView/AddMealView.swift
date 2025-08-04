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

    @StateObject private var viewModel = AddMealViewModel()
    @State private var searchText = ""
    @State private var showOnlyAvailable = false
    @State private var selectedMealTypeFilter: MealType? = nil

    private var filteredRecipes: [Recipe] {
        var filtered = recipes

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }

        // Apply availability filter
        if showOnlyAvailable {
            filtered = filtered.filter { recipe in
                viewModel.getRecipeStatus(recipe) != .planned
            }
        }

        return filtered
    }

    var body: some View {
        NavigationView {
            List {
                if !searchText.isEmpty {
                    // Show filtered results when searching
                    ForEach(filteredRecipes) { recipe in
                        recipeButton(for: recipe)
                    }
                } else {
                    // Show organized sections when not searching
                    if showOnlyAvailable {
                        // When filtering for available, show simplified sections
                        Section("Available Recipes") {
                            ForEach(filteredRecipes) { recipe in
                                recipeButton(for: recipe)
                            }
                        }
                    } else {
                        // Full organized view
                        if viewModel.recipeSections.hasRecentRecipes {
                            Section("Recently Made") {
                                ForEach(viewModel.recipeSections.recent) { recipe in
                                    recipeButton(for: recipe)
                                }
                            }
                        }

                        if viewModel.recipeSections.hasFrequentRecipes {
                            Section("Frequently Made") {
                                ForEach(viewModel.recipeSections.frequent) { recipe in
                                    recipeButton(for: recipe)
                                }
                            }
                        }

                        if viewModel.recipeSections.hasNotPlannedRecipes {
                            Section("Not Planned") {
                                ForEach(viewModel.recipeSections.notPlanned) { recipe in
                                    recipeButton(for: recipe)
                                }
                            }
                        }

                        Section("All Recipes") {
                            ForEach(recipes) { recipe in
                                recipeButton(for: recipe)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search recipes...")
            .navigationTitle(NSLocalizedString("Add Meal", comment: "Add meal screen title"))
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu("Filter") {
                        Button(showOnlyAvailable ? "Show All" : "Show Only Available") {
                            showOnlyAvailable.toggle()
                        }

                        Divider()

                        Menu("Meal Type") {
                            Button("All Types") {
                                selectedMealTypeFilter = nil
                            }

                            ForEach(MealType.allCases, id: \.self) { mealType in
                                Button(mealType.displayName) {
                                    selectedMealTypeFilter =
                                        selectedMealTypeFilter == mealType ? nil : mealType
                                }
                            }
                        }
                    }
                }
            }
            .alert(
                NSLocalizedString("Error", comment: "Error alert title"),
                isPresented: $viewModel.showingErrorAlert
            ) {
                Button(
                    NSLocalizedString("OK", comment: "Error alert OK button"),
                    role: .cancel
                ) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .onAppear {
            viewModel.configureEnvironment(modelContext, dismiss, auth)
            viewModel.organizeRecipes(recipes, meals)
        }
        .onChange(of: recipes) { _, newRecipes in
            viewModel.organizeRecipes(newRecipes, meals)
        }
    }

    @ViewBuilder
    private func recipeButton(for recipe: Recipe) -> some View {
        Button(action: { selectRecipe(recipe) }) {
            AddMealRecipeRow(
                recipe: recipe,
                status: viewModel.getRecipeStatus(recipe)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func selectRecipe(_ recipe: Recipe) {
        Task {
            await viewModel.createMeal(with: recipe)
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
