import SwiftData
import SwiftUI

struct AddShoppingItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var showQuantityField: Bool = false
    @State private var quantity: String = ""
    @State private var selectedUnit: Unit? = nil

    @FocusState private var focusedField: FocusableField?

    enum FocusableField: Hashable {
        case name
        case quantity
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
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

                    if showQuantityField {
                        HStack {
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
                            .frame(width: 100)

                            Picker("", selection: $selectedUnit) {
                                ForEach(Unit.allCases, id: \.self) { unit in
                                    Text(unit.displayName).tag(unit)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                }

                if !showQuantityField {
                    Button("Add Quantity") {
                        showQuantityField = true
                        selectedUnit = .piece
                        focusedField = .quantity
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
                            "Cancel", comment: "Button to cancel adding a shopping item")
                    ) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
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
        .presentationDetents([.medium, .large])
        .onAppear {
            focusedField = .name
        }
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

        selectedUnit = nil
        showQuantityField = false

        dismiss()
    }
}

#Preview {
    AddShoppingItemView()
}
