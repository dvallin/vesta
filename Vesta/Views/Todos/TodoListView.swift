import SwiftData
import SwiftUI

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var todoItems: [TodoItem]
    @State private var isPresentingAddTodoItemView = false
    @State private var toastMessages: [ToastMessage] = []

    var body: some View {
        NavigationSplitView {
            ZStack {
                List {
                    ForEach(todoItems) { item in
                        HStack {
                            Button(action: {
                                markAsDone(item: item)
                            }) {
                                Image(
                                    systemName: item.isCompleted
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                )
                                .foregroundColor(item.isCompleted ? .secondary : .blue)
                                .scaleEffect(item.isCompleted ? 1 : 1.5)
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
                            Spacer()
                        }
                    }
                    .onDelete(perform: deleteTodoItems)
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            isPresentingAddTodoItemView = true
                        }) {
                            Image(systemName: "plus")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .shadow(radius: 10)
                        }
                        .padding()
                    }
                }
            }
        } detail: {
            Text("Select a todo item")
        }
        .sheet(isPresented: $isPresentingAddTodoItemView) {
            AddTodoItemView()
        }
        .toast(messages: $toastMessages)
    }

    private func markAsDone(item: TodoItem) {
        withAnimation {
            item.markAsDone(modelContext: modelContext)
            let id = UUID()
            let toastMessage = ToastMessage(
                id: id, message: "\(item.title) marked as done",
                undoAction: {
                    undoMarkAsDone(item: item, id: id)
                })
            toastMessages.append(toastMessage)
        }
    }

    private func undoMarkAsDone(item: TodoItem, id: UUID) {
        withAnimation {
            item.undoLastEvent(modelContext: modelContext)
            toastMessages.removeAll { $0.id == id }
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

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)

        let context = container.mainContext
        let todoItems = [
            TodoItem(
                title: "Buy groceries", details: "Milk, Bread, Eggs",
                dueDate: Date().addingTimeInterval(3600),
                recurrenceFrequency: .daily,
                recurrenceType: .fixed
            ),
            TodoItem(
                title: "Call John", details: "Discuss the project details",
                dueDate: Date().addingTimeInterval(7200),
                recurrenceFrequency: .weekly,
                recurrenceType: .flexible
            ),
            TodoItem(
                title: "Workout", details: "Go for a run", dueDate: nil
            ),
        ]

        for item in todoItems {
            context.insert(item)
        }

        return TodoListView()
            .modelContainer(container)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
