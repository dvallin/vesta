import SwiftData
import SwiftUI

/// Represents a gap in the meal plan
struct MealGap: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let mealType: MealType

    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

/// Represents a proposed meal to fill a gap
struct MealProposal: Identifiable {
    let id = UUID()
    let gap: MealGap
    let suggestedRecipe: Recipe
    var isAccepted: Bool = false
    var isDeclined: Bool = false
}

class MealPlanHelperViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private var auth: UserAuthService?
    private var categoryService: TodoItemCategoryService?

    @Published var proposals: [MealProposal] = []
    @Published var plannedMeals: [Meal] = []
    @Published var isLoading = false
    @Published var showingErrorAlert = false
    @Published var errorMessage = ""

    let targetWeekStart: Date
    let filterMode: MealPlanFilterMode

    init(filterMode: MealPlanFilterMode) {
        self.filterMode = filterMode

        let calendar = Calendar.current
        let now = Date()

        switch filterMode {
        case .currentWeek:
            self.targetWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .nextWeek:
            let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: now) ?? now
            self.targetWeekStart =
                calendar.dateInterval(of: .weekOfYear, for: nextWeek)?.start ?? now
        default:
            self.targetWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        }
    }

    func configureEnvironment(_ context: ModelContext, _ auth: UserAuthService) {
        self.modelContext = context
        self.categoryService = TodoItemCategoryService(modelContext: context)
        self.auth = auth
    }

    /// Number of weeks to look back for frequency analysis
    private let lookbackWeeks = 4

    /// Cutoff hour for lunch proposals (don't suggest lunch after this hour)
    private let lunchCutoffHour = 13

    /// Analyzes meals and generates proposals for gaps
    /// - Parameters:
    ///   - allMeals: All meals in the system
    ///   - allRecipes: All recipes in the catalog (for fallback suggestions)
    func analyzeAndPropose(allMeals: [Meal], allRecipes: [Recipe] = []) {
        let calendar = Calendar.current

        // Get target week dates
        let targetWeekDates = (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: targetWeekStart)
        }

        // Filter meals for target week
        let targetWeekMeals = allMeals.filter { meal in
            guard let dueDate = meal.todoItem?.dueDate else { return false }
            let startOfDay = calendar.startOfDay(for: dueDate)
            return targetWeekDates.contains { calendar.isDate($0, inSameDayAs: startOfDay) }
        }

        // Get meals from the last N weeks for frequency analysis
        let historicalMeals = getHistoricalMeals(from: allMeals, weeks: lookbackWeeks)

        // Store planned meals for display
        plannedMeals = targetWeekMeals.sorted {
            ($0.todoItem?.dueDate ?? .distantFuture) < ($1.todoItem?.dueDate ?? .distantFuture)
        }

        // Collect recipes already planned this week (to avoid repetition)
        let alreadyPlannedRecipeIds = Set(
            targetWeekMeals.compactMap { $0.recipe?.uid }
        )

        // Find gaps (only lunch and dinner, skip breakfast)
        let mealTypesToPlan: [MealType] = [.lunch, .dinner]
        var newProposals: [MealProposal] = []
        var proposedRecipeIds = Set<String>()

        for date in targetWeekDates {
            for mealType in mealTypesToPlan {
                // Check if there's already a meal planned for this day/type
                let hasPlannedMeal = targetWeekMeals.contains { meal in
                    guard let dueDate = meal.todoItem?.dueDate else { return false }
                    return calendar.isDate(dueDate, inSameDayAs: date) && meal.mealType == mealType
                }

                if !hasPlannedMeal {
                    // Skip gaps that are in the past
                    if isGapInPast(date: date, mealType: mealType) {
                        continue
                    }

                    let gap = MealGap(date: date, mealType: mealType)
                    let targetWeekday = calendar.component(.weekday, from: date)
                    let excluded = alreadyPlannedRecipeIds.union(proposedRecipeIds)

                    // Try finding a recipe with fallback tiers
                    let recipe =
                        // Tier 0: Exact match (weekday + meal type) from history
                        findBestRecipe(
                            for: targetWeekday,
                            mealType: mealType,
                            from: historicalMeals,
                            excluding: excluded
                        )
                        // Tier 1: Any weekday, same meal type from history
                        ?? findBestRecipeForMealType(
                            mealType,
                            from: historicalMeals,
                            excluding: excluded
                        )
                        // Tier 2: Popular recipes from catalog (status == .normal)
                        ?? findPopularRecipeFromCatalog(
                            allRecipes: allRecipes,
                            excluding: excluded,
                            requireNormalStatus: true
                        )
                        // Tier 3: Any available recipe from catalog
                        ?? findPopularRecipeFromCatalog(
                            allRecipes: allRecipes,
                            excluding: excluded,
                            requireNormalStatus: false
                        )

                    if let recipe {
                        let proposal = MealProposal(gap: gap, suggestedRecipe: recipe)
                        newProposals.append(proposal)
                        proposedRecipeIds.insert(recipe.uid)
                    }
                }
            }
        }

        proposals = newProposals
    }

    /// Gets meals from the previous N weeks
    private func getHistoricalMeals(from allMeals: [Meal], weeks: Int) -> [Meal] {
        let calendar = Calendar.current

        return allMeals.filter { meal in
            guard let dueDate = meal.todoItem?.dueDate else { return false }
            guard let mealWeekStart = calendar.dateInterval(of: .weekOfYear, for: dueDate)?.start
            else { return false }

            // Check if this meal is from one of the previous N weeks
            for weekOffset in 1...weeks {
                if let pastWeekStart = calendar.date(
                    byAdding: .weekOfYear, value: -weekOffset, to: targetWeekStart)
                {
                    if calendar.isDate(mealWeekStart, inSameDayAs: pastWeekStart) {
                        return true
                    }
                }
            }
            return false
        }
    }

    /// Finds the best recipe for a given weekday and meal type based on frequency
    /// Excludes recipes that are already planned or proposed this week
    private func findBestRecipe(
        for weekday: Int,
        mealType: MealType,
        from historicalMeals: [Meal],
        excluding excludedRecipeIds: Set<String>
    ) -> Recipe? {
        let calendar = Calendar.current

        // Count frequency of each recipe for this weekday + meal type
        var recipeFrequency: [String: (recipe: Recipe, count: Int)] = [:]

        for meal in historicalMeals {
            guard let dueDate = meal.todoItem?.dueDate,
                let recipe = meal.recipe
            else { continue }

            let mealWeekday = calendar.component(.weekday, from: dueDate)

            // Match weekday and meal type
            if mealWeekday == weekday && meal.mealType == mealType {
                // Skip if this recipe is excluded (already planned/proposed)
                if excludedRecipeIds.contains(recipe.uid) {
                    continue
                }

                if let existing = recipeFrequency[recipe.uid] {
                    recipeFrequency[recipe.uid] = (recipe: recipe, count: existing.count + 1)
                } else {
                    recipeFrequency[recipe.uid] = (recipe: recipe, count: 1)
                }
            }
        }

        // Return the most frequent recipe
        return recipeFrequency.values
            .sorted { $0.count > $1.count }
            .first?
            .recipe
    }

    /// Checks if a gap is in the past and should not be proposed
    /// - Parameters:
    ///   - date: The date of the gap
    ///   - mealType: The meal type
    /// - Returns: true if the gap is in the past
    private func isGapInPast(date: Date, mealType: MealType) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        let startOfToday = calendar.startOfDay(for: now)
        let startOfGapDay = calendar.startOfDay(for: date)

        // If the gap day is before today, it's in the past
        if startOfGapDay < startOfToday {
            return true
        }

        // If it's today, check the meal time
        if calendar.isDateInToday(date) {
            let currentHour = calendar.component(.hour, from: now)

            switch mealType {
            case .breakfast:
                // Skip breakfast if it's past breakfast time (e.g., 10am)
                return currentHour >= 10
            case .lunch:
                // Skip lunch if it's past the cutoff hour
                return currentHour >= lunchCutoffHour
            case .dinner:
                // Skip dinner if it's past dinner time (e.g., 8pm)
                return currentHour >= 20
            }
        }

        return false
    }

    /// Finds the best recipe for a meal type from any weekday (Tier 1 fallback)
    /// Used when no exact weekday match is found
    private func findBestRecipeForMealType(
        _ mealType: MealType,
        from historicalMeals: [Meal],
        excluding excludedRecipeIds: Set<String>
    ) -> Recipe? {
        // Count frequency of each recipe for this meal type (any weekday)
        var recipeFrequency: [String: (recipe: Recipe, count: Int)] = [:]

        for meal in historicalMeals {
            guard let recipe = meal.recipe else { continue }

            // Match meal type only (ignore weekday)
            if meal.mealType == mealType {
                // Skip if this recipe is excluded
                if excludedRecipeIds.contains(recipe.uid) {
                    continue
                }

                if let existing = recipeFrequency[recipe.uid] {
                    recipeFrequency[recipe.uid] = (recipe: recipe, count: existing.count + 1)
                } else {
                    recipeFrequency[recipe.uid] = (recipe: recipe, count: 1)
                }
            }
        }

        // Return the most frequent recipe
        return recipeFrequency.values
            .sorted { $0.count > $1.count }
            .first?
            .recipe
    }

    /// Finds a popular recipe from the catalog (Tier 2 & 3 fallback)
    /// - Parameters:
    ///   - allRecipes: All recipes in the catalog
    ///   - excludedRecipeIds: Recipe IDs to exclude (already planned/proposed)
    ///   - requireNormalStatus: If true, only suggest recipes with .normal status
    private func findPopularRecipeFromCatalog(
        allRecipes: [Recipe],
        excluding excludedRecipeIds: Set<String>,
        requireNormalStatus: Bool
    ) -> Recipe? {
        let availableRecipes = allRecipes.filter { recipe in
            // Exclude already planned/proposed recipes
            guard !excludedRecipeIds.contains(recipe.uid) else { return false }

            // Exclude deleted recipes
            guard recipe.deletedAt == nil else { return false }

            // If requiring normal status, filter out planned and recent
            if requireNormalStatus {
                return recipe.status == .normal
            } else {
                // At minimum, exclude already planned recipes
                return recipe.status != .planned
            }
        }

        // Sort by timesCookedRecently (most popular first)
        // For never-cooked recipes, they'll have count 0 and appear at the end
        return
            availableRecipes
            .sorted { $0.timesCookedRecently > $1.timesCookedRecently }
            .first
    }

    /// Accept a proposal and create the meal
    @MainActor
    func acceptProposal(_ proposal: MealProposal) async {
        guard let index = proposals.firstIndex(where: { $0.id == proposal.id }) else { return }

        guard let currentUser = auth?.currentUser else {
            showError(NSLocalizedString("User not authenticated", comment: "Authentication error"))
            return
        }

        guard let context = modelContext else {
            showError(
                NSLocalizedString(
                    "Environment not configured", comment: "Environment configuration error"))
            return
        }

        do {
            let mealCategory = categoryService?.fetchOrCreate(
                named: NSLocalizedString("Meals", comment: "Category name for meal todo items")
            )

            // Calculate the due date with proper time for meal type
            let (hour, minute) = DateUtils.mealTime(for: proposal.gap.mealType)
            let dueDate = DateUtils.setTime(hour: hour, minute: minute, for: proposal.gap.date)

            let todoItem = TodoItem.create(
                title: proposal.suggestedRecipe.title,
                details: proposal.suggestedRecipe.details,
                dueDate: dueDate,
                ignoreTimeComponent: false,
                category: mealCategory,
                owner: currentUser
            )

            let meal = Meal(
                scalingFactor: 1.0,
                todoItem: todoItem,
                recipe: proposal.suggestedRecipe,
                mealType: proposal.gap.mealType,
                owner: currentUser
            )

            context.insert(todoItem)
            context.insert(meal)
            try context.save()

            // Mark as accepted and add to planned meals
            proposals[index].isAccepted = true
            plannedMeals.append(meal)
            plannedMeals.sort {
                ($0.todoItem?.dueDate ?? .distantFuture) < ($1.todoItem?.dueDate ?? .distantFuture)
            }

            HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)
        } catch {
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .error)
            showError(
                String(
                    format: NSLocalizedString(
                        "Error creating meal: %@", comment: "Error creating meal message"),
                    error.localizedDescription))
        }
    }

    /// Decline a proposal
    func declineProposal(_ proposal: MealProposal) {
        guard let index = proposals.firstIndex(where: { $0.id == proposal.id }) else { return }
        proposals[index].isDeclined = true
        HapticFeedbackManager.shared.generateImpactFeedback(style: .light)
    }

    /// Get pending proposals (not accepted or declined)
    var pendingProposals: [MealProposal] {
        proposals.filter { !$0.isAccepted && !$0.isDeclined }
    }

    /// Get accepted proposals
    var acceptedProposals: [MealProposal] {
        proposals.filter { $0.isAccepted }
    }

    /// Check if all proposals have been handled
    var allProposalsHandled: Bool {
        proposals.allSatisfy { $0.isAccepted || $0.isDeclined }
    }

    /// Accept all pending proposals
    @MainActor
    func acceptAllPending() async {
        for proposal in pendingProposals {
            await acceptProposal(proposal)
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showingErrorAlert = true
    }
}
