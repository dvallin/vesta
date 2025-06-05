import SwiftUI

struct TodoItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var auth: UserAuthService
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
                    updateMatchingCategories: viewModel.updateMatchingCategories
                )

                Section(NSLocalizedString("Actions", comment: "Actions section header")) {
                    Button(action: { viewModel.markAsDone() }) {
                        Label(
                            NSLocalizedString("Mark as Done", comment: "Mark as done button"),
                            systemImage: "checkmark.circle")
                    }

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
                viewModel.configureEnvironment(modelContext, dismiss, auth)
            }
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
