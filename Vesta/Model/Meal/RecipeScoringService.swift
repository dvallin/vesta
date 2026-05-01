import Foundation
import SwiftData

/// A service that scores and selects recipes based on historical meal patterns.
///
/// `RecipeScoringService` encapsulates the logic for analyzing past meals and suggesting
/// recipes for upcoming meal slots. It uses a tiered fallback strategy:
///
/// - **Tier 0**: Exact match — same weekday + same meal type from history
/// - **Tier 1**: Same meal type from any weekday in history
/// - **Tier 2**: Popular recipe from catalog with `.normal` status
/// - **Tier 3**: Any available recipe from catalog (excluding `.planned`)
///
/// ## Scoring Model
///
/// Each historical meal contributes a **weight** to its recipe's score:
///
///     weight = exp(-decayRate × weeksAgo) × cooldownMultiplier
///
/// - **Temporal decay** ensures recent meals have more influence than older ones.
/// - **Cooldown** suppresses recipes cooked very recently to prevent repetitive plans.
/// - **Weighted random sampling** selects from the scored candidates probabilistically,
///   so regenerating proposals can yield different — but still preference-aware — results.
struct RecipeScoringService {

    /// The start date of the week being planned for.
    let targetWeekStart: Date

    /// The number of previous weeks to look back when gathering historical meals.
    let lookbackWeeks: Int

    /// Controls how fast older meals lose influence.
    ///
    /// Higher values mean faster decay. With the default of `0.15`:
    /// - 1 week ago  → weight ≈ 0.86
    /// - 4 weeks ago → weight ≈ 0.55
    /// - 8 weeks ago → weight ≈ 0.30
    /// - 12 weeks ago → weight ≈ 0.17
    let decayRate: Double

    /// Recipes cooked within this many weeks are penalized by `cooldownPenalty`.
    let cooldownWeeks: Int

    /// Multiplier applied to recipes within the cooldown window.
    ///
    /// - `0.0` fully suppresses cooldown recipes (they can never be picked).
    /// - `0.1` makes them 10× less likely than their decayed weight alone.
    /// - `1.0` disables cooldown entirely.
    let cooldownPenalty: Double

    init(
        targetWeekStart: Date,
        lookbackWeeks: Int = 12,
        decayRate: Double = 0.15,
        cooldownWeeks: Int = 1,
        cooldownPenalty: Double = 0.1
    ) {
        self.targetWeekStart = targetWeekStart
        self.lookbackWeeks = lookbackWeeks
        self.decayRate = decayRate
        self.cooldownWeeks = cooldownWeeks
        self.cooldownPenalty = cooldownPenalty
    }

    // MARK: - Historical Meal Retrieval

