import SwiftData
import SwiftUI

@Observable class AddTodoItemViewModel {
    private var modelContext: ModelContext?
    private var dismiss: DismissAction?
    private var categoryService: TodoItemCategoryService?
    private var auth: UserAuthService?
    private var syncService: SyncService?

    var title: String = ""
    var details: String = ""
    var dueDate: Date? = nil
    var recurrenceFrequency: RecurrenceFrequency? = nil
    var recurrenceInterval: Int? = nil
    var recurrenceType: RecurrenceType? = nil
    var repeatOn: [DayOfWeek]? = nil
    var ignoreTimeComponent: Bool = true
    var priority: Int = 4
    var category: String = ""
    var matchingCategories: [TodoItemCategory] = []

    var showingValidationAlert = false
    var validationMessage = ""
    var showingDiscardAlert = false
    var isSaving = false

    init(
        initialCategory: String = "",
        initialPriority: Int = 4,
        initialDueDate: Date? = nil
    ) {
        self.category = initialCategory
        self.priority = initialPriority
        self.dueDate = initialDueDate
    }

    func configureEnvironment(
        _ context: ModelContext, _ dismiss: DismissAction, _ auth: UserAuthService,
        _ syncService: SyncService
    ) {
        self.modelContext = context
        self.categoryService = TodoItemCategoryService(modelContext: context)
        self.dismiss = dismiss
        self.auth = auth
        self.syncService = syncService
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
        guard let currentUser = auth?.currentUser else { return }

        isSaving = true
        do {
            let categoryEntity = categoryService?.fetchOrCreate(named: category)
            let todoItem = TodoItem.create(
                title: title, details: details, dueDate: dueDate,
                recurrenceFrequency: recurrenceFrequency, recurrenceType: recurrenceType,
                repeatOn: repeatOn, recurrenceInterval: recurrenceInterval,
                ignoreTimeComponent: ignoreTimeComponent,
                priority: priority,
                category: categoryEntity,
                owner: currentUser
            )

            modelContext!.insert(todoItem)

            NotificationManager.shared.scheduleNotification(for: todoItem)

            try modelContext!.save()

            _ = syncService?.pushLocalChanges()

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

    func updateMatchingCategories(for inputText: String? = nil) {
        guard let categoryService = categoryService else { return }
        let searchText = inputText ?? category
        matchingCategories = categoryService.findMatchingCategories(startingWith: searchText)
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
