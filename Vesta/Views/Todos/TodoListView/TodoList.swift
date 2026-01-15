import SwiftUI
import os

/// View representing a list of todo items.
struct TodoList: View {
    private let logger = Logger(subsystem: "com.yourapp.Vesta", category: "TodoList")

    @ObservedObject var viewModel: TodoListViewModel

    var todoItems: [TodoItem]

    var body: some View {
        List {
            ForEach(filteredTodoItems) { item in
                TodoListItem(
                    viewModel: viewModel,
                    item: item
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    // Delete action
                    Button(role: .destructive) {
                        deleteTodoItem(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    // Skip action for recurring todos
                    if item.recurrenceFrequency != nil {
                        Button {
                            skipTodoItem(item)
                        } label: {
                            Label("Skip", systemImage: "forward.end")
                        }
                        .tint(.yellow)
                    }
                }
            }
            .onDelete(perform: deleteTodoItems)
        }
        .overlay {
            if filteredTodoItems.isEmpty {
                ContentUnavailableView(
                    label: {
                        Label(
                            NSLocalizedString("No Todo Items", comment: "Empty todo list title"),
                            systemImage: "checklist"
                        )
                    },
                    description: {
                        Text(
                            NSLocalizedString(
                                "No items visible right now.",
                                comment: "Empty todo list description"
                            )
                        )
                    },
                    actions: {
                        HStack {
                            if viewModel.filterMode != .all || viewModel.selectedPriority != nil {
                                Button(
                                    NSLocalizedString("Show All", comment: "Show all todos button")
                                ) {
                                    logger.info("Show All button tapped")
                                    viewModel.filterMode = .all
                                    viewModel.selectedPriority = nil
                                    viewModel.selectedCategory = nil
                                }
                            }
                        }
                    }
                )
            }
        }
        .onAppear {
            logger.info("TodoList appeared with \(todoItems.count) items")
        }
    }

    private var filteredTodoItems: [TodoItem] {
        viewModel.filterItems(todoItems: todoItems)
    }

    private func deleteTodoItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                deleteTodoItem(filteredTodoItems[index])
            }
        }
    }

    private func deleteTodoItem(_ item: TodoItem) {
        withAnimation {
            viewModel.deleteItem(item) { item, id in
                viewModel.undoDeleteItem(item, id: id)
            }
        }
    }

    private func skipTodoItem(_ item: TodoItem) {
        withAnimation {
            viewModel.skip(item) { item, id in
                viewModel.undoLastEvent(item, id: id)
            }
        }
    }
}

// MARK: - Previews
#Preview {
    let todoItems = [
        Fixtures.todoItem(
            title: "Buy groceries",
            details: "Milk, Bread, Eggs",
            dueDate: Date().addingTimeInterval(3600),
            recurrenceFrequency: .daily,
            recurrenceType: .fixed
        ),
        Fixtures.completedTodoItem(
            title: "Call John",
            details: "Discuss the project details",
            dueDate: Date().addingTimeInterval(-3600),
            recurrenceFrequency: .weekly
        ),
        Fixtures.todoItem(
            title: "Workout",
            details: "Go for a run"
        ),
        Fixtures.todayTodoItem(
            title: "Read a book",
            details: "Chapter 1-3"
        ),
    ]

    return NavigationStack {
        TodoList(
            viewModel: TodoListViewModel(),
            todoItems: todoItems
        )
    }
}

#Preview("With Search") {
    let todoItems = [
        Fixtures.todoItem(
            title: "Buy groceries",
            details: "Milk, Bread, Eggs",
            dueDate: Date().addingTimeInterval(3600)
        ),
        Fixtures.todoItem(
            title: "Buy new phone",
            details: "Compare prices",
            dueDate: Date().addingTimeInterval(7200)
        ),
    ]

    return NavigationStack {
        TodoList(
            viewModel: TodoListViewModel(),
            todoItems: todoItems
        )
    }
}

#Preview("Today's Tasks") {
    let todoItems = [
        Fixtures.todayTodoItem(
            title: "Morning workout",
            details: "30 minutes cardio"
        ),
        Fixtures.todayTodoItem(
            title: "Team meeting",
            details: "Sprint planning",
            hoursFromNow: 4
        ),
        Fixtures.upcomingTodoItem(
            title: "Future task",
            details: "Not for today",
            daysFromNow: 2
        ),
    ]

    return NavigationStack {
        TodoList(
            viewModel: TodoListViewModel(),
            todoItems: todoItems
        )
    }
}

#Preview("Empty List") {
    return NavigationStack {
        TodoList(
            viewModel: TodoListViewModel(),
            todoItems: []
        )
    }
}

#Preview("All Filtered") {
    let todoItems = [
        Fixtures.completedTodoItem(
            title: "Completed task",
            details: "This is done",
            dueDate: Date()
        ),
        Fixtures.completedTodoItem(
            title: "Another completed task",
            details: "This is also done",
            dueDate: Date()
        ),
    ]

    let viewModel = TodoListViewModel()

    return NavigationStack {
        TodoList(
            viewModel: viewModel,
            todoItems: todoItems
        )
    }
}
