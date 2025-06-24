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
            return NSLocalizedString("Show All", comment: "Filter mode: show all items")
        case .next3Days:
            return NSLocalizedString("Next 3 Days", comment: "Filter mode: show next 3 days items")
        case .today:
            return NSLocalizedString("Only Today", comment: "Filter mode: show only today's items")
        case .noDueDate:
            return NSLocalizedString(
                "No Due Date", comment: "Filter mode: show items with no due date")
        case .overdue:
            return NSLocalizedString("Overdue", comment: "Filter mode: show overdue items")
        case .completed:
            return NSLocalizedString("Completed", comment: "Filter mode: completed items")
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

    @Published var searchText: String = ""
    @Published var filterMode: FilterMode = .today
    @Published var selectedPriority: Int? = nil
    @Published var selectedCategory: TodoItemCategory? = nil
    @Published var showNoCategory: Bool = false

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
        searchText = ""
        selectedPriority = nil
        selectedCategory = nil
    }

    func updateCurrentDay() {
        currentDay = Date()
    }

    func markAsDone(_ item: TodoItem, undoAction: @escaping (TodoItem, UUID) -> Void) {
        guard let currentUser = auth?.currentUser else { return }
        item.markAsDone(currentUser: currentUser)

        if saveContext() {
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

    func undoMarkAsDone(_ item: TodoItem, id: UUID) {
        guard let currentUser = auth?.currentUser else { return }
        item.setIsCompleted(isCompleted: false, currentUser: currentUser)

        if saveContext() {
            _ = syncService?.pushLocalChanges()
            NotificationManager.shared.scheduleNotification(for: item)

            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)

            toastMessages.removeAll { $0.id == id }
        }
    }

    func deleteItem(_ item: TodoItem) {
        NotificationManager.shared.cancelNotification(for: item)

        if saveContext() {

            if item.meal != nil {
                modelContext!.delete(item.meal!)
            } else if item.shoppingListItem != nil {
                modelContext!.delete(item.shoppingListItem!)
            } else {
                modelContext!.delete(item)
            }
            HapticFeedbackManager.shared.generateImpactFeedback(style: .heavy)
        }
    }

    func hasRescheduleOverdueTasks(todoItems: [TodoItem]) -> Bool {
        todoItems.contains { item in item.needsReschedule }
    }

    func showRescheduleOverdueTasks() {
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

            HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)
        }
    }

    func filterItems(todoItems: [TodoItem]) -> [TodoItem] {
        return todoItems.filter { item in
            let matchesSearchText =
                searchText.isEmpty
                || item.title.localizedCaseInsensitiveContains(searchText)
                || item.details.localizedCaseInsensitiveContains(searchText)
            let matchesPriority = selectedPriority == nil || item.priority == selectedPriority
            var matchesCategory = true
            if showNoCategory {
                // no category
                matchesCategory = item.category == nil
            } else if selectedCategory != nil {
                // exact category
                matchesCategory = item.category == selectedCategory
            }
            guard matchesSearchText && matchesPriority && matchesCategory else { return false }

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
                return item.isOverdue
            case .completed:
                return item.isCompleted
            }
        }
    }

    var displayTitle: String {
        switch filterMode {
        case .all:
            return NSLocalizedString("All Tasks", comment: "Filter mode: all tasks")
        case .today:
            return NSLocalizedString("Today's Tasks", comment: "Filter mode: today's tasks")
        case .next3Days:
            return NSLocalizedString("Next 3 Days Tasks", comment: "Filter mode: next 3 days tasks")
        case .noDueDate:
            return NSLocalizedString(
                "No Due Date", comment: "Filter mode: tasks without due date")
        case .overdue:
            return NSLocalizedString("Overdue Tasks", comment: "Filter mode: overdue tasks")
        case .completed:
            return NSLocalizedString("Completed Tasks", comment: "Filter mode: completed tasks")
        }
    }
}
