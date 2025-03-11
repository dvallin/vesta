import SwiftUI

struct ShoppingItemDetailView: View {
    var item: ShoppingListItem

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    Text("Name: \(item.name)")

                    if let quantity = item.quantity, let unit = item.unit {
                        Text("Quantity: \(quantity, specifier: "%.1f") \(unit.rawValue)")
                    } else {
                        Text("No quantity specified")
                    }

                    Toggle("Purchased", isOn: .constant(item.isPurchased))
                        .disabled(true)
                }

                if let meal = item.meal {
                    Section(header: Text("Related Meal")) {
                        Text("Recipe: \(meal.recipe.title)")
                        Text("Meal Type: \(meal.mealType.rawValue.capitalized)")
                    }
                }

                Section(header: Text("Todo Item")) {
                    Text("Title: \(item.todoItem.title)")
                    if let dueDate = item.todoItem.dueDate {
                        Text("Due Date: \(dueDate, format: .dateTime)")
                    }
                }
            }
            .navigationTitle(item.name)
        }
    }
}

#Preview {
    let todoItem = TodoItem(title: "Grocery Shopping", details: "Weekly groceries", dueDate: Date())
    let recipe = Recipe(title: "Pasta Carbonara", details: "Classic Italian dish")
    let mealTodo = TodoItem(title: "Make dinner", details: "Pasta night")
    let meal = Meal(scalingFactor: 1.0, todoItem: mealTodo, recipe: recipe, mealType: .dinner)

    let shoppingItem = ShoppingListItem(
        name: "Pasta",
        quantity: 500,
        unit: .gram,
        todoItem: todoItem,
        meal: meal
    )

    return ShoppingItemDetailView(item: shoppingItem)
}
