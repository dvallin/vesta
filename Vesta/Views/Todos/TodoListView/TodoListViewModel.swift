import SwiftData
import SwiftUI

class TodoListViewModel: ObservableObject {
    private var modelContext: ModelContext?

    @Published var currentDay: Date = Date()
    @Published var toastMessages: [ToastMessage] = []

    @Published var searchText: String = ""
    @Published var filterMode: FilterMode = .all
    @Published var showCompletedItems: Bool = false

    @Published var selectedTodoItem: TodoItem? = nil

    @Published var isPresentingAddTodoItemView = false
    @Published var isPresentingTodoEventsView = false
    @Published var isPresentingFilterCriteriaView = false

    init(filterMode: FilterMode = .all, showCompletedItems: Bool = false) {
        self.filterMode = filterMode
        self.showCompletedItems = showCompletedItems
    }

    func configureContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func saveContext() -> Bool {
        do {
            try modelContext!.save()
            return true
        } catch {
            return false
        }
    }

    func refresh() {
        currentDay = Date()
    }

    func markAsDone(_ item: TodoItem, undoAction: @escaping (TodoItem, UUID) -> Void) {
        item.markAsDone()

        if saveContext() {
            NotificationManager.shared.cancelNotification(for: item)

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
        if let lastEvent = item.undoLastEvent() {
            modelContext!.delete(lastEvent)
        }
        if saveContext() {
            if item.dueDate != nil {
                NotificationManager.shared.scheduleNotification(for: item)
            }

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
        showCompletedItems = false
    }

    func rescheduleOverdueTasks(todoItems: [TodoItem]) {
        let today = DateUtils.calendar.startOfDay(for: Date())

        for item in todoItems {
            if item.isOverdue && !item.isCompleted {
                if let dueDate = item.dueDate {
                    let newDueDate = DateUtils.preserveTime(from: dueDate, applying: today)
                    item.setDueDate(dueDate: newDueDate)
                }
            }
        }

        if saveContext() {
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
            let matchesCompleted = showCompletedItems || !item.isCompleted
            guard matchesSearchText && matchesCompleted else { return false }

            switch filterMode {
            case .all:
                return true
            case .today:
                return Calendar.current.isDate(
                    item.dueDate ?? Date.distantPast, inSameDayAs: currentDay)
            case .noDueDate:
                return item.dueDate == nil
            case .overdue:
                return item.isOverdue
            }
        }
    }

    var displayTitle: String {
        switch filterMode {
        case .all:
            return NSLocalizedString("All Tasks", comment: "Filter mode: all tasks")
        case .today:
            return NSLocalizedString("Today's Tasks", comment: "Filter mode: today's tasks")
        case .noDueDate:
            return NSLocalizedString(
                "No Due Date", comment: "Filter mode: tasks without due date")
        case .overdue:
            return NSLocalizedString("Overdue Tasks", comment: "Filter mode: overdue tasks")
        }
    }
}
