import SwiftUI

struct TodoListItem: View {
    let item: TodoItem
    var markAsDone: (TodoItem) -> Void
    var selectItem: () -> Void

    var body: some View {
        HStack {
            Button(action: {
                markAsDone(item)
            }) {
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
                        Text("No due date")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    List {
        // Regular todo item
        TodoListItem(
            item: TodoItem(
                title: "Buy groceries",
                details: "Milk, Bread, Eggs",
                dueDate: Date().addingTimeInterval(3600)
            ),
            markAsDone: { _ in },
            selectItem: {}
        )

        // Completed todo item
        TodoListItem(
            item: TodoItem(
                title: "Call John",
                details: "Discuss project details",
                dueDate: Date().addingTimeInterval(7200),
                isCompleted: true
            ),
            markAsDone: { _ in },
            selectItem: {}
        )

        // Recurring todo item (fixed)
        TodoListItem(
            item: TodoItem(
                title: "Weekly meeting",
                details: "Team sync-up",
                dueDate: Date().addingTimeInterval(24 * 3600),
                recurrenceFrequency: .weekly,
                recurrenceType: .fixed
            ),
            markAsDone: { _ in },
            selectItem: {}
        )

        // Recurring todo item (flexible)
        TodoListItem(
            item: TodoItem(
                title: "Workout",
                details: "30 minutes exercise",
                dueDate: Date().addingTimeInterval(12 * 3600),
                recurrenceFrequency: .daily,
                recurrenceType: .flexible
            ),
            markAsDone: { _ in },
            selectItem: {}
        )

        // Todo item without due date
        TodoListItem(
            item: TodoItem(
                title: "Read a book",
                details: "Any book will do",
                dueDate: nil
            ),
            markAsDone: { _ in },
            selectItem: {}
        )
    }
    .listStyle(.plain)
}
