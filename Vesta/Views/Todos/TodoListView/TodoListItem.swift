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
            .disabled(item.isCompleted)
            .buttonStyle(BorderlessButtonStyle())

            Button(action: selectItem) {
                VStack(alignment: .leading) {
                    Text(item.title)
                        .font(.headline)
                    if let dueDate = item.dueDate {
                        HStack(alignment: .bottom) {
                            if item.recurrenceType != nil {
                                Image(
                                    systemName: item.recurrenceType == .fixed
                                        ? "repeat"
                                        : "repeat"
                                )
                                .foregroundColor(.secondary)
                            }
                            Text(
                                dueDate,
                                format: Date.FormatStyle(
                                    date: .numeric, time: .shortened)
                            )
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
    }

    private func markAsDone() {
        withAnimation {
            viewModel.markAsDone(item, undoAction: undoMarkAsDone)
        }
    }

    private func undoMarkAsDone(item: TodoItem, id: UUID) {
        withAnimation {
            viewModel.markAsDone(item, id: id)
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
    }
    .listStyle(.plain)
}
