import SwiftData
import SwiftUI

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShoppingListItem.todoItem?.dueDate) var shoppingItems: [ShoppingListItem]

    @StateObject var viewModel: ShoppingListViewModel

    init(showPurchased: Bool = false) {
        _viewModel = StateObject(wrappedValue: ShoppingListViewModel(showPurchased: showPurchased))
    }

    var body: some View {
        NavigationView {
            ZStack {
                ShoppingList(
                    viewModel: viewModel,
                    shoppingItems: shoppingItems
                )

                FloatingAddButton {
                    viewModel.isPresentingAddShoppingItemView = true
                }
            }
            .navigationTitle(
                NSLocalizedString("Shopping List", comment: "Shopping list view title")
            )
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            viewModel.isPresentingFilterCriteriaView = true
                        }) {
                            Image(systemName: "line.horizontal.3.decrease.circle")
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
        .sheet(item: $viewModel.selectedShoppingItem) { item in
            ShoppingItemDetailView(item: item)
        }
        .sheet(isPresented: $viewModel.isPresentingAddShoppingItemView) {
            AddShoppingItemView()
        }
        .sheet(isPresented: $viewModel.isPresentingFilterCriteriaView) {
            ShoppingListFilterView(viewModel: viewModel)
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
        let todoItem1 = TodoItem(
            title: "Grocery Shopping", details: "Weekly groceries",
            owner: Fixtures.createUser())
        let todoItem2 = TodoItem(
            title: "Special Items", details: "For dinner party",
            owner: Fixtures.createUser())

        let items = [
            ShoppingListItem(
                name: "Milk", quantity: 1, unit: .liter, todoItem: todoItem1,
                owner: Fixtures.createUser()),
            ShoppingListItem(
                name: "Bread", quantity: 2, unit: .piece, todoItem: todoItem1,
                owner: Fixtures.createUser()),
            ShoppingListItem(
                name: "Eggs", quantity: 12, unit: .piece, todoItem: todoItem1,
                owner: Fixtures.createUser()),
            ShoppingListItem(
                name: "Wine", quantity: 2, unit: .piece, todoItem: todoItem2,
                owner: Fixtures.createUser()),
        ]

        for item in items {
            context.insert(item)
        }

        return ShoppingListView()
            .modelContainer(container)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
