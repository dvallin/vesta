import SwiftData
import SwiftUI

struct TodoListViewInner: View {
    @ObservedObject var viewModel: TodoListViewModel
    var todoItems: [TodoItem]

    var body: some View {
        VStack {
            QuickFilterView(viewModel: viewModel)
                .padding(.vertical, 8)

            RescheduleOverdueTaskBanner(viewModel: viewModel, todoItems: todoItems)

            ZStack {
                TodoList(
                    viewModel: viewModel,
                    todoItems: todoItems
                )

                FloatingAddButton {
                    viewModel.isPresentingAddTodoItemView = true
                    HapticFeedbackManager.shared.generateImpactFeedback(style: .light)
                }
            }
        }
        .navigationTitle(viewModel.displayTitle)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
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
}
