import SwiftData
import SwiftUI

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\TodoItem.dueDate, order: .forward),
        SortDescriptor(\TodoItem.title, order: .forward),
    ]) var todoItems: [TodoItem]

    @StateObject var viewModel: TodoListViewModel

    init(filterMode: FilterMode = .all, showCompletedItems: Bool = false) {
        _viewModel = StateObject(
            wrappedValue: TodoListViewModel(
                filterMode: filterMode, showCompletedItems: showCompletedItems))
    }

    var body: some View {
        NavigationView {
            VStack {
                RescheduleOverdueTaskBanner(viewModel: viewModel, todoItems: todoItems)

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
            .navigationTitle(viewModel.displayTitle)
            .toolbar {
                #if os(iOS)
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
                #endif
                ToolbarItem(placement: .principal) {
                    TextField(
                        NSLocalizedString("Search", comment: "Search text field placeholder"),
                        text: $viewModel.searchText
                    )
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

        // Sample items with different dates and titles
        let todoItems = [
            TodoItem(title: "Z Task", details: "Details", dueDate: nil),
            TodoItem(title: "A Task", details: "Details", dueDate: Date().addingTimeInterval(3600)),
            TodoItem(title: "B Task", details: "Details", dueDate: Date().addingTimeInterval(3600)),
            TodoItem(title: "C Task", details: "Details", dueDate: nil),
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
