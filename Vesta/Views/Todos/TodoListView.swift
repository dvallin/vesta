import SwiftData
import SwiftUI

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var todoItems: [TodoItem]

    @State private var filterMode: FilterMode = .all
    @State private var showCompletedItems: Bool = false
    @State private var searchText: String = ""

    @State private var isPresentingAddTodoItemView = false
    @State private var isPresentingTodoEventsView = false
    @State private var isPresentingFilterCriteriaView = false

    @State private var toastMessages: [ToastMessage] = []

    @State private var selectedTodoItem: TodoItem?

    init(filterMode: FilterMode = .all, showCompletedItems: Bool = false) {
        _filterMode = State(initialValue: filterMode)
        _showCompletedItems = State(initialValue: showCompletedItems)
    }

    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(filteredTodoItems) { item in
                        HStack {
                            Button(action: {
                                markAsDone(item: item)
                            }) {
                                Image(
                                    systemName: item.isCompleted
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                )
                                .foregroundColor(item.isCompleted ? .secondary : .accentColor)
                                .scaleEffect(item.isCompleted ? 1 : 1.5)
                                .animation(.easeInOut, value: item.isCompleted)
                            }
                            .disabled(item.isCompleted)
                            .buttonStyle(BorderlessButtonStyle())

                            Button(action: {
                                selectedTodoItem = item
                            }) {
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
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .shadow(radius: 10)
                        }
                        .padding()
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
            FilterCriteriaView(filterMode: $filterMode, showCompletedItems: $showCompletedItems)
                .presentationDetents([.medium, .large])
        }
        .toast(messages: $toastMessages)
    }

    private var filteredTodoItems: [TodoItem] {
        todoItems.filter { item in
            let matchesSearchText =
                searchText.isEmpty || item.title.localizedCaseInsensitiveContains(searchText)
                || item.details.localizedCaseInsensitiveContains(searchText)
            let matchesCompleted = showCompletedItems || !item.isCompleted
            guard matchesSearchText && matchesCompleted else { return false }

            switch filterMode {
            case .all:
                return true
            case .today:
                return Calendar.current.isDateInToday(item.dueDate ?? Date.distantPast)
            case .noDueDate:
                return item.dueDate == nil
            }
        }
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
