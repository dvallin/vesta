import SwiftUI

struct ShoppingListItemRow: View {
    @ObservedObject var viewModel: ShoppingListViewModel
    var item: ShoppingListItem

    var body: some View {
        HStack {
            Button(action: togglePurchased) {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isPurchased ? .secondary : .blue)
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

                    if let quantity = item.quantity {
                        if let unit = item.unit {
                            Text("\(quantity, specifier: "%.1f") \(unit.displayName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(quantity, specifier: "%.1f")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let dueDate = item.todoItem?.dueDate {
                        Text(
                            String(
                                format: NSLocalizedString(
                                    "Needed by: %@", comment: "Shopping item due date"),
                                dueDate.formatted(.dateTime.day().month().hour().minute()))
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if !item.meals.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 4) {
                        ForEach(item.meals) { meal in
                            Text(meal.recipe?.title ?? "Unknown")
                                .font(.caption)
                                .padding(4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
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
            viewModel.undoTogglePurchased(item, id: id)
        }
    }
}

#Preview {
    let viewModel = ShoppingListViewModel()
    let user = Fixtures.createUser()
    
    let todoItem = TodoItem(title: "Grocery Shopping", details: "Weekly groceries",
                            dueDate: Date().addingTimeInterval(86400), owner: user)

    // Create multiple recipes and meals
    let recipe1 = Fixtures.bolognese(owner: user)
    let recipe2 = Fixtures.curry(owner: user)

    let mealTodo1 = TodoItem(
        title: "Make dinner", details: "Pasta night", owner: user)
    let mealTodo2 = TodoItem(
        title: "Make lunch", details: "Pasta lunch", owner: user)
    let mealTodo3 = TodoItem(
        title: "Make dinner", details: "Another pasta night", owner: user)

    let meal1 = Meal(
        scalingFactor: 1.0, todoItem: mealTodo1, recipe: recipe1, owner: user)
    let meal2 = Meal(
        scalingFactor: 1.0, todoItem: mealTodo2, recipe: recipe2, owner: user)
    let meal3 = Meal(
        scalingFactor: 1.0, todoItem: mealTodo3, recipe: recipe2, owner: user)
    
    let itemWithMeals = ShoppingListItem(
        name: "Pasta",
        quantity: 500,
        unit: .gram,
        todoItem: todoItem,
        owner: user
    )
    itemWithMeals.meals = [meal1, meal2, meal3]
    
    return List {
        // Regular shopping item
        ShoppingListItemRow(
            viewModel: viewModel,
            item: ShoppingListItem( name: "Milk", quantity: 1, unit: .liter, todoItem: todoItem, owner: user)
        )

        // Purchased item
        ShoppingListItemRow(
            viewModel: viewModel,
            item: ShoppingListItem( name: "Bread", quantity: 2, unit: .piece, todoItem: todoItem,  owner: user)
        )

        // Item without quantity/unit
        ShoppingListItemRow(
            viewModel: viewModel,
            item: ShoppingListItem( name: "Special sauce", todoItem: todoItem, owner: user)
        )

        // Item with multiple meal references
        ShoppingListItemRow(
            viewModel: viewModel,
            item: itemWithMeals
        )
    }
    .listStyle(.plain)
}
