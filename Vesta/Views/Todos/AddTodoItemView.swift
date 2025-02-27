import SwiftUI

struct AddTodoItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var details: String = ""
    @State private var dueDate: Date? = nil
    @State private var recurrenceFrequency: RecurrenceFrequency? = nil
    @State private var recurrenceType: RecurrenceType? = nil

    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @State private var showingDiscardAlert = false
    @State private var isSaving = false

    @FocusState private var focusedField: String?

    var body: some View {
        NavigationView {
            Form {
                TitleDetailsSection(title: $title, details: $details, focusedField: $focusedField)

                DueDateRecurrenceSection(
                    dueDate: $dueDate,
                    recurrenceFrequency: $recurrenceFrequency,
                    recurrenceType: $recurrenceType
                )
            }
            .navigationTitle("Add Todo Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if !title.isEmpty || !details.isEmpty {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        validateAndSave()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .alert("Validation Error", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
            .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Continue Editing", role: .cancel) {}
            }
        }
    }

    private func validateAndSave() {
        guard !title.isEmpty else {
            validationMessage = "Please enter a todo title"
            showingValidationAlert = true
            return
        }
        saveTodoItem()
    }

    private func saveTodoItem() {
        isSaving = true
        do {
            let newItem = TodoItem(
                title: title, details: details, dueDate: dueDate,
                recurrenceFrequency: recurrenceFrequency, recurrenceType: recurrenceType)
            modelContext.insert(newItem)

            try modelContext.save()
            dismiss()
        } catch {
            validationMessage = "Error saving todo item: \(error.localizedDescription)"
            showingValidationAlert = true
        }
        isSaving = false
    }
}

#Preview {
    AddTodoItemView()
}
