import SwiftData
import SwiftUI

struct TodoListView: View {
    @EnvironmentObject private var auth: UserAuthService
    @EnvironmentObject private var syncService: SyncService
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    @StateObject var viewModel = TodoListViewModel()

    var body: some View {
        NavigationView {
            if viewModel.filterMode == .completed {
                CompletedTodoListView(viewModel: viewModel)
            } else {
                ActiveTodoListView(viewModel: viewModel)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                viewModel.isPresentingCategoryManagementView = true
                            }) {
                                Label("Manage Categories", systemImage: "folder")
                            }
                            .sheet(isPresented: $viewModel.isPresentingCategoryManagementView) {
                                CategoryManagementView()
                            }
                        }
                    }
            }
        }
        .sheet(item: $viewModel.selectedTodoItem) { item in
            TodoItemDetailView(item: item)
        }
        .sheet(isPresented: $viewModel.isPresentingAddTodoItemView) {
            AddTodoItemView(
                selectedCategory: viewModel.selectedCategory,
                selectedPriority: viewModel.selectedPriority ?? 4,
                presetDueDate: viewModel.filterMode == .today
                    ? DateUtils.calendar.startOfDay(for: Date()) : nil
            )
        }
        .toast(messages: $viewModel.toastMessages)
        .onAppear {
            viewModel.configureContext(modelContext, auth, syncService)
            viewModel.reset()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                viewModel.updateCurrentDay()
            }
        }
    }
}

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext

        let d = Date()
        // Sample items with different dates and titles
        let todoItems = [
            TodoItem(
                title: "Z Task", details: "Details", dueDate: nil,
                owner: Fixtures.createUser()),
            TodoItem(
                title: "A Task", details: "Details", dueDate: d.addingTimeInterval(3600),
                owner: Fixtures.createUser()),
            TodoItem(
                title: "B Task", details: "Details", dueDate: d.addingTimeInterval(3600),
                owner: Fixtures.createUser()),
            TodoItem(
                title: "D Task", details: "Details", dueDate: d.addingTimeInterval(3600),
                priority: 2, owner: Fixtures.createUser()),
            TodoItem(
                title: "B Task", details: "Details", dueDate: d.addingTimeInterval(-24 * 3600),
                owner: Fixtures.createUser()),
            TodoItem(
                title: "C Task", details: "Details", dueDate: nil, owner: Fixtures.createUser()),
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
