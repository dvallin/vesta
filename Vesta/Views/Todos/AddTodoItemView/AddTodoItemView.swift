import SwiftUI

struct AddTodoItemView: View {
    @EnvironmentObject private var auth: UserAuthService
    @EnvironmentObject private var syncService: SyncService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject var viewModel: AddTodoItemViewModel = AddTodoItemViewModel()

    @FocusState private var focusedField: String?

    init(
        selectedCategory: TodoItemCategory? = nil,
        selectedPriority: Int = 4,
        presetDueDate: Date? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: AddTodoItemViewModel(
                initialCategory: selectedCategory?.name ?? "",
                initialPriority: selectedPriority,
                initialDueDate: presetDueDate
            ))
    }

    var body: some View {
        NavigationView {
            Form {
                TitleDetailsSection(
                    title: $viewModel.title, details: $viewModel.details,
                    focusedField: $focusedField)

                DueDateRecurrenceSection(
                    dueDate: $viewModel.dueDate,
                    recurrenceFrequency: $viewModel.recurrenceFrequency,
                    recurrenceInterval: $viewModel.recurrenceInterval,
                    recurrenceType: $viewModel.recurrenceType,
                    ignoreTimeComponent: $viewModel.ignoreTimeComponent
                )

                PriorityCategorySection(
                    priority: $viewModel.priority,
                    category: $viewModel.category,
                    matchingCategories: $viewModel.matchingCategories,
                    focusedField: $focusedField,
                    updateMatchingCategories: viewModel.updateMatchingCategories
                )
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
        }
        .navigationTitle(NSLocalizedString("Add Todo Item", comment: "Add todo item view title"))
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            viewModel.configureEnvironment(modelContext, dismiss, auth, syncService)
        }
    }
}

#Preview {
    AddTodoItemView()
}
