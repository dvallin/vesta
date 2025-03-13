import SwiftUI

struct TodoItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: TodoItem

    @State private var isEditingTitle = false
    @State private var isEditingDetails = false

    var body: some View {
        Form {
            Text(item.title)
                .font(.title)
                .bold()
                .onTapGesture {
                    isEditingTitle = true
                }

            Section(
                header: Text(
                    NSLocalizedString("Description", comment: "Description section header"))
            ) {
                Text(item.details)
                    .onTapGesture {
                        isEditingDetails = true
                    }
            }

            DueDateRecurrenceSection(
                dueDate: Binding(
                    get: { item.dueDate },
                    set: { newValue in
                        item.setDueDate(modelContext: modelContext, dueDate: newValue)
                    }
                ),
                recurrenceFrequency: Binding(
                    get: { item.recurrenceFrequency },
                    set: { newValue in
                        item.setRecurrenceFrequency(
                            modelContext: modelContext,
                            recurrenceFrequency: newValue
                        )
                    }
                ),
                recurrenceType: Binding(
                    get: { item.recurrenceType },
                    set: { newValue in
                        item.setRecurrenceType(
                            modelContext: modelContext,
                            recurrenceType: newValue
                        )
                    }
                )
            )

            Section(NSLocalizedString("Actions", comment: "Actions section header")) {
                Button(action: markAsDone) {
                    Label(
                        NSLocalizedString("Mark as Done", comment: "Mark as done button"),
                        systemImage: "checkmark.circle")
                }
                .disabled(item.isCompleted)

                Toggle(
                    NSLocalizedString("Completed", comment: "Completed toggle label"),
                    isOn: Binding(
                        get: { item.isCompleted },
                        set: { newValue in
                            item.setIsCompleted(
                                modelContext: modelContext,
                                isCompleted: newValue
                            )
                        }
                    )
                )
            }
        }
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $isEditingTitle) {
            EditTitleView(
                navigationBarTitle: NSLocalizedString(
                    "Edit Title", comment: "Edit title view header"),
                title: Binding(
                    get: { item.title },
                    set: { newValue in
                        item.setTitle(modelContext: modelContext, title: newValue)
                    }
                ))
        }
        .sheet(isPresented: $isEditingDetails) {
            EditDetailsView(
                navigationBarTitle: NSLocalizedString(
                    "Edit Description", comment: "Edit description view header"),
                details: Binding(
                    get: { item.details },
                    set: { newValue in
                        item.setDetails(
                            modelContext: modelContext, details: newValue)
                    }
                ))
        }
    }

    private func markAsDone() {
        withAnimation {
            item.markAsDone(modelContext: modelContext)
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
