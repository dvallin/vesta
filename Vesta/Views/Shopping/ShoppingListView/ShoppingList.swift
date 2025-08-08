import SwiftUI

struct ShoppingList: View {
    @ObservedObject var viewModel: ShoppingListViewModel

    var shoppingItems: [ShoppingListItem]

    var body: some View {
        List {
            ForEach(filteredShoppingItems) { item in
                ShoppingListItemRow(
                    viewModel: viewModel,
                    item: item
                )
            }
            .onDelete(perform: deleteShoppingItems)
        }
        .overlay {
            if filteredShoppingItems.isEmpty {
                ContentUnavailableView(
                    label: {
                        Label(
                            NSLocalizedString(
                                "No Shopping Items", comment: "Empty shopping list title"),
                            systemImage: "cart"
                        )
                    },
                    description: {
                        Text(
                            NSLocalizedString(
                                "Add items to your shopping list",
                                comment: "Empty shopping list description"
                            )
                        )
                    },
                    actions: {
                        Button(
                            NSLocalizedString("Add Item", comment: "Button to add shopping item")
                        ) {
                            viewModel.isPresentingAddShoppingItemView = true
                        }
                    }
                )
            }
        }
    }

    private var filteredShoppingItems: [ShoppingListItem] {
        viewModel.filterItems(shoppingItems: shoppingItems)
    }

    private func deleteShoppingItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                viewModel.deleteItem(filteredShoppingItems[index]) { item, id in
                    viewModel.undoDeleteItem(item, id: id)
                }
            }
        }
    }
}

#Preview {
    let todoItem = TodoItem(
        title: "Grocery Shopping", details: "Weekly groceries", owner: Fixtures.createUser())
    let shoppingItems = [
        ShoppingListItem(
            name: "Milk", quantity: 1, unit: .liter, todoItem: todoItem,
            owner: Fixtures.createUser()),
        ShoppingListItem(
            name: "Bread", quantity: 2, unit: .piece, todoItem: todoItem,
            owner: Fixtures.createUser()),
        ShoppingListItem(
            name: "Eggs", quantity: 12, unit: .piece, todoItem: todoItem,
            owner: Fixtures.createUser()),
        ShoppingListItem(
            name: "Wine", quantity: 2, unit: .piece, todoItem: todoItem,
            owner: Fixtures.createUser()),
    ]

    return NavigationView {
        ShoppingList(
            viewModel: ShoppingListViewModel(),
            shoppingItems: shoppingItems
        )
    }
}
