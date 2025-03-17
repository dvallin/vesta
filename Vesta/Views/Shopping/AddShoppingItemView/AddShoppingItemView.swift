import SwiftData
import SwiftUI

struct AddShoppingItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var quantity: String = ""
    @State private var selectedUnit: Unit = .piece

    enum FocusableField: Hashable {
        case quantity
        case name
    }

    @FocusState private var focusedField: FocusableField?

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        HStack(spacing: 4) {
                            TextField(
                                NSLocalizedString(
                                    "Quantity", comment: "Quantity field placeholder"),
                                text: $quantity
                            )
                            .focused($focusedField, equals: .quantity)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            #if os(iOS)
                                .keyboardType(.decimalPad)
                            #endif
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .name
                            }
                            .layoutPriority(1)

                            Picker("", selection: $selectedUnit) {
                                ForEach(Unit.allCases, id: \.self) { unit in
                                    Text(unit.displayName).tag(unit)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .fixedSize()
                        }
                        .frame(width: 150)

                        TextField(
                            NSLocalizedString("Name", comment: "Item name field placeholder"),
                            text: $name
                        )
                        .focused($focusedField, equals: .name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .submitLabel(.done)
                        .onSubmit {
                            if !name.isEmpty {
                                addItem()
                            }
                        }
                    }
                }
            }
            .navigationTitle(
                NSLocalizedString(
                    "Add Shopping Item",
                    comment: "Title for the add shopping item screen"
                )
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        NSLocalizedString(
                            "Cancel",
                            comment: "Button to cancel adding a shopping item"
                        )
                    ) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(
                        NSLocalizedString(
                            "Add Item",
                            comment: "Button to confirm adding a shopping item"
                        )
                    ) {
                        addItem()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func addItem() {
        let todoItem = TodoItem(
            title: String(
                format: NSLocalizedString(
                    "Buy %@",
                    comment: "Format for todo item title, where %@ is the item name"
                ),
                name
            ),
            details: NSLocalizedString(
                "Shopping item",
                comment: "Default details text for shopping items"
            )
        )

        let quantityDouble = Double(quantity) ?? nil

        let newItem = ShoppingListItem(
            name: name,
            quantity: quantityDouble,
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
