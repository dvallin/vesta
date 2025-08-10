import SwiftData
import SwiftUI

enum RecipeSortOption: String, CaseIterable, Identifiable {
    case title
    case recentlyAdded
    case timesCookedRecently
    case seasonality
    case cookingTime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .title: return NSLocalizedString("Title", comment: "")
        case .recentlyAdded: return NSLocalizedString("Recently Added", comment: "")
        case .timesCookedRecently: return NSLocalizedString("Times Cooked", comment: "")
        case .seasonality: return NSLocalizedString("Seasonality", comment: "")
        case .cookingTime: return NSLocalizedString("Cooking Time", comment: "")
        }
    }
}

struct RecipeListView: View {
    @EnvironmentObject private var auth: UserAuthService
    @Environment(\.modelContext) private var modelContext
    @Query<Recipe>(
        filter: #Predicate { recipe in recipe.deletedAt == nil },
    ) private var recipes: [Recipe]

    @StateObject private var viewModel = RecipeListViewModel()
    @State private var isSearchActive = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                RecipeQuickFilterView(viewModel: viewModel, recipes: recipes)
                    .padding(.top, 8)

                ZStack {
                    if filteredAndSortedRecipes.isEmpty {
                        VStack(spacing: 16) {
                            Image(
                                systemName: viewModel.searchText.isEmpty
                                    ? "book.closed" : "magnifyingglass"
                            )
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                            Text(
                                viewModel.searchText.isEmpty ? "No recipes yet" : "No recipes found"
                            )
                            .font(.title2)
                            .fontWeight(.medium)

                            Text(
                                viewModel.searchText.isEmpty
                                    ? "Start building your recipe collection"
                                    : "Try adjusting your search terms"
                            )
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                            if viewModel.searchText.isEmpty {
                                Button("Add Your First Recipe") {
                                    viewModel.isPresentingAddRecipeView = true
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding()
                    } else {
                        RecipeList(
                            recipes: filteredAndSortedRecipes,
                            onDeleteRecipes: deleteRecipes
                        )
                    }

                    FloatingAddButton {
                        viewModel.isPresentingAddRecipeView = true
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

                                TextField("Search recipes...", text: $viewModel.searchText)
                                    .focused($isSearchFocused)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.headline)

                                Button("Cancel") {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isSearchActive = false
                                        viewModel.searchText = ""
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
                                Text(NSLocalizedString("Recipes", comment: "Navigation title"))
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

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isSearchActive {
                        Menu {
                            ForEach(RecipeSortOption.allCases) { option in
                                Button {
                                    viewModel.sortOption = option
                                } label: {
                                    HStack {
                                        Label(
                                            option.displayName,
                                            systemImage: sortOptionIcon(for: option))
                                        if viewModel.sortOption == option {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label("Sort", systemImage: "arrow.up.arrow.down.circle")
                        }
                        .labelStyle(IconOnlyLabelStyle())
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.isPresentingAddRecipeView) {
            AddRecipeView()
        }
        .onAppear {
            viewModel.configureContext(modelContext, auth)
        }
    }

    private var filteredAndSortedRecipes: [Recipe] {
        viewModel.filteredAndSortedRecipes(from: recipes)
    }

    private func deleteRecipes(offsets: IndexSet) {
        withAnimation {
            if viewModel.deleteRecipes(offsets: offsets, from: filteredAndSortedRecipes) {
                HapticFeedbackManager.shared.generateImpactFeedback(style: .heavy)
            }
        }
    }

    private func sortOptionIcon(for option: RecipeSortOption) -> String {
        switch option {
        case .title:
            return "textformat"
        case .recentlyAdded:
            return "clock"
        case .timesCookedRecently:
            return "flame"
        case .seasonality:
            return "leaf"
        case .cookingTime:
            return "timer"
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