    /// Gets meals from the previous `lookbackWeeks` weeks relative to `targetWeekStart`.
    ///
    /// Filters the provided meals to only include those whose due date falls within
    /// one of the N weeks immediately preceding the target week.
    ///
    /// - Parameter allMeals: All meals in the system to filter from.
    /// - Returns: Meals whose due dates fall within the lookback window.
    func getHistoricalMeals(from allMeals: [Meal]) -> [Meal] {
        let calendar = Calendar.current

        return allMeals.filter { meal in
            guard let dueDate = meal.todoItem?.dueDate else { return false }
            guard let mealWeekStart = calendar.dateInterval(of: .weekOfYear, for: dueDate)?.start
            else { return false }

            // Check if this meal is from one of the previous N weeks
            for weekOffset in 1...lookbackWeeks {
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

    // MARK: - Weighted Scoring

    /// Finds the best recipe for a given weekday and meal type using decay-weighted scoring
    /// and weighted random sampling.
    ///
    /// Each historical occurrence of a recipe on the matching weekday and meal type contributes
    /// a decay-weighted score. Recipes within the cooldown window are penalized.
    /// The final selection is made via weighted random sampling.
    ///
    /// - Parameters:
    ///   - weekday: The weekday component (1 = Sunday, 7 = Saturday) to match.
    ///   - mealType: The meal type to match.
    ///   - historicalMeals: Previously cooked meals to analyze.
    ///   - excludedRecipeIds: Recipe IDs to exclude (e.g., already planned or proposed).
    /// - Returns: A probabilistically selected recipe weighted by recency, or `nil` if none found.
    func findBestRecipeForWeekday(
        _ weekday: Int,
        mealType: MealType,
        from historicalMeals: [Meal],
        excluding excludedRecipeIds: Set<String>
    ) -> Recipe? {
        let calendar = Calendar.current

        var recipeScores: [String: (recipe: Recipe, weight: Double)] = [:]

        for meal in historicalMeals {
            guard let dueDate = meal.todoItem?.dueDate,
                let recipe = meal.recipe
            else { continue }

            let mealWeekday = calendar.component(.weekday, from: dueDate)

            guard mealWeekday == weekday && meal.mealType == mealType else { continue }
            guard !excludedRecipeIds.contains(recipe.uid) else { continue }

            let mealWeight = weight(for: dueDate)

            if let existing = recipeScores[recipe.uid] {
                recipeScores[recipe.uid] = (recipe: recipe, weight: existing.weight + mealWeight)
            } else {
                recipeScores[recipe.uid] = (recipe: recipe, weight: mealWeight)
            }
        }

        let candidates = recipeScores.values.map { (recipe: $0.recipe, weight: $0.weight) }
        return weightedRandomSelect(from: candidates)
    }

    /// Finds the best recipe for a meal type from any weekday using decay-weighted scoring
    /// and weighted random sampling.
    ///
    /// Similar to `findBestRecipeForWeekday(_:mealType:from:excluding:)` but ignores the weekday,
    /// matching only on meal type. Used as a Tier 1 fallback.
    ///
    /// - Parameters:
    ///   - mealType: The meal type to match.
    ///   - historicalMeals: Previously cooked meals to analyze.
    ///   - excludedRecipeIds: Recipe IDs to exclude (e.g., already planned or proposed).
    /// - Returns: A probabilistically selected recipe weighted by recency, or `nil` if none found.
    func findBestRecipeForMealType(
        _ mealType: MealType,
        from historicalMeals: [Meal],
        excluding excludedRecipeIds: Set<String>
    ) -> Recipe? {
        var recipeScores: [String: (recipe: Recipe, weight: Double)] = [:]

        for meal in historicalMeals {
            guard let dueDate = meal.todoItem?.dueDate,
                let recipe = meal.recipe
            else { continue }

            guard meal.mealType == mealType else { continue }
            guard !excludedRecipeIds.contains(recipe.uid) else { continue }

            let mealWeight = weight(for: dueDate)

            if let existing = recipeScores[recipe.uid] {
                recipeScores[recipe.uid] = (recipe: recipe, weight: existing.weight + mealWeight)
            } else {
                recipeScores[recipe.uid] = (recipe: recipe, weight: mealWeight)
            }
        }

        let candidates = recipeScores.values.map { (recipe: $0.recipe, weight: $0.weight) }
        return weightedRandomSelect(from: candidates)
    }

    // MARK: - Catalog-Based Selection

    /// Finds a recipe from the catalog using weighted random sampling based on popularity.
    ///
    /// Each recipe's weight is derived from `timesCookedRecently + 1`, giving never-cooked
    /// recipes a small but non-zero chance of being selected.
    ///
    /// - Parameters:
    ///   - allRecipes: All recipes in the catalog.
    ///   - excludedRecipeIds: Recipe IDs to exclude (already planned/proposed).
    ///   - requireNormalStatus: If `true`, only suggest recipes with `.normal` status.
    ///     If `false`, allows any status except `.planned`.
    /// - Returns: A probabilistically selected recipe, or `nil` if none available.
    func findPopularRecipeFromCatalog(
        allRecipes: [Recipe],
        excluding excludedRecipeIds: Set<String>,
        requireNormalStatus: Bool
    ) -> Recipe? {
        let candidates: [(recipe: Recipe, weight: Double)] = allRecipes.compactMap { recipe in
            guard !excludedRecipeIds.contains(recipe.uid) else { return nil }
            guard recipe.deletedAt == nil else { return nil }

            if requireNormalStatus {
                guard recipe.status == .normal else { return nil }
            } else {
                guard recipe.status != .planned else { return nil }
            }

            // Base weight from popularity; +1 so never-cooked recipes still have a chance
            let weight = Double(recipe.timesCookedRecently + 1)
            return (recipe: recipe, weight: weight)
        }

        return weightedRandomSelect(from: candidates)
    }

    // MARK: - Tiered Suggestion

    /// Suggests a recipe for a specific weekday and meal type using the full tiered fallback strategy.
    ///
    /// The tiers are tried in order:
    /// - **Tier 0**: Exact weekday + meal type match from historical meals
    /// - **Tier 1**: Same meal type from any weekday in historical meals
    /// - **Tier 2**: Most popular recipe from catalog with `.normal` status
    /// - **Tier 3**: Any available recipe from catalog (excluding `.planned`)
    ///
    /// - Parameters:
    ///   - weekday: The weekday component (1 = Sunday, 7 = Saturday) to target.
    ///   - mealType: The meal type to suggest for.
    ///   - historicalMeals: Previously cooked meals to analyze for frequency patterns.
    ///   - allRecipes: All recipes in the catalog (for fallback suggestions).
    ///   - excludedRecipeIds: Recipe IDs to exclude (already planned or proposed this week).
    /// - Returns: The best available recipe, or `nil` if no suitable recipe can be found.
    func suggestRecipe(
        for weekday: Int,
        mealType: MealType,
        historicalMeals: [Meal],
        allRecipes: [Recipe],
        excluding excludedRecipeIds: Set<String>
    ) -> Recipe? {
        // Tier 0: Exact match (weekday + meal type) from history
        findBestRecipeForWeekday(
            weekday,
            mealType: mealType,
            from: historicalMeals,
            excluding: excludedRecipeIds
        )
            // Tier 1: Any weekday, same meal type from history
            ?? findBestRecipeForMealType(
                mealType,
                from: historicalMeals,
                excluding: excludedRecipeIds
            )
            // Tier 2: Popular recipes from catalog (status == .normal)
            ?? findPopularRecipeFromCatalog(
                allRecipes: allRecipes,
                excluding: excludedRecipeIds,
                requireNormalStatus: true
            )
            // Tier 3: Any available recipe from catalog
            ?? findPopularRecipeFromCatalog(
                allRecipes: allRecipes,
                excluding: excludedRecipeIds,
                requireNormalStatus: false
            )
    }

    /// Suggests a recipe for a meal type without a specific weekday (undated case).
    ///
    /// Uses a reduced fallback strategy (skipping Tier 0 since there is no target weekday):
    /// - **Tier 1**: Most frequent recipe for this meal type from history
    /// - **Tier 2**: Most popular recipe from catalog with `.normal` status
    /// - **Tier 3**: Any available recipe from catalog (excluding `.planned`)
    ///
    /// - Parameters:
    ///   - mealType: The meal type to suggest for.
    ///   - historicalMeals: Previously cooked meals to analyze for frequency patterns.
    ///   - allRecipes: All recipes in the catalog (for fallback suggestions).
    ///   - excludedRecipeIds: Recipe IDs to exclude (already planned or proposed).
    /// - Returns: The best available recipe, or `nil` if no suitable recipe can be found.
    func suggestRecipeForMealType(
        _ mealType: MealType,
        historicalMeals: [Meal],
        allRecipes: [Recipe],
        excluding excludedRecipeIds: Set<String>
    ) -> Recipe? {
        // Tier 1: Any weekday, same meal type from history
        findBestRecipeForMealType(
            mealType,
            from: historicalMeals,
            excluding: excludedRecipeIds
        )
            // Tier 2: Popular recipes from catalog (status == .normal)
            ?? findPopularRecipeFromCatalog(
                allRecipes: allRecipes,
                excluding: excludedRecipeIds,
                requireNormalStatus: true
            )
            // Tier 3: Any available recipe from catalog
            ?? findPopularRecipeFromCatalog(
                allRecipes: allRecipes,
                excluding: excludedRecipeIds,
                requireNormalStatus: false
            )
    }

    // MARK: - Private Helpers

    /// Computes how many weeks ago a date is relative to `targetWeekStart`.
    ///
    /// Returns a continuous value (e.g., 3 days ago → ~0.43 weeks ago) for smooth decay.
    private func weeksAgo(for date: Date) -> Double {
        let days = Calendar.current.dateComponents([.day], from: date, to: targetWeekStart).day ?? 0
        return max(0, Double(days) / 7.0)
    }

    /// Computes the combined weight for a meal at a given date.
    ///
    /// Combines exponential temporal decay with a cooldown penalty:
    ///
    ///     weight = exp(-decayRate × weeksAgo) × cooldownMultiplier
    ///
    /// - Parameter date: The due date of the historical meal.
    /// - Returns: The weight contribution of this meal occurrence.
    private func weight(for date: Date) -> Double {
        let weeks = weeksAgo(for: date)
        let decay = exp(-decayRate * weeks)
        let cooldown: Double = weeks < Double(cooldownWeeks) ? cooldownPenalty : 1.0
        return decay * cooldown
    }

    /// Selects a recipe from weighted candidates using roulette-wheel sampling.
    ///
    /// Each candidate's probability of being chosen is proportional to its weight.
    /// Returns `nil` if the candidates array is empty or all weights are zero.
    ///
    /// - Parameter candidates: An array of (recipe, weight) tuples.
    /// - Returns: A probabilistically selected recipe, or `nil`.
    private func weightedRandomSelect(
        from candidates: [(recipe: Recipe, weight: Double)]
    ) -> Recipe? {
        let totalWeight = candidates.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else { return nil }

        var random = Double.random(in: 0..<totalWeight)
        for candidate in candidates {
            random -= candidate.weight
            if random <= 0 {
                return candidate.recipe
            }
        }

        // Floating-point safety: return the last candidate
        return candidates.last?.recipe
    }
}
