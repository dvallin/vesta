import SwiftData
import XCTest

@testable import Vesta

final class RecipeScoringServiceTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var user: User!

    /// A fixed reference date used as `targetWeekStart` for all tests.
    /// Using the start of the current week ensures weekday calculations are predictable.
    var targetWeekStart: Date!

    override func setUp() {
        super.setUp()
        container = try! ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        context = ModelContext(container)
        user = Fixtures.createUser()

        let calendar = Calendar.current
        targetWeekStart =
            calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
    }

    override func tearDown() {
        container = nil
        context = nil
        user = nil
        targetWeekStart = nil
        super.tearDown()
    }

    // MARK: - Test Helpers

    /// Creates a date that is a given number of weeks before `targetWeekStart`,
    /// optionally offset to a specific weekday (1 = Sunday, 7 = Saturday).
    private func date(weeksAgo weeks: Int, weekday: Int? = nil) -> Date {
        let calendar = Calendar.current
        var date = calendar.date(
            byAdding: .weekOfYear, value: -weeks, to: targetWeekStart
        )!
        if let weekday {
            // Advance to the requested weekday within that week
            let currentWeekday = calendar.component(.weekday, from: date)
            let delta = weekday - currentWeekday
            date = calendar.date(byAdding: .day, value: delta, to: date)!
        }
        // Set to noon to avoid any midnight boundary issues
        date = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date)!
        return date
    }

    /// Creates a `Recipe` with a given title, inserts it into context, and returns it.
    @discardableResult
    private func makeRecipe(title: String) -> Recipe {
        let recipe = Recipe(title: title, details: "", owner: user)
        context.insert(recipe)
        return recipe
    }

    /// Creates a `Meal` linked to a recipe and a todo item with a specific due date,
    /// inserts everything into context, and returns the meal.
    @discardableResult
    private func makeMeal(
        recipe: Recipe,
        mealType: MealType = .dinner,
        dueDate: Date
    ) -> Meal {
        let todoItem = Fixtures.todoItem(
            title: recipe.title,
            details: "",
            dueDate: dueDate,
            owner: user
        )
        context.insert(todoItem)

        let meal = Meal(
            scalingFactor: 1.0,
            todoItem: todoItem,
            recipe: recipe,
            mealType: mealType,
            owner: user
        )
        context.insert(meal)
        return meal
    }

    /// Creates a default service with the test's `targetWeekStart`.
    private func makeService(
        lookbackWeeks: Int = 12,
        decayRate: Double = 0.15,
        cooldownWeeks: Int = 1,
        cooldownPenalty: Double = 0.1
    ) -> RecipeScoringService {
        RecipeScoringService(
            targetWeekStart: targetWeekStart,
            lookbackWeeks: lookbackWeeks,
            decayRate: decayRate,
            cooldownWeeks: cooldownWeeks,
            cooldownPenalty: cooldownPenalty
        )
    }

    // MARK: - Historical Meal Retrieval

    func testGetHistoricalMealsFiltersToLookbackWindow() {
        let service = makeService(lookbackWeeks: 4)
        let recipe = makeRecipe(title: "Pasta")

        let withinWindow = makeMeal(recipe: recipe, dueDate: date(weeksAgo: 2))
        let atEdge = makeMeal(recipe: recipe, dueDate: date(weeksAgo: 4))
        let outsideWindow = makeMeal(recipe: recipe, dueDate: date(weeksAgo: 5))

        let allMeals = [withinWindow, atEdge, outsideWindow]
        let historical = service.getHistoricalMeals(from: allMeals)

        XCTAssertTrue(
            historical.contains { $0.uid == withinWindow.uid },
            "Meal 2 weeks ago should be included")
        XCTAssertTrue(
            historical.contains { $0.uid == atEdge.uid },
            "Meal at the edge (4 weeks ago) should be included")
        XCTAssertFalse(
            historical.contains { $0.uid == outsideWindow.uid },
            "Meal 5 weeks ago should be excluded with lookback=4")
    }

    func testGetHistoricalMealsExcludesMealsWithoutDueDate() {
        let service = makeService(lookbackWeeks: 4)
        let recipe = makeRecipe(title: "Pasta")

        // Meal with no due date
        let todoItem = Fixtures.todoItem(
            title: "Undated", details: "", dueDate: nil, owner: user)
        context.insert(todoItem)
        let undatedMeal = Meal(
            scalingFactor: 1.0, todoItem: todoItem, recipe: recipe,
            mealType: .dinner, owner: user)
        context.insert(undatedMeal)

        let datedMeal = makeMeal(recipe: recipe, dueDate: date(weeksAgo: 1))

        let historical = service.getHistoricalMeals(from: [undatedMeal, datedMeal])

        XCTAssertEqual(historical.count, 1, "Only the dated meal should be returned")
        XCTAssertEqual(historical.first?.uid, datedMeal.uid)
    }

    func testGetHistoricalMealsExcludesCurrentTargetWeek() {
        let service = makeService(lookbackWeeks: 4)
        let recipe = makeRecipe(title: "Pasta")

        // A meal in the target week itself (0 weeks ago)
        let targetWeekMeal = makeMeal(recipe: recipe, dueDate: date(weeksAgo: 0))
        let pastMeal = makeMeal(recipe: recipe, dueDate: date(weeksAgo: 1))

        let historical = service.getHistoricalMeals(from: [targetWeekMeal, pastMeal])

        XCTAssertFalse(
            historical.contains { $0.uid == targetWeekMeal.uid },
            "Meals in the target week should not be historical")
        XCTAssertTrue(historical.contains { $0.uid == pastMeal.uid })
    }

    // MARK: - Decay Weighting

    func testRecentRecipesSelectedMoreOftenThanOlderOnes() {
        // Two recipes: "Recent" cooked 1 week ago, "Old" cooked 10 weeks ago.
        // Over many iterations, "Recent" should be picked significantly more often.
        let recentRecipe = makeRecipe(title: "Recent Dish")
        let oldRecipe = makeRecipe(title: "Old Dish")

        let recentMeal = makeMeal(recipe: recentRecipe, dueDate: date(weeksAgo: 1, weekday: 2))
        let oldMeal = makeMeal(recipe: oldRecipe, dueDate: date(weeksAgo: 10, weekday: 2))

        let historicalMeals = [recentMeal, oldMeal]
        // Disable cooldown so we purely measure decay
        let service = makeService(cooldownWeeks: 0, cooldownPenalty: 1.0)

        var counts: [String: Int] = [recentRecipe.uid: 0, oldRecipe.uid: 0]
        let iterations = 1000

        for _ in 0..<iterations {
            if let recipe = service.findBestRecipeForWeekday(
                2, mealType: .dinner, from: historicalMeals, excluding: [])
            {
                counts[recipe.uid, default: 0] += 1
            }
        }

        let recentCount = counts[recentRecipe.uid] ?? 0
        let oldCount = counts[oldRecipe.uid] ?? 0

        XCTAssertGreaterThan(
            recentCount, oldCount,
            "Recent recipe (\(recentCount)) should be selected more often than old recipe (\(oldCount))"
        )
        // With decay rate 0.15: weight(1 week) ≈ 0.86, weight(10 weeks) ≈ 0.22
        // Expected ratio ≈ 0.86 / (0.86 + 0.22) ≈ 0.80
        let recentRatio = Double(recentCount) / Double(iterations)
        XCTAssertGreaterThan(
            recentRatio, 0.6,
            "Recent recipe should be picked at least 60% of the time, got \(recentRatio)")
    }

    func testEqualAgeRecipesSelectedRoughlyEvenly() {
        // Two recipes both cooked 3 weeks ago: should be selected ~50/50.
        let recipeA = makeRecipe(title: "Recipe A")
        let recipeB = makeRecipe(title: "Recipe B")

        let mealA = makeMeal(recipe: recipeA, dueDate: date(weeksAgo: 3, weekday: 3))
        let mealB = makeMeal(recipe: recipeB, dueDate: date(weeksAgo: 3, weekday: 3))

        let historicalMeals = [mealA, mealB]
        let service = makeService(cooldownWeeks: 0, cooldownPenalty: 1.0)

        var counts: [String: Int] = [:]
        let iterations = 1000

        for _ in 0..<iterations {
            if let recipe = service.findBestRecipeForWeekday(
                3, mealType: .dinner, from: historicalMeals, excluding: [])
            {
                counts[recipe.uid, default: 0] += 1
            }
        }

        let countA = counts[recipeA.uid] ?? 0
        let countB = counts[recipeB.uid] ?? 0

        // Should be roughly 50/50 — allow 35-65 range for randomness
        let ratioA = Double(countA) / Double(iterations)
        XCTAssertGreaterThan(
            ratioA, 0.35,
            "Recipe A should be picked at least 35% of the time, got \(ratioA)")
        XCTAssertLessThan(
            ratioA, 0.65,
            "Recipe A should be picked at most 65% of the time, got \(ratioA)")
        XCTAssertEqual(
            countA + countB, iterations,
            "All iterations should produce a result")
    }

    // MARK: - Cooldown Mechanism

    func testCooldownSuppressesVeryRecentRecipes() {
        // "Recent" cooked < 1 week ago (inside cooldown), "Safe" cooked 3 weeks ago.
        // With cooldown penalty 0.1, "Recent" should be picked much less often.
        let recentRecipe = makeRecipe(title: "Recent")
        let safeRecipe = makeRecipe(title: "Safe")

        // Create dates: recent is 3 days ago (< 1 week), safe is 3 weeks ago
        let calendar = Calendar.current
        let recentDate = calendar.date(byAdding: .day, value: -3, to: targetWeekStart)!
        // Use the same weekday for fair comparison in Tier 1 (mealType only)
        let safeDate = date(weeksAgo: 3)

        let recentMeal = makeMeal(recipe: recentRecipe, dueDate: recentDate)
        let safeMeal = makeMeal(recipe: safeRecipe, dueDate: safeDate)

        // Service with 1-week cooldown window, penalty = 0.1
        let service = makeService(cooldownWeeks: 1, cooldownPenalty: 0.1)
        let historicalMeals = [recentMeal, safeMeal]

        var counts: [String: Int] = [:]
        let iterations = 1000

        for _ in 0..<iterations {
            if let recipe = service.findBestRecipeForMealType(
                .dinner, from: historicalMeals, excluding: [])
            {
                counts[recipe.uid, default: 0] += 1
            }
        }

        let recentCount = counts[recentRecipe.uid] ?? 0
        let safeCount = counts[safeRecipe.uid] ?? 0

        XCTAssertGreaterThan(
            safeCount, recentCount,
            "Safe recipe (\(safeCount)) should dominate over cooled-down recipe (\(recentCount))")
    }

    func testCooldownWithZeroPenaltyFullySuppresses() {
        // With cooldownPenalty = 0.0, recipes in cooldown should never be picked.
        let recentRecipe = makeRecipe(title: "Suppressed")
        let otherRecipe = makeRecipe(title: "Available")

        let calendar = Calendar.current
        let recentDate = calendar.date(byAdding: .day, value: -3, to: targetWeekStart)!
        let otherDate = date(weeksAgo: 2)

        let recentMeal = makeMeal(recipe: recentRecipe, dueDate: recentDate)
        let otherMeal = makeMeal(recipe: otherRecipe, dueDate: otherDate)

        let service = makeService(cooldownWeeks: 1, cooldownPenalty: 0.0)
        let historicalMeals = [recentMeal, otherMeal]

        for _ in 0..<100 {
            let recipe = service.findBestRecipeForMealType(
                .dinner, from: historicalMeals, excluding: [])
            XCTAssertEqual(
                recipe?.uid, otherRecipe.uid,
                "Suppressed recipe should never be selected with penalty=0.0")
        }
    }

    func testRecipesBeyondCooldownWindowNotPenalized() {
        // A recipe cooked exactly 2 weeks ago with cooldownWeeks=1 should not be penalized.
        let recipe = makeRecipe(title: "Should be fine")
        let meal = makeMeal(recipe: recipe, dueDate: date(weeksAgo: 2))

        let service = makeService(cooldownWeeks: 1, cooldownPenalty: 0.0)

        // If it were penalized, it would have weight 0 and return nil
        let result = service.findBestRecipeForMealType(
            .dinner, from: [meal], excluding: [])
        XCTAssertNotNil(result, "Recipe beyond cooldown window should not be suppressed")
        XCTAssertEqual(result?.uid, recipe.uid)
    }

    // MARK: - Weighted Random Sampling

    func testWeightedRandomProducesVariety() {
        // With multiple candidates of similar weight, we should see variety across runs.
        let recipes = (1...5).map { makeRecipe(title: "Recipe \($0)") }
        let meals = recipes.map { makeMeal(recipe: $0, dueDate: date(weeksAgo: 3)) }

        let service = makeService(cooldownWeeks: 0, cooldownPenalty: 1.0)
        var selectedIds = Set<String>()

        for _ in 0..<200 {
            if let recipe = service.findBestRecipeForMealType(
                .dinner, from: meals, excluding: [])
            {
                selectedIds.insert(recipe.uid)
            }
        }

        XCTAssertGreaterThan(
            selectedIds.count, 1,
            "Weighted random should select more than one distinct recipe over 200 iterations, got \(selectedIds.count)"
        )
        // With 5 equal-weight candidates and 200 runs, we'd expect all 5 to appear
        XCTAssertEqual(
            selectedIds.count, 5,
            "All 5 equal-weight recipes should eventually be selected")
    }

    func testSingleCandidateAlwaysSelected() {
        let recipe = makeRecipe(title: "Only Option")
        let meal = makeMeal(recipe: recipe, dueDate: date(weeksAgo: 2))

        let service = makeService()

        for _ in 0..<10 {
            let result = service.findBestRecipeForMealType(
                .dinner, from: [meal], excluding: [])
            XCTAssertEqual(result?.uid, recipe.uid)
        }
    }

    // MARK: - Empty and Nil Cases

    func testEmptyHistoryReturnsNil() {
        let service = makeService()

        let result = service.findBestRecipeForMealType(
            .dinner, from: [], excluding: [])
        XCTAssertNil(result, "Empty history should return nil")
    }

    func testNoMatchingMealTypeReturnsNil() {
        let recipe = makeRecipe(title: "Lunch Recipe")
        let meal = makeMeal(recipe: recipe, mealType: .lunch, dueDate: date(weeksAgo: 2))

        let service = makeService()

        let result = service.findBestRecipeForMealType(
            .dinner, from: [meal], excluding: [])
        XCTAssertNil(result, "Should return nil when no meals match the requested type")
    }

    func testNoMatchingWeekdayReturnsNil() {
        let recipe = makeRecipe(title: "Wednesday Meal")
        // Create meal on weekday 4 (Wednesday)
        let meal = makeMeal(recipe: recipe, dueDate: date(weeksAgo: 2, weekday: 4))

        let service = makeService()

        // Ask for weekday 2 (Monday) — should get nil
        let result = service.findBestRecipeForWeekday(
            2, mealType: .dinner, from: [meal], excluding: [])
        XCTAssertNil(result, "Should return nil when no meals match the requested weekday")
    }

    // MARK: - Exclusion

    func testExcludedRecipesNeverReturned() {
        let excludedRecipe = makeRecipe(title: "Excluded")
        let availableRecipe = makeRecipe(title: "Available")

        let meal1 = makeMeal(recipe: excludedRecipe, dueDate: date(weeksAgo: 2))
        let meal2 = makeMeal(recipe: availableRecipe, dueDate: date(weeksAgo: 2))

        let service = makeService()
        let excluded: Set<String> = [excludedRecipe.uid]

        for _ in 0..<50 {
            let result = service.findBestRecipeForMealType(
                .dinner, from: [meal1, meal2], excluding: excluded)
            XCTAssertEqual(
                result?.uid, availableRecipe.uid,
                "Excluded recipe should never be returned")
        }
    }

    func testAllRecipesExcludedReturnsNil() {
        let recipe = makeRecipe(title: "Only Recipe")
        let meal = makeMeal(recipe: recipe, dueDate: date(weeksAgo: 2))

        let service = makeService()
        let excluded: Set<String> = [recipe.uid]

        let result = service.findBestRecipeForMealType(
            .dinner, from: [meal], excluding: excluded)
        XCTAssertNil(result, "Should return nil when all candidates are excluded")
    }

    // MARK: - Frequency Accumulation

    func testMoreFrequentRecipeHasHigherSelectionRate() {
        // Recipe A appears 4 times, Recipe B appears 1 time, all at the same age.
        // Recipe A should be selected roughly 4× more often.
        let recipeA = makeRecipe(title: "Frequent")
        let recipeB = makeRecipe(title: "Rare")

        let mealsA = (0..<4).map { _ in makeMeal(recipe: recipeA, dueDate: date(weeksAgo: 3)) }
        let mealsB = [makeMeal(recipe: recipeB, dueDate: date(weeksAgo: 3))]

        let allMeals = mealsA + mealsB
        let service = makeService(cooldownWeeks: 0, cooldownPenalty: 1.0)

        var counts: [String: Int] = [:]
        let iterations = 1000

        for _ in 0..<iterations {
            if let recipe = service.findBestRecipeForMealType(
                .dinner, from: allMeals, excluding: [])
            {
                counts[recipe.uid, default: 0] += 1
            }
        }

        let countA = counts[recipeA.uid] ?? 0
        let countB = counts[recipeB.uid] ?? 0

        // Expected: A ≈ 80%, B ≈ 20% — check A is picked at least 60%
        let ratioA = Double(countA) / Double(iterations)
        XCTAssertGreaterThan(
            ratioA, 0.6,
            "Frequent recipe should be selected >60% of the time, got \(ratioA)")
        XCTAssertGreaterThan(
            countB, 0,
            "Rare recipe should still be selected occasionally")
    }

    // MARK: - Catalog-Based Selection

    func testCatalogSelectionRespectsNormalStatusFilter() {
        let normalRecipe = makeRecipe(title: "Normal Recipe")
        // A recipe that's "planned" (has an active meal associated with it)
        let plannedRecipe = makeRecipe(title: "Planned Recipe")
        // Simulate the planned recipe having an upcoming non-completed meal
        // Due date must be in the future for status == .planned
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let todoItem = Fixtures.todoItem(
            title: "Planned meal", details: "", dueDate: tomorrow, owner: user)
        context.insert(todoItem)
        let plannedMeal = Meal(
            scalingFactor: 1.0, todoItem: todoItem, recipe: plannedRecipe,
            mealType: .dinner, owner: user)
        context.insert(plannedMeal)

        let service = makeService()

        // With requireNormalStatus = true, the planned recipe should be excluded
        for _ in 0..<20 {
            let result = service.findPopularRecipeFromCatalog(
                allRecipes: [normalRecipe, plannedRecipe],
                excluding: [],
                requireNormalStatus: true
            )
            if let result {
                XCTAssertEqual(
                    result.uid, normalRecipe.uid,
                    "Only normal-status recipes should be returned when requireNormalStatus=true")
            }
        }
    }

    func testCatalogSelectionExcludesDeletedRecipes() {
        let activeRecipe = makeRecipe(title: "Active")
        let deletedRecipe = makeRecipe(title: "Deleted")
        deletedRecipe.deletedAt = Date()

        let service = makeService()

        for _ in 0..<20 {
            let result = service.findPopularRecipeFromCatalog(
                allRecipes: [activeRecipe, deletedRecipe],
                excluding: [],
                requireNormalStatus: false
            )
            if let result {
                XCTAssertEqual(
                    result.uid, activeRecipe.uid,
                    "Deleted recipes should never be returned")
            }
        }
    }

    func testCatalogSelectionUsesWeightedRandom() {
        // Multiple recipes with the same popularity should show variety
        let recipes = (1...4).map { makeRecipe(title: "Catalog \($0)") }

        let service = makeService()
        var selectedIds = Set<String>()

        for _ in 0..<200 {
            if let recipe = service.findPopularRecipeFromCatalog(
                allRecipes: recipes, excluding: [], requireNormalStatus: false)
            {
                selectedIds.insert(recipe.uid)
            }
        }

        XCTAssertGreaterThan(
            selectedIds.count, 1,
            "Catalog selection should show variety with equal-weight recipes")
    }

    func testEmptyCatalogReturnsNil() {
        let service = makeService()

        let result = service.findPopularRecipeFromCatalog(
            allRecipes: [], excluding: [], requireNormalStatus: false)
        XCTAssertNil(result, "Empty catalog should return nil")
    }

    // MARK: - Tiered Fallback

    func testSuggestRecipeUsesWeekdayMatchFirst() {
        // Set up: Recipe A on matching weekday, Recipe B on a different weekday.
        // Tier 0 should pick A most of the time before falling to Tier 1.
        let weekdayRecipe = makeRecipe(title: "Weekday Match")
        let anyDayRecipe = makeRecipe(title: "Any Day")

        // Weekday 2 (Monday) dinner
        let weekdayMeal = makeMeal(
            recipe: weekdayRecipe, dueDate: date(weeksAgo: 2, weekday: 2))
        // Weekday 5 (Thursday) dinner — won't match Tier 0 for Monday
        let anyDayMeal = makeMeal(
            recipe: anyDayRecipe, dueDate: date(weeksAgo: 2, weekday: 5))

        let service = makeService(cooldownWeeks: 0, cooldownPenalty: 1.0)
        let historicalMeals = [weekdayMeal, anyDayMeal]

        var counts: [String: Int] = [:]
        let iterations = 200

        for _ in 0..<iterations {
            if let recipe = service.suggestRecipe(
                for: 2, mealType: .dinner, historicalMeals: historicalMeals,
                allRecipes: [], excluding: [])
            {
                counts[recipe.uid, default: 0] += 1
            }
        }

        let weekdayCount = counts[weekdayRecipe.uid] ?? 0

        // Tier 0 has only weekdayRecipe, so it should always be picked
        XCTAssertEqual(
            weekdayCount, iterations,
            "Weekday match (Tier 0) should always be selected when available")
    }

    func testSuggestRecipeFallsBackToMealType() {
        // No weekday match, but a meal type match exists.
        let recipe = makeRecipe(title: "Dinner Recipe")
        // Create meal on weekday 5 (Thursday), we'll query for weekday 2 (Monday)
        let meal = makeMeal(recipe: recipe, dueDate: date(weeksAgo: 2, weekday: 5))

        let service = makeService(cooldownWeeks: 0, cooldownPenalty: 1.0)

        let result = service.suggestRecipe(
            for: 2, mealType: .dinner, historicalMeals: [meal],
            allRecipes: [], excluding: [])

        XCTAssertEqual(
            result?.uid, recipe.uid,
            "Should fall back to Tier 1 (meal type match) when Tier 0 finds nothing")
    }

    func testSuggestRecipeFallsBackToCatalog() {
        // No historical meals at all, but catalog has recipes.
        let catalogRecipe = makeRecipe(title: "Catalog Suggestion")

        let service = makeService()

        let result = service.suggestRecipe(
            for: 2, mealType: .dinner, historicalMeals: [],
            allRecipes: [catalogRecipe], excluding: [])

        XCTAssertEqual(
            result?.uid, catalogRecipe.uid,
            "Should fall back to catalog when history has no matches")
    }

    func testSuggestRecipeReturnsNilWhenEverythingExhausted() {
        let service = makeService()

        let result = service.suggestRecipe(
            for: 2, mealType: .dinner, historicalMeals: [],
            allRecipes: [], excluding: [])

        XCTAssertNil(result, "Should return nil when no recipes are available at any tier")
    }

    // MARK: - Undated (MealType-only) Suggestion

    func testSuggestRecipeForMealTypeSkipsTier0() {
        // Undated suggestion should not use weekday matching at all.
        let recipe = makeRecipe(title: "Flexible Recipe")
        let meal = makeMeal(recipe: recipe, dueDate: date(weeksAgo: 2, weekday: 5))

        let service = makeService(cooldownWeeks: 0, cooldownPenalty: 1.0)

        let result = service.suggestRecipeForMealType(
            .dinner, historicalMeals: [meal], allRecipes: [], excluding: [])

        XCTAssertEqual(
            result?.uid, recipe.uid,
            "Undated suggestion should find recipe via Tier 1")
    }

    func testSuggestRecipeForMealTypeFallsBackToCatalog() {
        let catalogRecipe = makeRecipe(title: "Catalog Fallback")

        let service = makeService()

        let result = service.suggestRecipeForMealType(
            .dinner, historicalMeals: [], allRecipes: [catalogRecipe], excluding: [])

        XCTAssertEqual(
            result?.uid, catalogRecipe.uid,
            "Undated suggestion should fall back to catalog")
    }

    // MARK: - Configuration Variations

    func testHighDecayRateFavorsRecentMealsMoreStrongly() {
        let recentRecipe = makeRecipe(title: "Recent")
        let oldRecipe = makeRecipe(title: "Old")

        let recentMeal = makeMeal(recipe: recentRecipe, dueDate: date(weeksAgo: 1))
        let oldMeal = makeMeal(recipe: oldRecipe, dueDate: date(weeksAgo: 8))

        let historicalMeals = [recentMeal, oldMeal]

        // High decay rate (0.5) — much stronger preference for recent
        let service = makeService(decayRate: 0.5, cooldownWeeks: 0, cooldownPenalty: 1.0)

        var recentCount = 0
        let iterations = 500

        for _ in 0..<iterations {
            if let recipe = service.findBestRecipeForMealType(
                .dinner, from: historicalMeals, excluding: [])
            {
                if recipe.uid == recentRecipe.uid { recentCount += 1 }
            }
        }

        // With decay 0.5: weight(1w) ≈ 0.61, weight(8w) ≈ 0.02 → ratio ≈ 97%
        let recentRatio = Double(recentCount) / Double(iterations)
        XCTAssertGreaterThan(
            recentRatio, 0.85,
            "High decay rate should pick recent recipe >85%, got \(recentRatio)")
    }

    func testZeroDecayRateGivesEqualWeightRegardlessOfAge() {
        let recentRecipe = makeRecipe(title: "Recent")
        let oldRecipe = makeRecipe(title: "Old")

        let recentMeal = makeMeal(recipe: recentRecipe, dueDate: date(weeksAgo: 1))
        let oldMeal = makeMeal(recipe: oldRecipe, dueDate: date(weeksAgo: 10))

        let historicalMeals = [recentMeal, oldMeal]

        // Zero decay — all ages have weight 1.0
        let service = makeService(decayRate: 0.0, cooldownWeeks: 0, cooldownPenalty: 1.0)

        var counts: [String: Int] = [:]
        let iterations = 1000

        for _ in 0..<iterations {
            if let recipe = service.findBestRecipeForMealType(
                .dinner, from: historicalMeals, excluding: [])
            {
                counts[recipe.uid, default: 0] += 1
            }
        }

        let recentRatio = Double(counts[recentRecipe.uid] ?? 0) / Double(iterations)
        // Should be roughly 50/50
        XCTAssertGreaterThan(
            recentRatio, 0.35,
            "Zero decay should give roughly equal selection, got \(recentRatio)")
        XCTAssertLessThan(
            recentRatio, 0.65,
            "Zero decay should give roughly equal selection, got \(recentRatio)")
    }

    func testDisabledCooldownDoesNotPenalize() {
        // cooldownPenalty = 1.0 effectively disables cooldown
        let recipe = makeRecipe(title: "Very Recent")
        let calendar = Calendar.current
        let recentDate = calendar.date(byAdding: .day, value: -2, to: targetWeekStart)!
        let meal = makeMeal(recipe: recipe, dueDate: recentDate)

        let service = makeService(cooldownWeeks: 1, cooldownPenalty: 1.0)

        let result = service.findBestRecipeForMealType(
            .dinner, from: [meal], excluding: [])
        XCTAssertNotNil(
            result, "Recipe should be selectable when cooldown is disabled (penalty=1.0)")
    }
}
