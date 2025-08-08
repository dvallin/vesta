import SwiftData
import SwiftUI

enum RecipeSortOption: String, CaseIterable, Identifiable {
    case title
    case recentlyAdded
    case timesCookedRecently

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .title: return NSLocalizedString("Title", comment: "")
        case .recentlyAdded: return NSLocalizedString("Recently Added", comment: "")
        case .timesCookedRecently: return NSLocalizedString("Times Cooked", comment: "")
        }
    }
}

struct RecipeListView: View {
    @EnvironmentObject private var auth: UserAuthService
    @Environment(\.modelContext) private var modelContext
    @Query<Recipe>(
        filter: #Predicate { recipe in recipe.deletedAt == nil },
    ) private var recipes: [Recipe]

    @State private var searchText: String = ""
    @State private var sortOption: RecipeSortOption = .title

    @State private var isPresentingAddRecipeView = false

    var body: some View {
        NavigationView {
            ZStack {
                if filteredAndSortedRecipes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: searchText.isEmpty ? "book.closed" : "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text(searchText.isEmpty ? "No recipes yet" : "No recipes found")
                            .font(.title2)
                            .fontWeight(.medium)

                        Text(
                            searchText.isEmpty
                                ? "Start building your recipe collection"
                                : "Try adjusting your search terms"
                        )
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                        if searchText.isEmpty {
                            Button("Add Your First Recipe") {
                                isPresentingAddRecipeView = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                } else {
                    RecipeList(
                        recipes: filteredAndSortedRecipes,
                        deleteRecipes: deleteRecipes
                    )
                }

                FloatingAddButton {
                    isPresentingAddRecipeView = true
                }
            }
            .navigationTitle(NSLocalizedString("Recipes", comment: "Navigation title"))
            .searchable(text: $searchText, prompt: "Search recipes...")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(RecipeSortOption.allCases) { option in
                            Button {
                                sortOption = option
                            } label: {
                                HStack {
                                    Label(
                                        option.displayName,
                                        systemImage: option == .title
                                            ? "textformat"
                                            : option == .timesCookedRecently ? "flame" : "clock")
                                    if sortOption == option {
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
                }
            }
        }
        .sheet(isPresented: $isPresentingAddRecipeView) {
            AddRecipeView()
        }
    }

    private var filteredAndSortedRecipes: [Recipe] {
        let filtered = recipes.filter { recipe in
            searchText.isEmpty || recipe.title.localizedCaseInsensitiveContains(searchText)
                || recipe.details.localizedCaseInsensitiveContains(searchText)
        }
        switch sortOption {
        case .title:
            return filtered.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        case .recentlyAdded:
            return filtered.sorted {
                ($0.deletedAt ?? Date.distantPast) > ($1.deletedAt ?? Date.distantPast)
            }
        case .timesCookedRecently:
            return filtered.sorted {
                if $0.timesCookedRecently == $1.timesCookedRecently {
                    return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                }
                return $0.timesCookedRecently > $1.timesCookedRecently
            }
        }
    }

    private func deleteRecipes(offsets: IndexSet) {
        guard let currentUser = auth.currentUser else { return }

        withAnimation {
            for index in offsets {
                recipes[index].softDelete(currentUser: currentUser)
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
