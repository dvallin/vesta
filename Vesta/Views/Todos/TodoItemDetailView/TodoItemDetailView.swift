import SwiftUI

struct TodoItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var auth: UserAuthService
    @EnvironmentObject private var syncService: SyncService
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: TodoItemDetailViewModel

    @FocusState private var focusedField: String?

    init(item: TodoItem) {
        _viewModel = StateObject(wrappedValue: TodoItemDetailViewModel(item: item))
    }

    var body: some View {
        NavigationStack {
            Form {
                TitleDetailsSection(
                    title: $viewModel.tempTitle, details: $viewModel.tempDetails,
                    focusedField: $focusedField)

                DueDateRecurrenceSection(
                    dueDate: $viewModel.tempDueDate,
                    recurrenceFrequency: $viewModel.tempRecurrenceFrequency,
                    recurrenceInterval: $viewModel.tempRecurrenceInterval,
                    recurrenceType: $viewModel.tempRecurrenceType,
                    repeatOn: $viewModel.tempRepeatOn,
                    ignoreTimeComponent: $viewModel.tempIgnoreTimeComponent
                )

                PriorityCategorySection(
                    priority: $viewModel.tempPriority,
                    category: $viewModel.tempCategory,
                    matchingCategories: $viewModel.matchingCategories,
                    focusedField: $focusedField,
                    updateMatchingCategories: { text in
                        viewModel.updateMatchingCategories(for: text)
                    }
                )

                if viewModel.item.isHabitItem {
                    Section(
                        NSLocalizedString(
                            "Habits", comment: "Habits section header")
                    ) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(
                                    NSLocalizedString(
                                        "Health", comment: "Health label"))
                                Spacer()
                                HStack(spacing: 4) {
                                    Text("\(viewModel.item.health)%")
                                        .foregroundColor(.secondary)
                                    Image(
                                        systemName: viewModel.item.healthTrend
                                            .systemImage
                                    )
                                    .font(.caption)
                                    .foregroundColor(
                                        trendColor(viewModel.item.healthTrend))
                                }
                            }
                            Text(
                                healthMotivationText(
                                    health: viewModel.item.health,
                                    trend: viewModel.item.healthTrend)
                            )
                            .font(.caption)
                            .foregroundColor(
                                trendColor(viewModel.item.healthTrend)
                            )
                            .padding(.leading, 0)
                        }
                        HStack {
                            Text(
                                NSLocalizedString(
                                    "Current Streak", comment: "Current streak label"))
                            Spacer()
                            Text("\(viewModel.item.currentStreak)")
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text(
                                NSLocalizedString(
                                    "Best Streak", comment: "Best streak label"))
                            Spacer()
                            HStack(spacing: 4) {
                                if viewModel.item.bestStreak > 0
                                    && viewModel.item.currentStreak
                                        >= viewModel.item.bestStreak
                                {
                                    Image(systemName: "trophy.fill")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                                Text("\(viewModel.item.bestStreak)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(
                                    NSLocalizedString(
                                        "On-Time Rate",
                                        comment: "On-time rate label"))
                                Spacer()
                                Text(
                                    "\(Int(viewModel.item.onTimeRate * 100))%"
                                )
                                .foregroundColor(.secondary)
                            }
                            Text(
                                NSLocalizedString(
                                    "Percentage of completions on or before the due date",
                                    comment: "On-time rate explanation text")
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 0)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(
                                    NSLocalizedString(
                                        "Tolerance", comment: "Streak tolerance label"))
                                Spacer()
                                Text(
                                    String.localizedStringWithFormat(
                                        NSLocalizedString(
                                            "%d days", comment: "Days tolerance format"),
                                        viewModel.item.currentToleranceDays)
                                )
                                .foregroundColor(.secondary)
                            }
                            Text(
                                NSLocalizedString(
                                    "How many days late you can complete this without breaking your streak",
                                    comment: "Tolerance explanation text")
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 0)
                        }
                    }
                }

                Section(NSLocalizedString("Actions", comment: "Actions section header")) {
                    Button(action: { viewModel.markAsDone() }) {
                        Label(
                            NSLocalizedString("Mark as Done", comment: "Mark as done button"),
                            systemImage: "checkmark.circle")
                    }

                    Button(action: { viewModel.skip() }) {
                        Label(
                            NSLocalizedString("Skip", comment: "Skip button"),
                            systemImage: "forward.end")
                    }
                    .disabled(viewModel.item.recurrenceFrequency == nil)

                    Toggle(
                        NSLocalizedString("Completed", comment: "Completed toggle label"),
                        isOn: $viewModel.tempIsCompleted
                    )
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                            Task {
                                viewModel.cancel()
                            }
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(NSLocalizedString("Save", comment: "Save button")) {
                            viewModel.save()
                        }
                        .disabled(viewModel.isSaving)
                    }
                #endif

            }
            .alert(
                NSLocalizedString("Validation Error", comment: "Validation error alert title"),
                isPresented: $viewModel.showingValidationAlert
            ) {
                Button(NSLocalizedString("OK", comment: "OK button"), role: .cancel) {}
            } message: {
                Text(viewModel.validationMessage)
            }
            .alert(
                NSLocalizedString("Discard Changes?", comment: "Discard changes alert title"),
                isPresented: $viewModel.showingDiscardAlert
            ) {
                Button(NSLocalizedString("Discard", comment: "Discard button"), role: .destructive)
                {
                    Task {
                        viewModel.discard()
                    }
                }
                Button(
                    NSLocalizedString("Continue Editing", comment: "Continue editing button"),
                    role: .cancel
                ) {}
            }
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                viewModel.configureEnvironment(modelContext, dismiss, auth, syncService)
            }
        }
    }

    private func trendColor(_ trend: HealthTrend) -> Color {
        switch trend {
        case .improving:
            return .green
        case .stable:
            return .secondary
        case .declining:
            return .orange
        }
    }

    private func healthMotivationText(health: Int, trend: HealthTrend) -> String {
        switch (health, trend) {
        // High health
        case (80...100, .improving):
            return NSLocalizedString(
                "Exceptional! You're at peak performance",
                comment: "Health motivation: high health, improving")
        case (80...100, .stable):
            return NSLocalizedString(
                "Solid habit — keep up the great rhythm",
                comment: "Health motivation: high health, stable")
        case (80...100, .declining):
            return NSLocalizedString(
                "Still strong, but watch the timing",
                comment: "Health motivation: high health, declining")
        // Medium-high health
        case (60..<80, .improving):
            return NSLocalizedString(
                "Nice momentum — you're building consistency",
                comment: "Health motivation: medium-high health, improving")
        case (60..<80, .stable):
            return NSLocalizedString(
                "Good pace — a few more on time will push you higher",
                comment: "Health motivation: medium-high health, stable")
        case (60..<80, .declining):
            return NSLocalizedString(
                "Slipping a bit — try completing before the due date",
                comment: "Health motivation: medium-high health, declining")
        // Medium-low health
        case (40..<60, .improving):
            return NSLocalizedString(
                "Recovering well — keep the streak going",
                comment: "Health motivation: medium-low health, improving")
        case (40..<60, .stable):
            return NSLocalizedString(
                "Steady — each on-time completion builds health",
                comment: "Health motivation: medium-low health, stable")
        case (40..<60, .declining):
            return NSLocalizedString(
                "Needs attention — try not to let it slip further",
                comment: "Health motivation: medium-low health, declining")
        // Low health
        case (_, .improving):
            return NSLocalizedString(
                "Good start — every completion counts",
                comment: "Health motivation: low health, improving")
        case (_, .stable):
            return NSLocalizedString(
                "Build your streak — consistency is key",
                comment: "Health motivation: low health, stable")
        case (_, .declining):
            return NSLocalizedString(
                "Fresh start — one completion is all it takes",
                comment: "Health motivation: low health, declining")
        }
    }

    func formatDistance(_ interval: TimeInterval, isVariance: Bool = false) -> String {
        let absInterval = abs(interval)
        let days = Int(absInterval) / 86400
        let hours = (Int(absInterval) % 86400) / 3600
        let minutes = (Int(absInterval) % 3600) / 60

        var components: [String] = []
        if days > 0 { components.append("\(days)d") }
        if hours > 0 { components.append("\(hours)h") }
        if minutes > 0 && days == 0 { components.append("\(minutes)m") }

        let base = components.isEmpty ? "<1m" : components.joined(separator: " ")
        if isVariance {
            return base
        }
        if interval < 0 {
            return String(format: NSLocalizedString("%@ early", comment: "Completed early"), base)
        } else if interval > 0 {
            return String(format: NSLocalizedString("%@ late", comment: "Completed late"), base)
        } else {
            return NSLocalizedString("On time", comment: "Completed on time")
        }
    }
}

