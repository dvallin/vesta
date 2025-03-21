import SwiftData
import SwiftUI

class TodoItemDetailViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private var dismiss: DismissAction?

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

    func configureEnvironment(_ context: ModelContext, _ dismiss: DismissAction) {
        self.modelContext = context
        self.dismiss = dismiss
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
        withAnimation {
            item.markAsDone()
            saveContext()
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)
        }
    }

    func save() {
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
            item.setTitle(title: tempTitle)
        }
        if tempDetails != item.details {
            item.setDetails(details: tempDetails)
        }
        if tempDueDate != item.dueDate {
            item.setDueDate(dueDate: tempDueDate)
        }
        if tempRecurrenceFrequency != item.recurrenceFrequency {
            item.setRecurrenceFrequency(recurrenceFrequency: tempRecurrenceFrequency)
        }
        if tempRecurrenceInterval != item.recurrenceInterval {
            item.setRecurrenceInterval(recurrenceInterval: tempRecurrenceInterval)
        }
        if tempRecurrenceType != item.recurrenceType {
            item.setRecurrenceType(recurrenceType: tempRecurrenceType)
        }
        if tempIgnoreTimeComponent != item.ignoreTimeComponent {
            item.setIgnoreTimeComponent(ignoreTimeComponent: tempIgnoreTimeComponent)
        }
        if tempIsCompleted != item.isCompleted {
            item.setIsCompleted(isCompleted: tempIsCompleted)
        }
        if tempPriority != item.priority {
            item.setPriority(priority: tempPriority)
        }
        if tempCategory != item.category?.name {
            let categoryEntity = fetchOrCreateCategory(named: tempCategory)
            item.setCategory(category: categoryEntity)
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

    private func fetchOrCreateCategory(named name: String) -> TodoItemCategory? {
        guard !name.isEmpty, let context = modelContext else { return nil }

        // Replace the deprecated FetchRequest with a FetchDescriptor
        let fetchDescriptor = FetchDescriptor<TodoItemCategory>(
            predicate: #Predicate { item in item.name == name },
            sortBy: []
        )

        if let existingCategory = try? context.fetch(fetchDescriptor).first {
            return existingCategory
        } else {
            let newCategory = TodoItemCategory(name: name)
            context.insert(newCategory)
            return newCategory
        }
    }

    func updateMatchingCategories() {
        guard let context = modelContext else { return }

        // Create a FetchDescriptor for categories that begin with the current text
        let fetchDescriptor = FetchDescriptor<TodoItemCategory>(
            predicate: #Predicate { item in
                item.name.starts(with: tempCategory)
            },
            sortBy: []
        )

        if let categories = try? context.fetch(fetchDescriptor) {
            matchingCategories = categories
        }
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
