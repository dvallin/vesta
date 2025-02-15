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
