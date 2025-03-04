import SwiftUI

struct AddTodoItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject var viewModel: AddTodoItemViewModel = AddTodoItemViewModel()

    @FocusState private var focusedField: String?

    var body: some View {
        NavigationView {
            Form {
                TitleDetailsSection(
                    title: $viewModel.title, details: $viewModel.details,
                    focusedField: $focusedField)

                DueDateRecurrenceSection(
                    dueDate: $viewModel.dueDate,
                    recurrenceFrequency: $viewModel.recurrenceFrequency,
                    recurrenceType: $viewModel.recurrenceType
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        Task {
                            viewModel.cancel()
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.save()
                    }
                    .disabled(viewModel.isSaving)
                }

                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .alert("Validation Error", isPresented: $viewModel.showingValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.validationMessage)
            }
            .alert("Discard Changes?", isPresented: $viewModel.showingDiscardAlert) {
                Button("Discard", role: .destructive) {
                    Task {
                        viewModel.discard()
                    }
                }
                Button("Continue Editing", role: .cancel) {}
            }
        }
        .navigationTitle("Add Todo Item")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.configureEnvironment(modelContext, dismiss)
        }
    }
}

#Preview {
    AddTodoItemView()
}
