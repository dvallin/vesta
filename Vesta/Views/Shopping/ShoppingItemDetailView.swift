import SwiftUI

struct ShoppingItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State var item: ShoppingListItem
    @State private var quantity: String
    @State private var selectedUnit: Unit?
    @State private var isEditingQuantity = false
    @FocusState private var focusedField: String?

    init(item: ShoppingListItem) {
        self._item = State(initialValue: item)
        self._quantity = State(initialValue: item.quantity != nil ? String(item.quantity!) : "")
        self._selectedUnit = State(initialValue: item.unit)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text(
                        NSLocalizedString(
                            "Item Details", comment: "Section header for item details"))
                ) {
                    Text(item.name)
                        .font(.title)
                        .textInputAutocapitalization(.words)

                    if isEditingQuantity {
                        HStack {
                            TextField(
                                NSLocalizedString(
                                    "Quantity", comment: "Quantity field placeholder"),
                                text: $quantity
                            )
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            #if os(iOS)
                                .keyboardType(.decimalPad)
                            #endif
                            .focused($focusedField, equals: "quantity")
                            .frame(width: 100)

                            Picker("", selection: $selectedUnit) {
                                ForEach(Unit.allCases, id: \.self) { unit in
                                    Text(unit.displayName).tag(unit as Unit?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    } else {
                        if !quantity.isEmpty && quantity != "0" {
                            Text(
                                String(
                                    format: NSLocalizedString(
                                        "Quantity: %.1f %@", comment: "Quantity and unit format"),
                                    Double(quantity) ?? 0, selectedUnit?.displayName ?? "")
                            )
                            .foregroundColor(.primary)
                            .onTapGesture {
                                isEditingQuantity = true
                            }
                        } else {
                            Text(
                                NSLocalizedString(
                                    "No quantity specified",
                                    comment: "Displayed when no quantity is set")
                            )
                            .foregroundColor(.primary)
                            .onTapGesture {
                                isEditingQuantity = true
                            }
                        }
                    }

                    Toggle(
                        NSLocalizedString("Purchased", comment: "Purchase status toggle"),
                        isOn: .constant(item.isPurchased)
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
                            NavigationLink(destination: MealDetailView(meal: meal)) {
                                VStack(alignment: .leading) {
                                    Text(
                                        String(
                                            format: NSLocalizedString(
                                                "Recipe: %@", comment: "Recipe name format"),
                                            meal.recipe?.title ?? "Unknown"))
                                    Text(
                                        String(
                                            format: NSLocalizedString(
                                                "Meal Type: %@", comment: "Meal type format"),
                                            meal.mealType.displayName))
                                    if let dueDate = meal.todoItem?.dueDate {
                                        Text(
                                            String(
                                                format: NSLocalizedString(
                                                    "Planned for: %@",
                                                    comment: "Planned date format"),
                                                dueDate.formatted(.dateTime)))
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }

                Section(
                    header: Text(
                        NSLocalizedString("Todo Item", comment: "Section header for todo item"))
                ) {
                    if let todoItem = item.todoItem {
                        NavigationLink(destination: TodoItemDetailView(item: todoItem)) {
                            VStack(alignment: .leading) {
                                Text(
                                    String(
                                        format: NSLocalizedString(
                                            "Title: %@", comment: "Todo title format"),
                                        todoItem.title))
                                if let dueDate = todoItem.dueDate {
                                    Text(
                                        String(
                                            format: NSLocalizedString(
                                                "Due Date: %@", comment: "Due date format"),
                                            dueDate.formatted(.dateTime)))
                                }
                            }
                        }
                    } else {
                        Text(
                            String(
                                format: NSLocalizedString(
                                    "Title: %@", comment: "Todo title format"),
                                "Unknown"))
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(
                        NSLocalizedString("Save", comment: "Save button")
                    ) {
                        isEditingQuantity = false
                        focusedField = nil
                        saveChanges()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .keyboard) {
                    Button(NSLocalizedString("Done", comment: "Done button")) {
                        isEditingQuantity = false
                        focusedField = nil
                    }
                }
            }
        }
    }

    private func saveChanges() {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let quantityDouble = numberFormatter.number(from: quantity)?.doubleValue

        item.setQuantity(newQuantity: quantityDouble)
        item.setUnit(newUnit: selectedUnit)

        do {
            try modelContext.save()
        } catch {}
    }
}

#Preview {
    let user = Fixtures.createUser()

    let todoItem = TodoItem(
        title: "Grocery Shopping", details: "Weekly groceries", dueDate: Date(), owner: user)

    // Create multiple meals
    let recipe1 = Fixtures.curry(owner: user)
    let mealTodo1 = TodoItem(title: "Make dinner", details: "Pasta night", owner: user)
    let meal1 = Meal(
        scalingFactor: 1.0, todoItem: mealTodo1, recipe: recipe1, mealType: .dinner, owner: user)

    let recipe2 = Fixtures.bolognese(owner: user)
    let mealTodo2 = TodoItem(title: "Make lunch", details: "Light pasta", owner: user)
    let meal2 = Meal(
        scalingFactor: 1.0, todoItem: mealTodo2, recipe: recipe2, mealType: .lunch, owner: user)

    let shoppingItem = ShoppingListItem(
        name: "Pasta",
        quantity: 500,
        unit: .gram,
        todoItem: todoItem,
        owner: user
    )
    shoppingItem.meals.append(meal1)
    shoppingItem.meals.append(meal2)

    return ShoppingItemDetailView(item: shoppingItem)
}
