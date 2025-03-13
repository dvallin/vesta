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
        #if os(iOS)
            .listStyle(.insetGrouped)
        #endif
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
                viewModel.deleteItem(filteredShoppingItems[index])
            }
        }
    }
}

#Preview {
    let todoItem = TodoItem(title: "Grocery Shopping", details: "Weekly groceries")
    let shoppingItems = [
        ShoppingListItem(name: "Milk", quantity: 1, unit: .liter, todoItem: todoItem),
        ShoppingListItem(name: "Bread", quantity: 2, unit: .piece, todoItem: todoItem),
        ShoppingListItem(name: "Eggs", quantity: 12, unit: .piece, todoItem: todoItem),
        ShoppingListItem(
            name: "Wine", quantity: 2, unit: .piece, todoItem: todoItem),
    ]

    return NavigationView {
        ShoppingList(
            viewModel: ShoppingListViewModel(),
            shoppingItems: shoppingItems
        )
    }
}
