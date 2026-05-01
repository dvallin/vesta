import SwiftData
import SwiftUI

/// Represents a gap in the meal plan
struct MealGap: Identifiable, Equatable {
    let id = UUID()
    let date: Date?
    let mealType: MealType

    var weekdayName: String? {
        guard let date else { return nil }
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
    private let lookbackWeeks = 12

    /// Number of proposals if not running week based
    private let undatedProposalCount = 5

    /// Cutoff hour for lunch proposals (don't suggest lunch after this hour)
    private let lunchCutoffHour = 13

    /// Scoring service for recipe suggestions
    private var scoringService: RecipeScoringService {
        RecipeScoringService(targetWeekStart: targetWeekStart, lookbackWeeks: lookbackWeeks)
    }

    /// Analyzes meals and generates proposals for gaps
    /// - Parameters:
    ///   - allMeals: All meals in the system
    ///   - allRecipes: All recipes in the catalog (for fallback suggestions)
    func analyzeAndPropose(allMeals: [Meal], allRecipes: [Recipe] = []) {
        if filterMode == .all {
            analyzeAndProposeUndated(allMeals: allMeals, allRecipes: allRecipes)
            return
        }

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
        let historicalMeals = scoringService.getHistoricalMeals(from: allMeals)

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

                    // Find best recipe using scoring service
                    let recipe = scoringService.suggestRecipe(
                        for: targetWeekday,
                        mealType: mealType,
                        historicalMeals: historicalMeals,
                        allRecipes: allRecipes,
                        excluding: excluded
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

    private func analyzeAndProposeUndated(allMeals: [Meal], allRecipes: [Recipe]) {
        let historicalMeals = scoringService.getHistoricalMeals(from: allMeals)

        // Show existing undated meals in the "Already Planned" section
        plannedMeals =
            allMeals
            .filter { $0.todoItem?.dueDate == nil }
            .sorted { ($0.recipe?.title ?? "") < ($1.recipe?.title ?? "") }

        // Exclude recipes already present as undated meals
        let existingRecipeIds = Set(plannedMeals.compactMap { $0.recipe?.uid })
        var proposedRecipeIds = existingRecipeIds
        var newProposals: [MealProposal] = []

        // Alternate dinner/lunch for variety
        let mealSequence: [MealType] = Array(
            Array(
                repeating: [MealType.dinner, .lunch],
                count: (undatedProposalCount + 1) / 2
            ).flatMap { $0 }.prefix(undatedProposalCount))

        for mealType in mealSequence {
            let gap = MealGap(date: nil, mealType: mealType)
            let recipe = scoringService.suggestRecipeForMealType(
                mealType,
                historicalMeals: historicalMeals,
                allRecipes: allRecipes,
                excluding: proposedRecipeIds
            )

            if let recipe {
                newProposals.append(MealProposal(gap: gap, suggestedRecipe: recipe))
                proposedRecipeIds.insert(recipe.uid)
            }
        }

        proposals = newProposals
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
            let dueDate: Date?
            if let gapDate = proposal.gap.date {
                let (hour, minute) = DateUtils.mealTime(for: proposal.gap.mealType)
                dueDate = DateUtils.setTime(hour: hour, minute: minute, for: gapDate)
            } else {
                dueDate = nil
            }

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
