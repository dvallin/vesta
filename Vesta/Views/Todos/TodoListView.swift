import SwiftData
import SwiftUI

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var todoItems: [TodoItem]

    @StateObject var viewModel: TodoListViewModel

    @State private var searchText: String = ""

    @State private var isPresentingAddTodoItemView = false
    @State private var isPresentingTodoEventsView = false
    @State private var isPresentingFilterCriteriaView = false

    @State private var selectedTodoItem: TodoItem?

    init(filterMode: FilterMode = .all, showCompletedItems: Bool = false) {
        _viewModel = StateObject(
            wrappedValue: TodoListViewModel(
                filterMode: filterMode, showCompletedItems: showCompletedItems))
    }

    var body: some View {
        NavigationView {
            VStack {
                OverdueTasksBanner(viewModel: viewModel)

                ZStack {
                    TodoList(
                        todoItems: todoItems,
                        selectedTodoItem: $selectedTodoItem,
                        searchText: $searchText,
                        showCompletedItems: $viewModel.showCompletedItems,
                        filterMode: $viewModel.filterMode,
                        markAsDone: markAsDone,
                        deleteTodoItems: deleteTodoItems
                    )

                    FloatingAddButton {
                        isPresentingAddTodoItemView = true
                    }
                }
            }
            .navigationTitle("Todo List")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresentingFilterCriteriaView = true
                    }) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPresentingTodoEventsView = true
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
                ToolbarItem(placement: .principal) {
                    TextField("Search", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 200)
                }
            }
        }
        .sheet(item: $selectedTodoItem) { item in
            TodoItemDetailView(item: item)
        }
        .sheet(isPresented: $isPresentingAddTodoItemView) {
            AddTodoItemView()
        }
        .sheet(isPresented: $isPresentingTodoEventsView) {
            TodoEventsView()
        }
        .sheet(isPresented: $isPresentingFilterCriteriaView) {
            FilterCriteriaView(
                filterMode: $viewModel.filterMode, showCompletedItems: $viewModel.showCompletedItems
            )
            .presentationDetents([.medium, .large])
        }
        .toast(messages: $viewModel.toastMessages)
        .onAppear {
            viewModel.configureContext(modelContext)
            viewModel.todoItems = todoItems
        }
    }

    private func markAsDone(item: TodoItem) {
        withAnimation {
            viewModel.markAsDone(item, undoAction: undoMarkAsDone)
        }
    }

    private func undoMarkAsDone(item: TodoItem, id: UUID) {
        withAnimation {
            viewModel.markAsDone(item, id: id)
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
                title: "Buy groceries",
                details: "Milk, Bread, Eggs",
                dueDate: Date().addingTimeInterval(3600),
                recurrenceFrequency: .daily,
                recurrenceType: .fixed
            ),
            TodoItem(
                title: "Call John",
                details: "Discuss the project details",
                dueDate: Date().addingTimeInterval(7200),
                recurrenceFrequency: .weekly,
                recurrenceType: .flexible
            ),
            TodoItem(
                title: "Workout",
                details: "Go for a run",
                dueDate: nil
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
