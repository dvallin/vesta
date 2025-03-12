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

                if !item.meals.isEmpty {
                    Section(header: Text("Related Meals")) {
                        ForEach(item.meals) { meal in
                            VStack(alignment: .leading) {
                                Text("Recipe: \(meal.recipe.title)")
                                Text("Meal Type: \(meal.mealType.rawValue.capitalized)")
                                if let dueDate = meal.todoItem.dueDate {
                                    Text("Planned for: \(dueDate, format: .dateTime)")
                                }
                            }
                            .padding(.vertical, 4)
                        }
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
