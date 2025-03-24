import SwiftUI

struct TodoListItem: View {
    @ObservedObject var viewModel: TodoListViewModel

    var item: TodoItem

    var body: some View {
        HStack {
            Button(action: markAsDone) {
                Image(
                    systemName: item.isCompleted
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .foregroundColor(
                    item.isCompleted ? .gray : priorityColor(priority: item.priority)
                )
                .scaleEffect(item.isCompleted ? 1 : 1.5)
                .animation(.easeInOut, value: item.isCompleted)
            }
            .buttonStyle(BorderlessButtonStyle())

            Button(action: selectItem) {
                VStack(alignment: .leading) {
                    Text(item.title)
                        .font(.headline)
                    HStack(alignment: .bottom) {
                        if let dueDate = item.dueDate {
                            if item.recurrenceFrequency != nil {
                                Image(
                                    systemName: item.recurrenceType == .fixed
                                        ? "repeat"
                                        : "repeat"
                                )
                                .foregroundColor(.secondary)
                            }
                            Text(
                                dueDate,
                                format: item.ignoreTimeComponent
                                    ? Date.FormatStyle(date: .numeric, time: .omitted)
                                    : Date.FormatStyle(date: .numeric, time: .shortened)
                            )
                            .font(.subheadline)
                            .foregroundColor(item.isOverdue ? .red : .secondary)
                        } else {
                            Text(
                                NSLocalizedString(
                                    "No due date", comment: "Label for items without due date")
                            )
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        Spacer()
                        if let category = item.category {
                            Text(category.name)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .cornerRadius(5)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }

    private func priorityColor(priority: Int) -> Color {
        switch priority {
        case 1:  // Most urgent
            return .red
        case 2:  // Warning level
            return .orange
        case 3:  // Highlighted
            return .blue
        default:  // Default priority (4)
            return .gray
        }
    }
    private func selectItem() {
        viewModel.selectedTodoItem = item
        HapticFeedbackManager.shared.generateSelectionFeedback()
    }

    private func markAsDone() {
        withAnimation {
            viewModel.markAsDone(item, undoAction: undoMarkAsDone)
        }
    }

    private func undoMarkAsDone(item: TodoItem, id: UUID) {
        withAnimation {
            viewModel.undoMarkAsDone(item, id: id)
        }
    }
}

#Preview("Basic Items") {
    let viewModel = TodoListViewModel()

    return List {
        // Regular todo item
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Buy groceries",
                details: "Milk, Bread, Eggs",
                dueDate: Date().addingTimeInterval(3600)
            )
        )

        // Completed todo item
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Call John",
                details: "Discuss project details",
                dueDate: Date().addingTimeInterval(7200),
                isCompleted: true
            )
        )

        // Todo item without due date
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Read a book",
                details: "Any book will do",
                dueDate: nil
            )
        )
    }
    .listStyle(.plain)
}

#Preview("Priority Levels") {
    let viewModel = TodoListViewModel()

    return List {
        // Regular todo item
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Buy groceries",
                details: "Milk, Bread, Eggs",
                dueDate: Date().addingTimeInterval(3600)
            )
        )

        // Priority 1 (Urgent)
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Urgent Meeting",
                details: "Emergency team sync",
                dueDate: Date().addingTimeInterval(3600),
                priority: 1
            )
        )

        // Priority 2 (Warning)
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Submit Report",
                details: "Deadline approaching",
                dueDate: Date().addingTimeInterval(7200),
                priority: 2
            )
        )

        // Priority 3 (Highlighted)
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Review Code",
                details: "Review pull request",
                dueDate: Date().addingTimeInterval(24 * 3600),
                priority: 3
            )
        )

        // Priority 4 (Default)
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Read Documentation",
                details: "Review new features",
                dueDate: Date().addingTimeInterval(48 * 3600),
                priority: 4
            )
        )
    }
    .listStyle(.plain)
}

#Preview("Recurring Items") {
    let viewModel = TodoListViewModel()

    return List {
        // Regular todo item
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Buy groceries",
                details: "Milk, Bread, Eggs",
                dueDate: Date().addingTimeInterval(3600)
            )
        )

        // Recurring todo item (fixed)
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Weekly meeting",
                details: "Team sync-up",
                dueDate: Date().addingTimeInterval(24 * 3600),
                recurrenceFrequency: .weekly,
                recurrenceType: .fixed
            )
        )

        // Recurring todo item (flexible)
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Workout",
                details: "30 minutes exercise",
                dueDate: Date().addingTimeInterval(12 * 3600),
                recurrenceFrequency: .daily,
                recurrenceType: .flexible,
                ignoreTimeComponent: false
            )
        )
    }
    .listStyle(.plain)
}

#Preview("Categories") {
    let viewModel = TodoListViewModel()

    return List {
        // Regular todo item
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Buy groceries",
                details: "Milk, Bread, Eggs",
                dueDate: Date().addingTimeInterval(3600)
            )
        )

        // Work category
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Quarterly Review",
                details: "Prepare presentation",
                category: TodoItemCategory(name: "Work")
            )
        )

        // Personal category
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Dentist Appointment",
                details: "Annual checkup",
                dueDate: Date().addingTimeInterval(48 * 3600),
                category: TodoItemCategory(name: "Personal")
            )
        )

        // Shopping category with high priority
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Buy Birthday Gift",
                details: "For Mom's birthday",
                dueDate: Date().addingTimeInterval(24 * 3600),
                ignoreTimeComponent: false,
                priority: 2,
                category: TodoItemCategory(name: "Shopping")
            )
        )

        // Health category with recurrence
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Take Vitamins",
                details: "Daily supplements",
                dueDate: Date().addingTimeInterval(12 * 3600),
                recurrenceFrequency: .daily,
                recurrenceType: .flexible,
                category: TodoItemCategory(name: "Health")
            )
        )
    }
    .listStyle(.plain)
}

#Preview("Special Cases") {
    let viewModel = TodoListViewModel()

    return List {
        // Overdue todo item
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Submit report",
                details: "Submit the quarterly report",
                dueDate: Date().addingTimeInterval(-3600),
                ignoreTimeComponent: false
            )
        )

        // Overdue todo item with ignoreTimeComponent
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Pay bills",
                details: "Pay electricity and water bills",
                dueDate: Date().addingTimeInterval(-3600 * 24),
                ignoreTimeComponent: true
            )
        )

        // Todo item with ignoreTimeComponent
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Morning run",
                details: "Run 5km",
                dueDate: Date().addingTimeInterval(3600),
                ignoreTimeComponent: true
            )
        )
    }
    .listStyle(.plain)
}