#Preview {
    TodoItemDetailView(
        item: TodoItem(
            title: "Buy groceries",
            details: "Milk, Bread, Eggs, Fresh vegetables, and fruits for the week",
            dueDate: Date().addingTimeInterval(3600),
            owner: Fixtures.createUser()
        )
    )
    .modelContainer(for: TodoItem.self)
}

#Preview("With Recurrence") {
    TodoItemDetailView(
        item: TodoItem(
            title: "Weekly Team Meeting",
            details:
                "Discuss project progress and upcoming milestones with the development team",
            dueDate: Date().addingTimeInterval(24 * 3600),
            recurrenceFrequency: .weekly,
            recurrenceType: .fixed,
            owner: Fixtures.createUser()
        )
    )
    .modelContainer(for: TodoItem.self)
}

#Preview("Completed") {
    TodoItemDetailView(
        item: TodoItem(
            title: "Send Project Proposal",
            details: "Final review and submission of the Q4 project proposal",
            dueDate: Date().addingTimeInterval(-24 * 3600),
            isCompleted: true,
            owner: Fixtures.createUser()
        )
    )
    .modelContainer(for: TodoItem.self)
}

#Preview("No Due Date") {
    TodoItemDetailView(
        item: TodoItem(
            title: "Read Design Patterns Book",
            details: "Study and take notes on the Gang of Four design patterns",
            dueDate: nil,
            owner: Fixtures.createUser()
        )
    )
    .modelContainer(for: TodoItem.self)
}
