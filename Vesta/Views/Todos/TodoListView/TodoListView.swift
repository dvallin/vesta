import SwiftData
import SwiftUI

struct TodoListView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Query(
        sort: [
            SortDescriptor(\TodoItem.priority, order: .forward),
            SortDescriptor(\TodoItem.dueDate, order: .forward),
            SortDescriptor(\TodoItem.title, order: .forward),
        ]) var todoItems: [TodoItem]

    @StateObject var viewModel = TodoListViewModel()

    var body: some View {
        NavigationView {
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
                #if os(iOS)
                    ToolbarItem(placement: .automatic) {
                        Button(action: {
                            viewModel.isPresentingTodoEventsView = true
                            HapticFeedbackManager.shared.generateSelectionFeedback()
                        }) {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                    }
                #endif
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
        .sheet(isPresented: $viewModel.isPresentingTodoEventsView) {
            TodoEventsView()
        }
        .toast(messages: $viewModel.toastMessages)
        .onAppear {
            viewModel.configureContext(modelContext)
            viewModel.reset()
        }
        .onChange(of: scenePhase) { newPhase, _ in
            if newPhase == .active {
                viewModel.reset()
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
            TodoItem(title: "Z Task", details: "Details", dueDate: nil),
            TodoItem(title: "A Task", details: "Details", dueDate: d.addingTimeInterval(3600)),
            TodoItem(title: "B Task", details: "Details", dueDate: d.addingTimeInterval(3600)),
            TodoItem(
                title: "D Task", details: "Details", dueDate: d.addingTimeInterval(3600),
                priority: 2),
            TodoItem(
                title: "B Task", details: "Details", dueDate: d.addingTimeInterval(-24 * 3600)),
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
