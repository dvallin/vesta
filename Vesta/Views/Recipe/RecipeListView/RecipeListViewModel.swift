import SwiftData
import SwiftUI

enum RecipeFilterMode: String, CaseIterable, Identifiable {
    case all
    case inSeason
    case planned
    case recent
    case notPlanned
    case quickCook  // under 30 minutes
    case longCook  // over 2 hours

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:
            return NSLocalizedString("All Recipes", comment: "Filter mode: all recipes")
        case .inSeason:
            return NSLocalizedString("In Season", comment: "Filter mode: in season recipes")
        case .planned:
            return NSLocalizedString("Planned", comment: "Filter mode: planned recipes")
        case .recent:
            return NSLocalizedString("Recent", comment: "Filter mode: recently cooked recipes")
        case .notPlanned:
            return NSLocalizedString("Not Planned", comment: "Filter mode: not planned recipes")
        case .quickCook:
            return NSLocalizedString("Quick Cook", comment: "Filter mode: quick cooking recipes")
        case .longCook:
            return NSLocalizedString("Long Cook", comment: "Filter mode: long cooking recipes")
        }
    }
}

class RecipeListViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private var auth: UserAuthService?

    @Published var searchText: String = ""
    @Published var sortOption: RecipeSortOption = .title
    @Published var filterMode: RecipeFilterMode = .all
    @Published var selectedSeasonality: Seasonality? = nil
    @Published var selectedMealType: MealType? = nil
    @Published var selectedTag: String? = nil
    @Published var showUntagged: Bool = false
    @Published var isPresentingAddRecipeView = false

    func configureContext(_ context: ModelContext, _ auth: UserAuthService) {
        self.modelContext = context
        self.auth = auth
    }

    func filteredAndSortedRecipes(from recipes: [Recipe]) -> [Recipe] {
        let filtered = applyFilters(to: recipes)
        return applySorting(to: filtered)
    }

    private func applyFilters(to recipes: [Recipe]) -> [Recipe] {
        return recipes.filter { recipe in
            // Search filter
            let matchesSearch =
                searchText.isEmpty || recipe.title.localizedCaseInsensitiveContains(searchText)
                || recipe.details.localizedCaseInsensitiveContains(searchText)
                || recipe.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }

            // Filter mode
            let matchesFilterMode = matchesFilter(recipe: recipe)

            // Seasonality filter
            let matchesSeasonality =
                selectedSeasonality == nil || recipe.seasonality == selectedSeasonality

            // Meal type filter
            let matchesMealType =
                selectedMealType == nil || recipe.mealTypes.contains(selectedMealType!)

            // Tag filter
            let matchesTag: Bool
            if showUntagged {
                matchesTag = recipe.tags.isEmpty
            } else if let selectedTag = selectedTag {
                matchesTag = recipe.tags.contains(selectedTag)
            } else {
                matchesTag = true
            }

            return matchesSearch && matchesFilterMode && matchesSeasonality && matchesMealType
                && matchesTag
        }
    }

    private func matchesFilter(recipe: Recipe) -> Bool {
        switch filterMode {
        case .all:
            return true
        case .inSeason:
            return isInSeason(recipe: recipe)
        case .planned:
            return recipe.status == .planned
        case .recent:
            return recipe.status == .recent
        case .notPlanned:
            return recipe.status != .planned
        case .quickCook:
            return recipe.totalDuration > 0 && recipe.totalDuration <= 30 * 60  // 30 minutes
        case .longCook:
            return recipe.totalDuration >= 2 * 60 * 60  // 2 hours
        }
    }

    private func isInSeason(recipe: Recipe) -> Bool {
        guard let seasonality = recipe.seasonality else { return true }

        if seasonality == .yearRound {
            return true
        }

        let currentDate = Date()
        let currentYear = Calendar.current.component(.year, from: currentDate)
        let seasonInterval = seasonality.dateInterval(for: currentYear)

        return seasonInterval.contains(currentDate)
    }

    private func applySorting(to recipes: [Recipe]) -> [Recipe] {
        switch sortOption {
        case .title:
            return recipes.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        case .recentlyAdded:
            return recipes.sorted {
                ($0.deletedAt ?? Date.distantPast) > ($1.deletedAt ?? Date.distantPast)
            }
        case .timesCookedRecently:
            return recipes.sorted {
                if $0.timesCookedRecently == $1.timesCookedRecently {
                    return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                }
                return $0.timesCookedRecently > $1.timesCookedRecently
            }
        case .seasonality:
            return recipes.sorted { recipe1, recipe2 in
                let season1 = recipe1.seasonality?.rawValue ?? "zzz"
                let season2 = recipe2.seasonality?.rawValue ?? "zzz"
                if season1 == season2 {
                    return recipe1.title.localizedCaseInsensitiveCompare(recipe2.title)
                        == .orderedAscending
                }
                return season1 < season2
            }
        case .cookingTime:
            return recipes.sorted { recipe1, recipe2 in
                if recipe1.totalDuration == recipe2.totalDuration {
                    return recipe1.title.localizedCaseInsensitiveCompare(recipe2.title)
                        == .orderedAscending
                }
                return recipe1.totalDuration < recipe2.totalDuration
            }
        }
    }

    func fetchAllTags(from recipes: [Recipe]) -> [String] {
        let allTags = recipes.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }

    func deleteRecipes(offsets: IndexSet, from recipes: [Recipe]) -> Bool {
        guard let currentUser = auth?.currentUser else { return false }

        for index in offsets {
            recipes[index].softDelete(currentUser: currentUser)
        }

        return saveContext()
    }

    private func saveContext() -> Bool {
        do {
            try modelContext?.save()
            return true
        } catch {
            return false
        }
    }

    func resetFilters() {
        filterMode = .all
        selectedSeasonality = nil
        selectedMealType = nil
        selectedTag = nil
        showUntagged = false
    }
}
