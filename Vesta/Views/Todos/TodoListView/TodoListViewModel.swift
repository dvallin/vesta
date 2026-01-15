import SwiftData
import SwiftUI

enum FilterMode: String, CaseIterable {
    case all
    case today
    case next3Days
    case noDueDate
    case overdue
    case completed

    var displayName: String {
        switch self {
        case .all:
            return String(localized: "todos.filter-mode.all")
        case .today:
            return String(localized: "todos.filter-mode.today")
        case .next3Days:
            return String(localized: "todos.filter-mode.next-three")
        case .noDueDate:
            return String(localized: "todos.filter-mode.no-due-date")
        case .overdue:
            return String(localized: "todos.filter-mode.overdue")
        case .completed:
            return String(localized: "todos.filter-mode.completed")
        }
    }
}

class TodoListViewModel: ObservableObject {
    private var modelContext: ModelContext?
    private var categoryService: TodoItemCategoryService?
    private var auth: UserAuthService?
    private var syncService: SyncService?

    @Published var currentDay: Date = Date()
    @Published var toastMessages: [ToastMessage] = []

    @Published var filterMode: FilterMode = .today
    @Published var selectedPriority: Int? = nil
    @Published var selectedCategory: TodoItemCategory? = nil
    @Published var showNoCategory: Bool = false
    @Published var searchText: String = ""

    @Published var selectedTodoItem: TodoItem? = nil

    @Published var isPresentingAddTodoItemView = false
    @Published var isPresentingCategoryManagementView = false

    func configureContext(
        _ context: ModelContext, _ auth: UserAuthService,
        _ syncService: SyncService
    ) {
        self.modelContext = context
        self.categoryService = TodoItemCategoryService(modelContext: context)
        self.auth = auth
        self.syncService = syncService
    }

    func fetchCategories() -> [TodoItemCategory] {
        return categoryService?.fetchAllCategories() ?? []
    }

    func saveContext() -> Bool {
        do {
            try modelContext!.save()
            return true
        } catch {
            return false
        }
    }

    func reset() {
        currentDay = Date()
        filterMode = .today
        selectedPriority = nil
        selectedCategory = nil
        showNoCategory = false
        searchText = ""
    }

    func updateCurrentDay() {
        currentDay = Date()
    }

