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
                HStack {
                    if isSearchActive {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))

                            TextField("Search todos...", text: $viewModel.searchText)
                                .focused($isSearchFocused)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.headline)

                            Button("Cancel") {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isSearchActive = false
                                    viewModel.searchText = ""
                                    isSearchFocused = false
                                }
                            }
                            .font(.system(size: 16))
                            .foregroundColor(.accentColor)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        HStack {
                            Text(viewModel.displayTitle)
                                .font(.headline)
                                .fontWeight(.semibold)

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isSearchActive = true
                                    isSearchFocused = true
                                }
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity)
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
