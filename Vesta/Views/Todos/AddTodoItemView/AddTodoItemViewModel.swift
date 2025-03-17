import SwiftData
import SwiftUI

class AddTodoItemViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private var dismiss: DismissAction?

    @Published var title: String = ""
    @Published var details: String = ""
    @Published var dueDate: Date? = nil
    @Published var recurrenceFrequency: RecurrenceFrequency? = nil
    @Published var recurrenceInterval: Int? = nil
    @Published var recurrenceType: RecurrenceType? = nil
    @Published var ignoreTimeComponent: Bool = true

    @Published var showingValidationAlert = false
    @Published var validationMessage = ""
    @Published var showingDiscardAlert = false
    @Published var isSaving = false

    func configureEnvironment(_ context: ModelContext, _ dismiss: DismissAction) {
        self.modelContext = context
        self.dismiss = dismiss
    }

    @MainActor
    func save() {
        guard !title.isEmpty else {
            validationMessage = NSLocalizedString(
                "Please enter a todo title", comment: "Validation error for empty todo title")
            showingValidationAlert = true
            return
        }
        guard modelContext != nil else {
            validationMessage = NSLocalizedString(
                "Environment not configured",
                comment: "Error when environment is not properly configured")
            showingValidationAlert = true
            return
        }

        isSaving = true
        do {
            let newItem = TodoItem(
                title: title, details: details, dueDate: dueDate,
                recurrenceFrequency: recurrenceFrequency, recurrenceType: recurrenceType,
                recurrenceInterval: recurrenceInterval, ignoreTimeComponent: ignoreTimeComponent)
            modelContext!.insert(newItem)

            try modelContext!.save()

            dismiss!()
        } catch {
            validationMessage = String(
                format: NSLocalizedString(
                    "Error saving todo item: %@",
                    comment: "Error message when saving todo item fails"),
                error.localizedDescription
            )
            showingValidationAlert = true
        }
        isSaving = false
    }

    @MainActor
    func cancel() {
        if !title.isEmpty || !details.isEmpty {
            showingDiscardAlert = true
        } else {
            dismiss!()
        }
    }

    @MainActor
    func discard() {
        dismiss!()
    }
}
