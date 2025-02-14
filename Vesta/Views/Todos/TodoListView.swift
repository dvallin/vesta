import SwiftData
import SwiftUI

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var todoItems: [TodoItem]
    @State private var isPresentingAddTodoItemView = false
    @State private var showToast = false
    @State private var lastMarkedAsDoneItem: TodoItem?

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(todoItems) { item in
                    HStack {
                        Button(action: {
                            markAsDone(item: item)
                        }) {
                            Image(
                                systemName: item.isCompleted
                                    ? "checkmark.circle.fill"
                                    : "checkmark.circle"
                            )
                            .foregroundColor(item.isCompleted ? .gray : .blue)
                            .scaleEffect(item.isCompleted ? 1.2 : 1.0)
                            .animation(.easeInOut, value: item.isCompleted)
                        }
                        .disabled(item.isCompleted)
                        .buttonStyle(BorderlessButtonStyle())

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
                        Spacer()
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
        .toast(
            isPresented: $showToast,
            message: "Todo Item Marked as Done. You can undo this action.",
            duration: 3
        )
    }

    private func markAsDone(item: TodoItem) {
        withAnimation {
            item.markAsDone(modelContext: modelContext)
            lastMarkedAsDoneItem = item
            showToast = true
        }
    }

    private func undoMarkAsDone() {
        guard let item = lastMarkedAsDoneItem else { return }
        withAnimation {
            item.undoLastEvent(modelContext: modelContext)
            lastMarkedAsDoneItem = nil
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
