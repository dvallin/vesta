import SwiftData
import SwiftUI

class TodoListViewModel: ObservableObject {
    private var modelContext: ModelContext?

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

    func saveContext() {
        do {
            try modelContext!.save()
        } catch {
            // handle error
        }
    }

    func markAsDone(_ item: TodoItem, undoAction: @escaping (TodoItem, UUID) -> Void) {
        item.markAsDone(modelContext: modelContext!)
        saveContext()

        let id = UUID()
        let toastMessage = ToastMessage(
            id: id,
            message: "\(item.title) marked as done",
            undoAction: {
                undoAction(item, id)
            }
        )
        toastMessages.append(toastMessage)
    }

    func markAsDone(_ item: TodoItem, id: UUID) {
        item.undoLastEvent(modelContext: modelContext!)
        saveContext()

        toastMessages.removeAll { $0.id == id }
    }

    func deleteItem(_ item: TodoItem) {
        modelContext!.delete(item)
        saveContext()
    }

    func hasOverdueTasks(todoItems: [TodoItem]) -> Bool {
        todoItems.contains { item in
            if let dueDate = item.dueDate {
                return dueDate < Date()
                    && !Calendar.current.isDateInToday(dueDate)
                    && !item.isCompleted
            }
            return false
        }
    }

    func showRescheduleOverdueTasks() {
        filterMode = .overdue
        showCompletedItems = false
    }

    func rescheduleOverdueTasks(todoItems: [TodoItem]) {
        let today = Calendar.current.startOfDay(for: Date())

        for item in todoItems {
            if let dueDate = item.dueDate,
                dueDate < Date(),
                !Calendar.current.isDateInToday(dueDate),
                !item.isCompleted
            {
                item.setDueDate(modelContext: modelContext!, dueDate: today)
            }
        }
        saveContext()

        filterMode = .today
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
                return Calendar.current.isDateInToday(item.dueDate ?? Date.distantPast)
            case .noDueDate:
                return item.dueDate == nil
            case .overdue:
                if let dueDate = item.dueDate {
                    return dueDate < Date() && !Calendar.current.isDateInToday(dueDate)
                }
                return false
            }
        }
    }
}
