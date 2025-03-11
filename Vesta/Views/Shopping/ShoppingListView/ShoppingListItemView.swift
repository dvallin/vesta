import SwiftUI

struct ShoppingListItemRow: View {
    @ObservedObject var viewModel: ShoppingListViewModel
    var item: ShoppingListItem

    var body: some View {
        HStack {
            Button(action: togglePurchased) {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isPurchased ? .secondary : .accentColor)
                    .scaleEffect(item.isPurchased ? 1 : 1.5)
                    .animation(.easeInOut, value: item.isPurchased)
            }
            .buttonStyle(BorderlessButtonStyle())

            Button(action: selectItem) {
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.headline)
                        .strikethrough(item.isPurchased)
                        .foregroundColor(item.isPurchased ? .secondary : .primary)

                    if let quantity = item.quantity, let unit = item.unit {
                        Text("\(quantity, specifier: "%.1f") \(unit.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let dueDate = item.todoItem.dueDate {
                        Text(
                            "Needed by: \(dueDate, format: .dateTime.day().month().hour().minute())"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if let meal = item.meal {
                Text(meal.recipe.title)
                    .font(.caption)
                    .padding(4)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(4)
            }
        }
    }

    private func selectItem() {
        viewModel.selectedShoppingItem = item
    }

    private func togglePurchased() {
        withAnimation {
            viewModel.togglePurchased(item, undoAction: undoTogglePurchased)
        }
    }

    private func undoTogglePurchased(item: ShoppingListItem, id: UUID) {
        withAnimation {
            viewModel.togglePurchased(item, id: id)
        }
    }
}

#Preview {
    let viewModel = ShoppingListViewModel()
    let todoItem = TodoItem(
        title: "Grocery Shopping", details: "Weekly groceries",
        dueDate: Date().addingTimeInterval(86400))

    return List {
        // Regular shopping item
        ShoppingListItemRow(
            viewModel: viewModel,
            item: ShoppingListItem(name: "Milk", quantity: 1, unit: .liter, todoItem: todoItem)
        )

        // Purchased item
        ShoppingListItemRow(
            viewModel: viewModel,
            item: ShoppingListItem(
                name: "Bread", quantity: 2, unit: .piece, isPurchased: true, todoItem: todoItem)
        )

        // Item without quantity/unit
        ShoppingListItemRow(
            viewModel: viewModel,
            item: ShoppingListItem(name: "Special sauce", todoItem: todoItem)
        )

        // Item with meal reference
        let recipe = Recipe(title: "Pasta Carbonara", details: "Classic Italian dish")
        let mealTodo = TodoItem(title: "Make dinner", details: "Pasta night")
        let meal = Meal(scalingFactor: 1.0, todoItem: mealTodo, recipe: recipe)
        ShoppingListItemRow(
            viewModel: viewModel,
            item: ShoppingListItem(
                name: "Pasta", quantity: 500, unit: .gram, todoItem: todoItem, meal: meal)
        )
    }
    .listStyle(.plain)
}
