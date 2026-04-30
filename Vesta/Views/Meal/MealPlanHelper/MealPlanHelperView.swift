import SwiftData
import SwiftUI

struct MealPlanHelperView: View {
    @EnvironmentObject private var auth: UserAuthService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query<Meal>(
        filter: #Predicate { meal in meal.deletedAt == nil }
    ) private var allMeals: [Meal]
    @Query<Recipe>(
        filter: #Predicate { recipe in recipe.deletedAt == nil }
    ) private var allRecipes: [Recipe]

    @StateObject var viewModel: MealPlanHelperViewModel

    init(filterMode: MealPlanFilterMode) {
        _viewModel = StateObject(wrappedValue: MealPlanHelperViewModel(filterMode: filterMode))
    }

    var body: some View {
        NavigationStack {
            List {
                // Planned meals section
                if !viewModel.plannedMeals.isEmpty {
                    Section {
                        ForEach(viewModel.plannedMeals) { meal in
                            PlannedMealRow(meal: meal)
                        }
                    } header: {
                        Text(
                            NSLocalizedString(
                                "Already Planned", comment: "Planned meals section header"))
                    }
                }

                // Proposals section
                if !viewModel.pendingProposals.isEmpty {
                    Section {
                        ForEach(viewModel.pendingProposals) { proposal in
                            ProposalRow(
                                proposal: proposal,
                                onAccept: {
                                    Task {
                                        await viewModel.acceptProposal(proposal)
                                    }
                                },
                                onDecline: {
                                    viewModel.declineProposal(proposal)
                                }
                            )
                        }
                    } header: {
                        HStack {
                            Text(
                                NSLocalizedString(
                                    "Suggestions", comment: "Suggestions section header"))
                            Spacer()
                            if viewModel.pendingProposals.count > 1 {
                                Button(action: {
                                    Task {
                                        await viewModel.acceptAllPending()
                                    }
                                }) {
                                    Text(
                                        NSLocalizedString(
                                            "Accept All", comment: "Accept all button")
                                    )
                                    .font(.caption)
                                }
                            }
                        }
                    }
                }

                // Empty state when no proposals
                if viewModel.pendingProposals.isEmpty && viewModel.proposals.isEmpty {
                    Section {
                        ContentUnavailableView(
                            NSLocalizedString("No Suggestions", comment: "No suggestions title"),
                            systemImage: "lightbulb",
                            description: Text(
                                NSLocalizedString(
                                    "No meals from the previous week match your gaps.",
                                    comment: "No suggestions description"
                                )
                            )
                        )
                    }
                }

                // All handled state
                if viewModel.allProposalsHandled && !viewModel.proposals.isEmpty {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.green)
                                Text(
                                    NSLocalizedString(
                                        "All suggestions handled!", comment: "All handled message")
                                )
                                .font(.headline)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Plan Helper", comment: "Plan helper title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Done", comment: "Done button")) {
                        dismiss()
                    }
                }
            }
            .alert(
                NSLocalizedString("Error", comment: "Error alert title"),
                isPresented: $viewModel.showingErrorAlert
            ) {
                Button(NSLocalizedString("OK", comment: "OK button"), role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .onAppear {
            viewModel.configureEnvironment(modelContext, auth)
            viewModel.analyzeAndPropose(allMeals: allMeals, allRecipes: allRecipes)
        }
    }
}

// MARK: - Planned Meal Row

struct PlannedMealRow: View {
    let meal: Meal

    private var dayName: String {
        guard let date = meal.todoItem?.dueDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.recipe?.title ?? "No Recipe")
                    .font(.body)
                HStack(spacing: 4) {
                    if !dayName.isEmpty {
                        Text(dayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(meal.mealType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
        }
    }
}

// MARK: - Proposal Row

struct ProposalRow: View {
    let proposal: MealProposal
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Gap info
            HStack(spacing: 4) {
                if let weekdayName = proposal.gap.weekdayName {
                    Text(weekdayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("•")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Text(proposal.gap.mealType.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Suggested recipe
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(NSLocalizedString("Suggestion:", comment: "Suggestion label"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(proposal.suggestedRecipe.title)
                        .font(.body)
                }

                Spacer()

                // Accept/Decline buttons
                HStack(spacing: 12) {
                    Button(action: onDecline) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(BorderlessButtonStyle())

                    Button(action: onAccept) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
        .padding(.vertical, 4)
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

        // Create meals for previous week
        let calendar = Calendar.current
        let now = Date()
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!

        for (index, recipe) in recipes.enumerated() {
            let dayOffset = index * 2
            let date = calendar.date(byAdding: .day, value: dayOffset, to: lastWeekStart)!
            let todoItem = TodoItem(
                title: recipe.title,
                details: recipe.details,
                dueDate: date,
                owner: user
            )
            context.insert(todoItem)

            let meal = Meal(
                scalingFactor: 1.0,
                todoItem: todoItem,
                recipe: recipe,
                mealType: index % 2 == 0 ? .dinner : .lunch,
                owner: user
            )
            context.insert(meal)
        }

        let authService = UserAuthService(modelContext: context)
        return MealPlanHelperView(filterMode: .currentWeek)
            .modelContainer(container)
            .environmentObject(authService)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
