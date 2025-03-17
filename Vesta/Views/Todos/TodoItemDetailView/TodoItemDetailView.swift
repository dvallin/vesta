import SwiftUI

struct TodoItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: TodoItemDetailViewModel

    init(item: TodoItem) {
        _viewModel = StateObject(wrappedValue: TodoItemDetailViewModel(item: item))
    }

    var body: some View {
        Form {
            Text(viewModel.item.title)
                .font(.title)
                .bold()
                .onTapGesture {
                    viewModel.isEditingTitle = true
                }

            Section(
                header: Text(
                    NSLocalizedString("Description", comment: "Description section header"))
            ) {
                Text(viewModel.item.details)
                    .onTapGesture {
                        viewModel.isEditingDetails = true
                    }
            }

            DueDateRecurrenceSection(
                dueDate: Binding(
                    get: { viewModel.item.dueDate },
                    set: { viewModel.setDueDate(dueDate: $0) }
                ),
                recurrenceFrequency: Binding(
                    get: { viewModel.item.recurrenceFrequency },
                    set: { viewModel.setRecurrenceFrequency(recurrenceFrequency: $0) }
                ),
                recurrenceInterval: Binding(
                    get: { viewModel.item.recurrenceInterval },
                    set: { viewModel.setRecurrenceInterval(recurrenceInterval: $0) }
                ),
                recurrenceType: Binding(
                    get: { viewModel.item.recurrenceType },
                    set: { viewModel.setRecurrenceType(recurrenceType: $0) }
                ),
                ignoreTimeComponent: Binding(
                    get: { viewModel.item.ignoreTimeComponent },
                    set: { viewModel.setIgnoreTimeComponent(ignoreTimeComponent: $0) }
                )
            )

            Section(NSLocalizedString("Actions", comment: "Actions section header")) {
                Button(action: { viewModel.markAsDone() }) {
                    Label(
                        NSLocalizedString("Mark as Done", comment: "Mark as done button"),
                        systemImage: "checkmark.circle")
                }
                .disabled(viewModel.item.isCompleted)

                Toggle(
                    NSLocalizedString("Completed", comment: "Completed toggle label"),
                    isOn: Binding(
                        get: { viewModel.item.isCompleted },
                        set: { viewModel.setIsCompleted(isCompleted: $0) }
                    )
                )
            }
        }
        .onAppear {
            viewModel.configureContext(modelContext)
        }
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $viewModel.isEditingTitle) {
            EditTitleView(
                navigationBarTitle: NSLocalizedString(
                    "Edit Title", comment: "Edit title view header"),
                title: Binding(
                    get: { viewModel.item.title },
                    set: { viewModel.setTitle(title: $0) }
                ))
        }
        .sheet(isPresented: $viewModel.isEditingDetails) {
            EditDetailsView(
                navigationBarTitle: NSLocalizedString(
                    "Edit Description", comment: "Edit description view header"),
                details: Binding(
                    get: { viewModel.item.details },
                    set: { viewModel.setDetails(details: $0) }
                ))
        }
    }
}

#Preview {
    NavigationStack {
        // Regular todo item
        TodoItemDetailView(
            item: TodoItem(
                title: "Buy groceries",
                details: "Milk, Bread, Eggs, Fresh vegetables, and fruits for the week",
                dueDate: Date().addingTimeInterval(3600)
            )
        )
    }
    .modelContainer(for: TodoItem.self)
}

#Preview("With Recurrence") {
    NavigationStack {
        // Recurring todo item
        TodoItemDetailView(
            item: TodoItem(
                title: "Weekly Team Meeting",
                details:
                    "Discuss project progress and upcoming milestones with the development team",
                dueDate: Date().addingTimeInterval(24 * 3600),
                recurrenceFrequency: .weekly,
                recurrenceType: .fixed
            )
        )
    }
    .modelContainer(for: TodoItem.self)
}

#Preview("Completed") {
    NavigationStack {
        // Completed todo item
        TodoItemDetailView(
            item: TodoItem(
                title: "Send Project Proposal",
                details: "Final review and submission of the Q4 project proposal",
                dueDate: Date().addingTimeInterval(-24 * 3600),
                isCompleted: true
            )
        )
    }
    .modelContainer(for: TodoItem.self)
}

#Preview("No Due Date") {
    NavigationStack {
        // Todo item without due date
        TodoItemDetailView(
            item: TodoItem(
                title: "Read Design Patterns Book",
                details: "Study and take notes on the Gang of Four design patterns",
                dueDate: nil
            )
        )
    }
    .modelContainer(for: TodoItem.self)
}
