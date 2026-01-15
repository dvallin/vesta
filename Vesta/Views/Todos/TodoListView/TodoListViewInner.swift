import SwiftData
import SwiftUI

struct TodoListViewInner: View {
    @ObservedObject var viewModel: TodoListViewModel
    var todoItems: [TodoItem]
    @State private var isSearchActive = false
    @FocusState private var isSearchFocused: Bool

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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                SearchableNavigationBar(
                    title: viewModel.filterMode.displayName,
                    searchText: $viewModel.searchText,
                    isSearchActive: $isSearchActive,
                    isSearchFocused: $isSearchFocused,
                    searchPlaceholder: "Search todos..."
                )
            }

            if viewModel.filterMode != .completed && !isSearchActive {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.isPresentingCategoryManagementView = true
                    }) {
                        Label("Manage Categories", systemImage: "folder")
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $viewModel.isPresentingCategoryManagementView) {
            CategoryManagementView()
        }
    }
}
