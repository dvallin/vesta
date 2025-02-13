import SwiftData
import SwiftUI

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var todoItems: [TodoItem]
    @State private var isPresentingAddTodoItemView = false

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(todoItems) { item in
                    NavigationLink {
                        TodoItemDetailView(item: item)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(.headline)
                            if let dueDate = item.dueDate {
                                Text(
                                    dueDate,
                                    format: Date.FormatStyle(date: .numeric, time: .shortened)
                                )
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            } else {
                                Text("No due date")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteTodoItems)
            }
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            isPresentingAddTodoItemView = true
                        }) {
                            Label("Add Todo Item", systemImage: "plus")
                        }
                    }
                #endif
            }
        } detail: {
            Text("Select a todo item")
        }
        .sheet(isPresented: $isPresentingAddTodoItemView) {
            AddTodoItemView()
        }
    }

    private func deleteTodoItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(todoItems[index])
            }
        }
    }
}
