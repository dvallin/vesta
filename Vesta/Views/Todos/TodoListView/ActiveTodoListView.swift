import SwiftData
import SwiftUI

struct ActiveTodoListView: View {
    @ObservedObject var viewModel: TodoListViewModel
    @Query<TodoItem>(
        filter: #Predicate { item in item.isCompleted != true },
        sort: [
            SortDescriptor(\TodoItem.priority, order: .forward),
            SortDescriptor(\TodoItem.dueDate, order: .forward),
            SortDescriptor(\TodoItem.title, order: .forward),
        ]) var todoItems: [TodoItem]

    var body: some View {
        TodoListViewInner(viewModel: viewModel, todoItems: todoItems)
    }
}
