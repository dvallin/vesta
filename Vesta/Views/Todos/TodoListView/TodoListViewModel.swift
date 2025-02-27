import SwiftData
import SwiftUI

class TodoListViewModel: ObservableObject {
    private var modelContext: ModelContext?

    @Published var toastMessages: [ToastMessage] = []
    @Published var filterMode: FilterMode = .all
    @Published var showCompletedItems: Bool = false
    @Published var todoItems: [TodoItem] = []

    init(filterMode: FilterMode = .all, showCompletedItems: Bool = false) {
        self.filterMode = filterMode
        self.showCompletedItems = showCompletedItems
    }

    func configureContext(_ context: ModelContext) {
        self.modelContext = context
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

    func saveContext() {
        do {
            try modelContext!.save()
        } catch {
            // handle error
        }
    }

    var hasOverdueTasks: Bool {
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

    func rescheduleOverdueTasks() {
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

        filterMode = .today
    }
}
