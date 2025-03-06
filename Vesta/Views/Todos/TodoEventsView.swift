import SwiftData
import SwiftUI

struct GroupedTodoItemEvent: Identifiable {
    var id: UUID { UUID() }
    var todoItem: TodoItem?
    var events: [TodoItemEvent]
}

struct TodoEventsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var todoItemEvents: [TodoItemEvent]

    var body: some View {
        NavigationView {
            List {
                ForEach(groupedEvents(), id: \.id) { groupedEvent in
                    Section(
                        header: Text(
                            "\(groupedEvent.todoItem?.title ?? "Unknown Item") - \(groupedEvent.events.first?.date ?? Date(), style: .date)"
                        )
                    ) {
                        if let todoItem = groupedEvent.todoItem {
                            NavigationLink(destination: TodoItemDetailView(item: todoItem)) {
                                VStack(alignment: .leading) {
                                    ForEach(groupedEvent.events) { event in
                                        Text(event.type.rawValue)
                                            .font(.headline)
                                    }
                                }
                            }
                        } else {
                            ForEach(groupedEvent.events) { event in
                                VStack(alignment: .leading) {
                                    Text(event.type.rawValue)
                                        .font(.headline)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Todo Events")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func groupedEvents() -> [GroupedTodoItemEvent] {
        var groupedEvents: [GroupedTodoItemEvent] = []
        var currentGroup: GroupedTodoItemEvent?

        for event in todoItemEvents.sorted(by: { $0.date > $1.date }) {
            if currentGroup?.todoItem != event.todoItem {
                if let currentGroup = currentGroup {
                    groupedEvents.append(currentGroup)
                }
                currentGroup = GroupedTodoItemEvent(todoItem: event.todoItem, events: [])
            }
            currentGroup?.events.append(event)
        }

        if let currentGroup = currentGroup {
            groupedEvents.append(currentGroup)
        }

        return groupedEvents
    }
}

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext

        // Create sample todo items
        let todoItem1 = TodoItem(
            title: "Buy groceries",
            details: "Milk, Bread, Eggs",
            dueDate: Date().addingTimeInterval(3600)
        )

        let todoItem2 = TodoItem(
            title: "Call John",
            details: "Discuss project details",
            dueDate: Date().addingTimeInterval(7200)
        )

        // Insert todo items
        context.insert(todoItem1)
        context.insert(todoItem2)

        // Create sample events for todoItem1
        todoItem1.markAsDone(modelContext: context)
        todoItem1.setTitle(modelContext: context, title: "Buy groceries and supplies")
        todoItem1.setDetails(modelContext: context, details: "Milk, Bread, Eggs, and Paper towels")

        // Create sample events for todoItem2
        todoItem2.setDueDate(modelContext: context, dueDate: Date().addingTimeInterval(14400))
        todoItem2.markAsDone(modelContext: context)

        return TodoEventsView()
            .modelContainer(container)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
