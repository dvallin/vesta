import SwiftData
import SwiftUI

struct AddShoppingItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var quantity: Double?
    @State private var selectedUnit: Unit?

    var body: some View {
        NavigationView {
            Form {
                // Section header for item details
                Section(
                    header: Text(
                        NSLocalizedString(
                            "Item Details",
                            comment: "Header for the section containing shopping item details"))
                ) {
                    // Text field for entering item name
                    TextField(
                        NSLocalizedString(
                            "Item Name", comment: "Placeholder text for item name input field"),
                        text: $name)

                    HStack {
                        // Text field for entering quantity
                        TextField(
                            NSLocalizedString(
                                "Quantity", comment: "Placeholder text for quantity input field"),
                            value: $quantity,
                            format: .number
                        )
                        #if os(iOS)
                            .keyboardType(.decimalPad)
                        #endif

                        // Picker for selecting unit of measurement
                        Picker(
                            NSLocalizedString("Unit", comment: "Label for unit selection picker"),
                            selection: $selectedUnit
                        ) {
                            // Option for no unit selected
                            Text(NSLocalizedString("None", comment: "Option for no unit selection"))
                                .tag(nil as Unit?)
                            ForEach(Unit.allCases, id: \.self) { unit in
                                Text(unit.displayName).tag(unit as Unit?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
            }
            // Navigation title for the view
            .navigationTitle(
                NSLocalizedString(
                    "Add Shopping Item", comment: "Title for the add shopping item screen")
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // Cancel button
                    Button(
                        NSLocalizedString(
                            "Cancel", comment: "Button to cancel adding a shopping item")
                    ) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    // Add item button
                    Button(
                        NSLocalizedString(
                            "Add Item", comment: "Button to confirm adding a shopping item")
                    ) {
                        addItem()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func addItem() {
        let todoItem = TodoItem(
            // Format string for creating todo item title
            title: String(
                format: NSLocalizedString(
                    "Buy %@", comment: "Format for todo item title, where %@ is the item name"),
                name),
            // Generic details for shopping item
            details: NSLocalizedString(
                "Shopping item", comment: "Default details text for shopping items")
        )

        let newItem = ShoppingListItem(
            name: name,
            quantity: quantity,
            unit: selectedUnit,
            todoItem: todoItem
        )

        modelContext.insert(todoItem)
        modelContext.insert(newItem)

        dismiss()
    }
}

#Preview {
    AddShoppingItemView()
}
