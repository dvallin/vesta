import SwiftData
import SwiftUI

class AddTodoItemViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private var dismiss: DismissAction?
    private var categoryService: TodoItemCategoryService?

    @Published var title: String = ""
    @Published var details: String = ""
    @Published var dueDate: Date? = nil
    @Published var recurrenceFrequency: RecurrenceFrequency? = nil
    @Published var recurrenceInterval: Int? = nil
    @Published var recurrenceType: RecurrenceType? = nil
    @Published var ignoreTimeComponent: Bool = true
    @Published var priority: Int = 4
    @Published var category: String = ""
    @Published var matchingCategories: [TodoItemCategory] = []

    @Published var showingValidationAlert = false
    @Published var validationMessage = ""
    @Published var showingDiscardAlert = false
    @Published var isSaving = false

    init(
        initialCategory: String = "",
        initialPriority: Int = 4,
        initialDueDate: Date? = nil
    ) {
        self.category = initialCategory
        self.priority = initialPriority
        self.dueDate = initialDueDate
    }

    func configureEnvironment(_ context: ModelContext, _ dismiss: DismissAction) {
        self.modelContext = context
        self.categoryService = TodoItemCategoryService(modelContext: context)
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
            let categoryEntity = categoryService?.fetchOrCreate(named: category)
            let todoItem = TodoItem.create(
                title: title, details: details, dueDate: dueDate,
                recurrenceFrequency: recurrenceFrequency, recurrenceType: recurrenceType,
                recurrenceInterval: recurrenceInterval,
                ignoreTimeComponent: ignoreTimeComponent,
                priority: priority,
                category: categoryEntity
            )

            modelContext!.insert(todoItem)

            if dueDate != nil {
                NotificationManager.shared.scheduleNotification(for: todoItem)
            }

            try modelContext!.save()

            HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)
            dismiss!()
        } catch {
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .error)
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

    func updateMatchingCategories() {
        guard let categoryService = categoryService else { return }
        matchingCategories = categoryService.findMatchingCategories(startingWith: category)
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