    func markAsDone(_ item: TodoItem, undoAction: @escaping (TodoItem, UUID) -> Void) {
        guard let currentUser = auth?.currentUser else { return }
        item.markAsDone(currentUser: currentUser)

        if saveContext() {
            NotificationManager.shared.scheduleNotification(for: item)

            _ = syncService?.pushLocalChanges()
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)

            let id = UUID()
            let toastMessage = ToastMessage(
                id: id,
                message: String(
                    format: NSLocalizedString(
                        "%@ marked as done", comment: "Toast message for marking todo as done"),
                    item.title
                ),
                undoAction: {
                    undoAction(item, id)
                }
            )
            toastMessages.append(toastMessage)
        }
    }

    func skip(_ item: TodoItem, undoAction: @escaping (TodoItem, UUID) -> Void) {
        guard let currentUser = auth?.currentUser else { return }
        guard item.recurrenceFrequency != nil else { return }
        item.skip(currentUser: currentUser)

        if saveContext() {
            NotificationManager.shared.scheduleNotification(for: item)

            _ = syncService?.pushLocalChanges()
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .warning)

            let id = UUID()
            let toastMessage = ToastMessage(
                id: id,
                message: String(
                    format: NSLocalizedString(
                        "%@ skipped", comment: "Toast message for skipping todo"),
                    item.title
                ),
                undoAction: {
                    undoAction(item, id)
                }
            )
            toastMessages.append(toastMessage)
        }
    }

    func undoLastEvent(_ item: TodoItem, id: UUID) {
        item.undoLastEvent()
        toastMessages.removeAll { $0.id == id }

        if saveContext() {
            NotificationManager.shared.scheduleNotification(for: item)

            _ = syncService?.pushLocalChanges()
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }
    }

    func deleteItem(_ item: TodoItem, undoAction: @escaping (TodoItem, UUID) -> Void) {
        guard let currentUser = auth?.currentUser else { return }
        item.softDelete(currentUser: currentUser)

        if saveContext() {
            NotificationManager.shared.cancelNotification(for: item)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .heavy)

            let id = UUID()
            let toastMessage = ToastMessage(
                id: id,
                message: String(
                    format: NSLocalizedString(
                        "%@ deleted", comment: "Toast message for deleting todo item"),
                    item.title
                ),
                undoAction: {
                    undoAction(item, id)
                }
            )
            toastMessages.append(toastMessage)
        }
    }

    func undoDeleteItem(_ item: TodoItem, id: UUID) {
        guard let currentUser = auth?.currentUser else { return }
        item.restore(currentUser: currentUser)
        toastMessages.removeAll { $0.id == id }

        if saveContext() {
            NotificationManager.shared.scheduleNotification(for: item)
            _ = syncService?.pushLocalChanges()
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }
    }

    func hasRescheduleOverdueTasks(todoItems: [TodoItem]) -> Bool {
        todoItems.contains { item in item.needsReschedule }
    }

    func showRescheduleOverdueTasks() {
        reset()
        filterMode = .overdue
    }

    func rescheduleOverdueTasks(todoItems: [TodoItem]) {
        guard let currentUser = auth?.currentUser else { return }
        let today = DateUtils.calendar.startOfDay(for: Date())

        for item in todoItems {
            if item.isOverdue && !item.isCompleted {
                if let dueDate = item.dueDate {
                    let newDueDate = DateUtils.preserveTime(from: dueDate, applying: today)
                    item.setRescheduleDate(rescheduleDate: newDueDate, currentUser: currentUser)
                }
            }
        }

        if saveContext() {
            _ = syncService?.pushLocalChanges()
            filterMode = .today

            for item in todoItems {
                NotificationManager.shared.scheduleNotification(for: item)
            }

            HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)
        }
    }

    func filterItems(todoItems: [TodoItem]) -> [TodoItem] {
        return todoItems.filter { item in
            let matchesPriority = selectedPriority == nil || item.priority == selectedPriority
            var matchesCategory = true
            if showNoCategory {
                // no category
                matchesCategory = item.category == nil
            } else if selectedCategory != nil {
                // exact category
                matchesCategory = item.category == selectedCategory
            }

            let matchesSearch =
                searchText.isEmpty || item.title.localizedCaseInsensitiveContains(searchText)
                || item.details.localizedCaseInsensitiveContains(searchText)

            guard matchesPriority && matchesCategory && matchesSearch else { return false }

            switch filterMode {
            case .all:
                return !item.isCompleted
            case .today:
                return !item.isCompleted && item.isToday
            case .next3Days:
                return !item.isCompleted && item.isNext3Days
            case .noDueDate:
                return !item.isCompleted && item.dueDate == nil
            case .overdue:
                // this view should not show same day, so just isOverdue does not do it.
                return item.needsReschedule
            case .completed:
                return item.isCompleted
            }
        }
    }

    // MARK: - Filter Override Methods

    /// Sets category and applies left-to-right override: resets filterMode to .all when selecting specific category
    func setCategory(_ category: TodoItemCategory?) {
        selectedCategory = category
        showNoCategory = false

        filterMode = .all
        selectedPriority = nil

        HapticFeedbackManager.shared.generateSelectionFeedback()
    }

    /// Sets showNoCategory and applies override logic
    func setShowNoCategory(_ show: Bool) {
        showNoCategory = show
        selectedCategory = nil
        filterMode = .all
        selectedPriority = nil

        HapticFeedbackManager.shared.generateSelectionFeedback()
    }

    /// Sets showAllCategories and clears category selection
    func setShowAllCategories() {
        showNoCategory = false
        filterMode = .all
        selectedCategory = nil

        HapticFeedbackManager.shared.generateSelectionFeedback()
    }

    /// Sets filter mode - no override, maintains category selection
    func setFilterMode(_ mode: FilterMode) {
        filterMode = mode
        selectedPriority = nil

        HapticFeedbackManager.shared.generateSelectionFeedback()
    }

    /// Sets priority - no override, maintains category and filter mode selection
    func setPriority(_ priority: Int?) {
        selectedPriority = priority

        HapticFeedbackManager.shared.generateSelectionFeedback()
    }

    var hasActiveFilters: Bool {
        filterMode != .today || selectedCategory != nil
            || selectedPriority != nil || searchText != ""
            || showNoCategory
    }
}
