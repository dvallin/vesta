import SwiftUI

struct TodoItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var auth: UserAuthService
    @EnvironmentObject private var syncService: SyncService
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: TodoItemDetailViewModel

    @FocusState private var focusedField: String?

    init(item: TodoItem) {
        _viewModel = State(initialValue: TodoItemDetailViewModel(item: item))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
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
                            "Streak", comment: "Streak section header")
                    ) {
                        HStack {
                            Text(
                                NSLocalizedString(
                                    "Current Streak", comment: "Current streak label"))
                            Spacer()
                            HStack(spacing: 4) {
                                if viewModel.item.currentStreak > 0 {
                                    Image(systemName: "flame.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                Text("\(viewModel.item.currentStreak)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        HStack {
                            Text(
                                NSLocalizedString(
                                    "Best Streak", comment: "Best streak label"))
                            Spacer()
                            HStack(spacing: 4) {
                                if viewModel.item.isPersonalBest {
                                    Image(systemName: "trophy.fill")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                                Text("\(viewModel.item.bestStreak)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        if viewModel.item.currentStreak > 0 {
                            Text(
                                streakMotivationText(
                                    streak: viewModel.item.currentStreak,
                                    best: viewModel.item.bestStreak)
                            )
                            .font(.caption)
                            .foregroundColor(.orange)
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

    private func streakMotivationText(streak: Int, best: Int) -> String {
        if streak >= best && streak >= 7 {
            return NSLocalizedString(
                "\u{1F3C6} New personal best! You're on fire!",
                comment: "Streak motivation: personal best high")
        } else if streak >= best && streak >= 3 {
            return NSLocalizedString(
                "\u{1F3C6} Personal best \u{2014} keep it going!",
                comment: "Streak motivation: matching best")
        } else if streak >= 15 {
            return NSLocalizedString(
                "Incredible discipline \u{2014} you're unstoppable",
                comment: "Streak motivation: very high streak")
        } else if streak >= 7 {
            return NSLocalizedString(
                "Solid streak \u{2014} consistency pays off",
                comment: "Streak motivation: high streak")
        } else if streak >= 3 {
            return NSLocalizedString(
                "Building momentum \u{2014} don't break the chain!",
                comment: "Streak motivation: medium streak")
        } else {
            return NSLocalizedString(
                "Every completion counts \u{2014} keep going",
                comment: "Streak motivation: low streak")
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
