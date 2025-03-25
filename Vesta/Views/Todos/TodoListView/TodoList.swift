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
                viewModel.deleteItem(todoItems[index])
            }
        }
    }
}

// MARK: - Previews

#Preview {
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
            dueDate: Date().addingTimeInterval(-3600),  // Overdue task
            isCompleted: true,
            recurrenceFrequency: .weekly,
            recurrenceType: .flexible
        ),
        TodoItem(
            title: "Workout",
            details: "Go for a run",
            dueDate: nil
        ),
        TodoItem(
            title: "Read a book",
            details: "Chapter 1-3",
            dueDate: Calendar.current.startOfDay(for: Date()),  // Today's task
            isCompleted: false
        ),
    ]

    return NavigationView {
        TodoList(
            viewModel: TodoListViewModel(),
            todoItems: todoItems
        )
    }
}

#Preview("With Search") {
    let todoItems = [
        TodoItem(
            title: "Buy groceries",
            details: "Milk, Bread, Eggs",
            dueDate: Date().addingTimeInterval(3600)
        ),
        TodoItem(
            title: "Buy new phone",
            details: "Compare prices",
            dueDate: Date().addingTimeInterval(7200)
        ),
    ]

    return NavigationView {
        TodoList(
            viewModel: TodoListViewModel(),
            todoItems: todoItems
        )
    }
}

#Preview("Today's Tasks") {
    let todoItems = [
        TodoItem(
            title: "Morning workout",
            details: "30 minutes cardio",
            dueDate: Calendar.current.startOfDay(for: Date())
        ),
        TodoItem(
            title: "Team meeting",
            details: "Sprint planning",
            dueDate: Calendar.current.startOfDay(for: Date()).addingTimeInterval(3600 * 4)
        ),
        TodoItem(
            title: "Future task",
            details: "Not for today",
            dueDate: Date().addingTimeInterval(3600 * 24 * 2)
        ),
    ]

    return NavigationView {
        TodoList(
            viewModel: TodoListViewModel(filterMode: .today),
            todoItems: todoItems
        )
    }
}

#Preview("Empty List") {
    return NavigationView {
        TodoList(
            viewModel: TodoListViewModel(),
            todoItems: []
        )
    }
}

#Preview("All Filtered") {
    let todoItems = [
        TodoItem(
            title: "Completed task",
            details: "This is done",
            dueDate: Date(),
            isCompleted: true
        ),
        TodoItem(
            title: "Another completed task",
            details: "This is also done",
            dueDate: Date(),
            isCompleted: true
        ),
    ]

    let viewModel = TodoListViewModel()

    return NavigationView {
        TodoList(
            viewModel: viewModel,
            todoItems: todoItems
        )
    }
}
