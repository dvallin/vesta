import SwiftData
import SwiftUI

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var todoItems: [TodoItem]

    @State private var filterMode: FilterMode = .all
    @State private var showCompletedItems: Bool = false
    @State private var searchText: String = ""

    @State private var isPresentingAddTodoItemView = false
    @State private var isPresentingTodoEventsView = false
    @State private var isPresentingFilterCriteriaView = false

    @State private var toastMessages: [ToastMessage] = []

    @State private var selectedTodoItem: TodoItem?

    init(filterMode: FilterMode = .all, showCompletedItems: Bool = false) {
        _filterMode = State(initialValue: filterMode)
        _showCompletedItems = State(initialValue: showCompletedItems)
    }

    var body: some View {
        NavigationView {
            VStack {
                OverdueTasksBanner(
                    hasOverdueTasks: hasOverdueTasks,
                    filterMode: filterMode,
                    showRescheduleOverdueTasks: showRescheduleOverdueTasks,
                    rescheduleOverdueTasks: rescheduleOverdueTasks
                )

                ZStack {
                    TodoList(
                        todoItems: todoItems,
                        selectedTodoItem: $selectedTodoItem,
                        searchText: $searchText,
                        showCompletedItems: $showCompletedItems,
                        filterMode: $filterMode,
                        markAsDone: markAsDone,
                        deleteTodoItems: deleteTodoItems
                    )

                    FloatingAddButton {
                        isPresentingAddTodoItemView = true
                    }
                }
            }
            .navigationTitle("Todo List")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresentingFilterCriteriaView = true
                    }) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPresentingTodoEventsView = true
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
                ToolbarItem(placement: .principal) {
                    TextField("Search", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 200)
                }
            }
        }
        .sheet(item: $selectedTodoItem) { item in
            TodoItemDetailView(item: item)
        }
        .sheet(isPresented: $isPresentingAddTodoItemView) {
            AddTodoItemView()
        }
        .sheet(isPresented: $isPresentingTodoEventsView) {
            TodoEventsView()
        }
        .sheet(isPresented: $isPresentingFilterCriteriaView) {
            FilterCriteriaView(filterMode: $filterMode, showCompletedItems: $showCompletedItems)
                .presentationDetents([.medium, .large])
        }
        .toast(messages: $toastMessages)
    }

    private var hasOverdueTasks: Bool {
        todoItems.contains { item in
            if let dueDate = item.dueDate {
                return dueDate < Date()
                    && !Calendar.current.isDateInToday(dueDate)
                    && !item.isCompleted
            }
            return false
        }
    }

    private func markAsDone(item: TodoItem) {
        withAnimation {
            item.markAsDone(modelContext: modelContext)
            let id = UUID()
            let toastMessage = ToastMessage(
                id: id,
                message: "\(item.title) marked as done",
                undoAction: {
                    undoMarkAsDone(item: item, id: id)
                }
            )
            toastMessages.append(toastMessage)
        }
    }

    private func undoMarkAsDone(item: TodoItem, id: UUID) {
        withAnimation {
            item.undoLastEvent(modelContext: modelContext)
            toastMessages.removeAll { $0.id == id }
        }
    }

    private func deleteTodoItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(todoItems[index])
            }
        }
    }

    private func showRescheduleOverdueTasks() {
        filterMode = .overdue
        showCompletedItems = false
    }

    private func rescheduleOverdueTasks() {
        let today = Calendar.current.startOfDay(for: Date())

        for item in todoItems {
            if let dueDate = item.dueDate,
                dueDate < Date(),
                !Calendar.current.isDateInToday(dueDate),
                !item.isCompleted
            {
                item.setDueDate(modelContext: modelContext, dueDate: today)
            }
        }

        filterMode = .today
    }
}

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)

        let context = container.mainContext
        let todoItems = [
            TodoItem(
                title: "Buy groceries",
                details: "Milk, Bread, Eggs",
                dueDate: Date().addingTimeInterval(3600),
                recurrenceFrequency: .daily,
                recurrenceType: .fixed
            ),
            TodoItem(
                title: "Call John",
                details: "Discuss the project details",
                dueDate: Date().addingTimeInterval(7200),
                recurrenceFrequency: .weekly,
                recurrenceType: .flexible
            ),
            TodoItem(
                title: "Workout",
                details: "Go for a run",
                dueDate: nil
            ),
        ]

        for item in todoItems {
            context.insert(item)
        }

        return TodoListView()
            .modelContainer(container)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
