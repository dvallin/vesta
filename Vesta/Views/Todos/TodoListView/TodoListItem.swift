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
                .foregroundColor(item.isCompleted ? .secondary : .accentColor)
                .scaleEffect(item.isCompleted ? 1 : 1.5)
                .animation(.easeInOut, value: item.isCompleted)
            }
            .buttonStyle(BorderlessButtonStyle())

            Button(action: selectItem) {
                VStack(alignment: .leading) {
                    Text(item.title)
                        .font(.headline)
                    if let dueDate = item.dueDate {
                        HStack(alignment: .bottom) {
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
                        }
                    } else {
                        Text(
                            NSLocalizedString(
                                "No due date", comment: "Label for items without due date")
                        )
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }
            }
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

#Preview {
    let viewModel = TodoListViewModel()

    List {
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
                recurrenceType: .flexible
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

        // Todo item with ignoreTimeComponent set to true
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Morning run",
                details: "Run 5km",
                dueDate: Date().addingTimeInterval(3600),
                ignoreTimeComponent: true
            )
        )

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

        // Overdue todo item with ignoreTimeComponent set to true
        TodoListItem(
            viewModel: viewModel,
            item: TodoItem(
                title: "Pay bills",
                details: "Pay electricity and water bills",
                dueDate: Date().addingTimeInterval(-3600 * 24),
                ignoreTimeComponent: true
            )
        )
    }
    .listStyle(.plain)
}
