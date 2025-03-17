import SwiftData
import SwiftUI

class TodoItemDetailViewModel: ObservableObject {
    private var modelContext: ModelContext?
    @Published var item: TodoItem

    @Published var isEditingTitle = false
    @Published var isEditingDetails = false

    init(item: TodoItem) {
        self.item = item
    }

    func configureContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func markAsDone() {
        withAnimation {
            item.markAsDone()
            saveContext()
        }
    }

    func setTitle(title: String) {
        item.setTitle(title: title)
        saveContext()
    }

    func setDetails(details: String) {
        item.setDetails(details: details)
        saveContext()
    }

    func setDueDate(dueDate: Date?) {
        item.setDueDate(dueDate: dueDate)
        saveContext()
    }

    func setIsCompleted(isCompleted: Bool) {
        item.setIsCompleted(isCompleted: isCompleted)
        saveContext()
    }

    func setRecurrenceFrequency(recurrenceFrequency: RecurrenceFrequency?) {
        item.setRecurrenceFrequency(recurrenceFrequency: recurrenceFrequency)
        saveContext()
    }

    func setRecurrenceInterval(recurrenceInterval: Int?) {
        item.setRecurrenceInterval(recurrenceInterval: recurrenceInterval)
        saveContext()
    }

    func setRecurrenceType(recurrenceType: RecurrenceType?) {
        item.setRecurrenceType(recurrenceType: recurrenceType)
        saveContext()
    }

    func setIgnoreTimeComponent(ignoreTimeComponent: Bool) {
        item.setIgnoreTimeComponent(ignoreTimeComponent: ignoreTimeComponent)
        saveContext()
    }

    private func saveContext() {
        guard let modelContext = modelContext else { return }
        do {
            try modelContext.save()
        } catch {
            // Handle error appropriately
            print("Failed to save context: \(error)")
        }
    }
}
