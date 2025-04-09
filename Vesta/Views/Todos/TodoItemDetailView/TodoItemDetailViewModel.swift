import SwiftData
import SwiftUI

class TodoItemDetailViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private var dismiss: DismissAction?
    private var categoryService: TodoItemCategoryService?
    private var userService: UserService?

    @Published var item: TodoItem

    // Temporary values for editing
    @Published var tempTitle: String
    @Published var tempDetails: String
    @Published var tempDueDate: Date?
    @Published var tempRecurrenceFrequency: RecurrenceFrequency?
    @Published var tempRecurrenceInterval: Int?
    @Published var tempRecurrenceType: RecurrenceType?
    @Published var tempIgnoreTimeComponent: Bool
    @Published var tempIsCompleted: Bool
    @Published var tempPriority: Int
    @Published var tempCategory: String
    @Published var matchingCategories: [TodoItemCategory] = []

    @Published var showingValidationAlert = false
    @Published var validationMessage = ""
    @Published var showingDiscardAlert = false
    @Published var isSaving = false

    init(item: TodoItem) {
        self.item = item
        self.tempTitle = item.title
        self.tempDetails = item.details
        self.tempDueDate = item.dueDate
        self.tempRecurrenceFrequency = item.recurrenceFrequency
        self.tempRecurrenceInterval = item.recurrenceInterval
        self.tempRecurrenceType = item.recurrenceType
        self.tempIgnoreTimeComponent = item.ignoreTimeComponent
        self.tempIsCompleted = item.isCompleted
        self.tempPriority = item.priority
        self.tempCategory = item.category?.name ?? ""
    }

    func configureEnvironment(
        _ context: ModelContext, _ dismiss: DismissAction, _ userService: UserService
    ) {
        self.modelContext = context
        self.categoryService = TodoItemCategoryService(modelContext: context)
        self.dismiss = dismiss
        self.userService = userService
    }

    var isDirty: Bool {
        return tempTitle != item.title || tempDetails != item.details || tempDueDate != item.dueDate
            || tempRecurrenceFrequency != item.recurrenceFrequency
            || tempRecurrenceInterval != item.recurrenceInterval
            || tempRecurrenceType != item.recurrenceType
            || tempIgnoreTimeComponent != item.ignoreTimeComponent
            || tempIsCompleted != item.isCompleted
            || tempPriority != item.priority
            || tempCategory != item.category?.name
    }

    func markAsDone() {
        guard let currentUser = userService?.currentUser else { return }
        withAnimation {
            item.markAsDone(currentUser: currentUser)
            saveContext()
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)
        }
    }

    func save() {
        guard let currentUser = userService?.currentUser else { return }
        guard !tempTitle.isEmpty else {
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

        if tempTitle != item.title {
            item.setTitle(title: tempTitle, currentUser: currentUser)
        }
        if tempDetails != item.details {
            item.setDetails(details: tempDetails, currentUser: currentUser)
        }
        if tempDueDate != item.dueDate {
            item.setDueDate(dueDate: tempDueDate, currentUser: currentUser)
        }
        if tempRecurrenceFrequency != item.recurrenceFrequency {
            item.setRecurrenceFrequency(
                recurrenceFrequency: tempRecurrenceFrequency, currentUser: currentUser)
        }
        if tempRecurrenceInterval != item.recurrenceInterval {
            item.setRecurrenceInterval(
                recurrenceInterval: tempRecurrenceInterval, currentUser: currentUser)
        }
        if tempRecurrenceType != item.recurrenceType {
            item.setRecurrenceType(recurrenceType: tempRecurrenceType, currentUser: currentUser)
        }
        if tempIgnoreTimeComponent != item.ignoreTimeComponent {
            item.setIgnoreTimeComponent(
                ignoreTimeComponent: tempIgnoreTimeComponent, currentUser: currentUser)
        }
        if tempIsCompleted != item.isCompleted {
            item.setIsCompleted(isCompleted: tempIsCompleted, currentUser: currentUser)
        }
        if tempPriority != item.priority {
            item.setPriority(priority: tempPriority, currentUser: currentUser)
        }
        if tempCategory != item.category?.name {
            let categoryEntity = categoryService?.fetchOrCreate(named: tempCategory)
            item.setCategory(category: categoryEntity, currentUser: currentUser)
        }
        saveContext()
    }

    private func saveContext() {
        guard let modelContext = modelContext else { return }

        isSaving = true
        do {
            try modelContext.save()

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
        matchingCategories = categoryService.findMatchingCategories(startingWith: tempCategory)
    }

    @MainActor
    func cancel() {
        if isDirty {
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
