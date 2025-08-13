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
        NavigationView {
            Form {
                TitleDetailsSection(
                    title: $viewModel.tempTitle, details: $viewModel.tempDetails,
                    focusedField: $focusedField)

                DueDateRecurrenceSection(
                    dueDate: $viewModel.tempDueDate,
                    recurrenceFrequency: $viewModel.tempRecurrenceFrequency,
                    recurrenceInterval: $viewModel.tempRecurrenceInterval,
                    recurrenceType: $viewModel.tempRecurrenceType,
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

                // --- Completion Statistics Section ---
                Section(
                    NSLocalizedString(
                        "Completion Statistics", comment: "Completion statistics section header")
                ) {
                    if let mean = viewModel.item.meanCompletionDistance {
                        HStack {
                            Text(
                                NSLocalizedString(
                                    "Mean Completion Time", comment: "Mean completion time label"))
                            Spacer()
                            Text(formatDistance(mean))
                                .foregroundColor(.secondary)
                        }
                    }
                    if let median = viewModel.item.medianCompletionDistance {
                        HStack {
                            Text(
                                NSLocalizedString(
                                    "Median Completion Time",
                                    comment: "Median completion time label"))
                            Spacer()
                            Text(formatDistance(median))
                                .foregroundColor(.secondary)
                        }
                    }
                    if let variance = viewModel.item.varianceCompletionDistance {
                        HStack {
                            Text(NSLocalizedString("Variance", comment: "Variance label"))
                            Spacer()
                            Text(formatDistance(variance, isVariance: true))
                                .foregroundColor(.secondary)
                        }
                    }
                    if viewModel.item.completionDistances.isEmpty {
                        Text(
                            NSLocalizedString(
                                "No completion data yet.", comment: "No completion data message")
                        )
                        .foregroundColor(.secondary)
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

                ToolbarItem(placement: .keyboard) {
                    Button(NSLocalizedString("Done", comment: "Done button")) {
                        focusedField = nil
                    }
                }
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
