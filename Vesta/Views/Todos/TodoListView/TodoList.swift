import SwiftUI

struct TodoList: View {
    var todoItems: [TodoItem]
    @Binding var selectedTodoItem: TodoItem?
    @Binding var searchText: String
    @Binding var showCompletedItems: Bool
    @Binding var filterMode: FilterMode

    var markAsDone: (TodoItem) -> Void
    var deleteTodoItems: (IndexSet) -> Void

    var body: some View {
        List {
            ForEach(filteredTodoItems) { item in
                TodoListItem(
                    item: item,
                    markAsDone: markAsDone,
                    selectItem: { selectedTodoItem = item }
                )
            }
            .onDelete(perform: deleteTodoItems)
        }
    }

    private var filteredTodoItems: [TodoItem] {
        todoItems.filter { item in
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
            todoItems: todoItems,
            selectedTodoItem: .constant(nil),
            searchText: .constant(""),
            showCompletedItems: .constant(true),
            filterMode: .constant(.all),
            markAsDone: { _ in },
            deleteTodoItems: { _ in }
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
            todoItems: todoItems,
            selectedTodoItem: .constant(nil),
            searchText: .constant("Buy"),
            showCompletedItems: .constant(true),
            filterMode: .constant(.all),
            markAsDone: { _ in },
            deleteTodoItems: { _ in }
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
            todoItems: todoItems,
            selectedTodoItem: .constant(nil),
            searchText: .constant(""),
            showCompletedItems: .constant(true),
            filterMode: .constant(.today),
            markAsDone: { _ in },
            deleteTodoItems: { _ in }
        )
    }
}
