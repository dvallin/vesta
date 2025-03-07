import SwiftData
import SwiftUI

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var todoItems: [TodoItem]

    @StateObject var viewModel: TodoListViewModel

    init(filterMode: FilterMode = .all, showCompletedItems: Bool = false) {
        _viewModel = StateObject(
            wrappedValue: TodoListViewModel(
                filterMode: filterMode, showCompletedItems: showCompletedItems))
    }

    var body: some View {
        NavigationView {
            VStack {
                OverdueTasksBanner(viewModel: viewModel, todoItems: todoItems)

                ZStack {
                    TodoList(
                        viewModel: viewModel,
                        todoItems: todoItems
                    )

                    FloatingAddButton {
                        viewModel.isPresentingAddTodoItemView = true
                    }
                }
            }
            .navigationTitle("Todo List")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.isPresentingFilterCriteriaView = true
                    }) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.isPresentingTodoEventsView = true
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
                ToolbarItem(placement: .principal) {
                    TextField("Search", text: $viewModel.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 200)
                }
            }
        }
        .sheet(item: $viewModel.selectedTodoItem) { item in
            TodoItemDetailView(item: item)
        }
        .sheet(isPresented: $viewModel.isPresentingAddTodoItemView) {
            AddTodoItemView()
        }
        .sheet(isPresented: $viewModel.isPresentingTodoEventsView) {
            TodoEventsView()
        }
        .sheet(isPresented: $viewModel.isPresentingFilterCriteriaView) {
            FilterCriteriaView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
        .toast(messages: $viewModel.toastMessages)
        .onAppear {
            viewModel.configureContext(modelContext)
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
