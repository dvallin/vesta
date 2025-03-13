import SwiftUI

struct ShoppingItemDetailView: View {
    var item: ShoppingListItem

    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text(
                        NSLocalizedString(
                            "Item Details", comment: "Section header for item details"))
                ) {
                    Text(
                        String(
                            format: NSLocalizedString("Name: %@", comment: "Item name format"),
                            item.name))

                    if let quantity = item.quantity, let unit = item.unit {
                        Text(
                            String(
                                format: NSLocalizedString(
                                    "Quantity: %.1f %@", comment: "Item quantity format"),
                                quantity, unit.displayName))
                    } else {
                        Text(
                            NSLocalizedString(
                                "No quantity specified", comment: "No quantity message"))
                    }

                    Toggle(
                        NSLocalizedString("Purchased", comment: "Purchase status toggle"),
                        isOn: .constant(item.todoItem.isCompleted)
                    )
                    .disabled(true)
                }

                if !item.meals.isEmpty {
                    Section(
                        header: Text(
                            NSLocalizedString(
                                "Related Meals", comment: "Section header for related meals"))
                    ) {
                        ForEach(item.meals) { meal in
                            VStack(alignment: .leading) {
                                Text(
                                    String(
                                        format: NSLocalizedString(
                                            "Recipe: %@", comment: "Recipe name format"),
                                        meal.recipe.title))
                                Text(
                                    String(
                                        format: NSLocalizedString(
                                            "Meal Type: %@", comment: "Meal type format"),
                                        meal.mealType.displayName))
                                if let dueDate = meal.todoItem.dueDate {
                                    Text(
                                        String(
                                            format: NSLocalizedString(
                                                "Planned for: %@", comment: "Planned date format"),
                                            dueDate.formatted(.dateTime)))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section(
                    header: Text(
                        NSLocalizedString("Todo Item", comment: "Section header for todo item"))
                ) {
                    Text(
                        String(
                            format: NSLocalizedString("Title: %@", comment: "Todo title format"),
                            item.todoItem.title))
                    if let dueDate = item.todoItem.dueDate {
                        Text(
                            String(
                                format: NSLocalizedString(
                                    "Due Date: %@", comment: "Due date format"),
                                dueDate.formatted(.dateTime)))
                    }
                }
            }
            .navigationTitle(item.name)
        }
    }
}

#Preview {
    let todoItem = TodoItem(title: "Grocery Shopping", details: "Weekly groceries", dueDate: Date())

    // Create multiple meals
    let recipe1 = Recipe(title: "Pasta Carbonara", details: "Classic Italian dish")
    let mealTodo1 = TodoItem(title: "Make dinner", details: "Pasta night")
    let meal1 = Meal(scalingFactor: 1.0, todoItem: mealTodo1, recipe: recipe1, mealType: .dinner)

    let recipe2 = Recipe(title: "Pasta Primavera", details: "Vegetarian pasta")
    let mealTodo2 = TodoItem(title: "Make lunch", details: "Light pasta")
    let meal2 = Meal(scalingFactor: 1.0, todoItem: mealTodo2, recipe: recipe2, mealType: .lunch)

    let shoppingItem = ShoppingListItem(
        name: "Pasta",
        quantity: 500,
        unit: .gram,
        todoItem: todoItem,
        meals: [meal1, meal2]
    )

    return ShoppingItemDetailView(item: shoppingItem)
}
