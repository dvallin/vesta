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
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    // Existing delete action
                    Button(role: .destructive) {
                        viewModel.deleteItem(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    // New skip action for recurring todos
                    if item.recurrenceFrequency != nil {
                        Button {
                            // Call skip via TodoListItem's skip() method
                            // This will be handled by TodoListItem, not directly here
                            // (No-op here, skip is handled in TodoListItem)
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
                                    viewModel.searchText = ""
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
                viewModel.deleteItem(filteredTodoItems[index])
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

    return NavigationView {
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

    return NavigationView {
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

    return NavigationView {
        TodoList(
            viewModel: TodoListViewModel(),
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

    return NavigationView {
        TodoList(
            viewModel: viewModel,
            todoItems: todoItems
        )
    }
}
