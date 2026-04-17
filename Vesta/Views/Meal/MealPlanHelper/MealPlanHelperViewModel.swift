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

    /// Analyzes meals and generates proposals for gaps
    func analyzeAndPropose(allMeals: [Meal]) {
        let calendar = Calendar.current

        // Get target week dates
        let targetWeekDates = (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: targetWeekStart)
        }

        // Get previous week start
        guard
            let previousWeekStart = calendar.date(
                byAdding: .weekOfYear, value: -1, to: targetWeekStart)
        else {
            return
        }

        // Filter meals for target week and previous week
        let targetWeekMeals = allMeals.filter { meal in
            guard let dueDate = meal.todoItem?.dueDate else { return false }
            let startOfDay = calendar.startOfDay(for: dueDate)
            return targetWeekDates.contains { calendar.isDate($0, inSameDayAs: startOfDay) }
        }

        let previousWeekMeals = allMeals.filter { meal in
            guard let dueDate = meal.todoItem?.dueDate else { return false }
            let mealWeekStart = calendar.dateInterval(of: .weekOfYear, for: dueDate)?.start
            return mealWeekStart == previousWeekStart
        }

        // Store planned meals for display
        plannedMeals = targetWeekMeals.sorted {
            ($0.todoItem?.dueDate ?? .distantFuture) < ($1.todoItem?.dueDate ?? .distantFuture)
        }

        // Find gaps (only lunch and dinner, skip breakfast)
        let mealTypesToPlan: [MealType] = [.lunch, .dinner]
        var newProposals: [MealProposal] = []

        for date in targetWeekDates {
            for mealType in mealTypesToPlan {
                // Check if there's already a meal planned for this day/type
                let hasPlannedMeal = targetWeekMeals.contains { meal in
                    guard let dueDate = meal.todoItem?.dueDate else { return false }
                    return calendar.isDate(dueDate, inSameDayAs: date) && meal.mealType == mealType
                }

                if !hasPlannedMeal {
                    let gap = MealGap(date: date, mealType: mealType)

                    // Look for a matching meal from previous week (same weekday, same meal type)
                    let targetWeekday = calendar.component(.weekday, from: date)

                    if let previousMeal = previousWeekMeals.first(where: { meal in
                        guard let dueDate = meal.todoItem?.dueDate else { return false }
                        let mealWeekday = calendar.component(.weekday, from: dueDate)
                        return mealWeekday == targetWeekday && meal.mealType == mealType
                    }),
                        let recipe = previousMeal.recipe
                    {
                        let proposal = MealProposal(gap: gap, suggestedRecipe: recipe)
                        newProposals.append(proposal)
                    }
                }
            }
        }

        proposals = newProposals
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
