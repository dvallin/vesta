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
                Section(header: Text("Item Details")) {
                    TextField("Item Name", text: $name)

                    HStack {
                        TextField("Quantity", value: $quantity, format: .number)
                            #if os(iOS)
                                .keyboardType(.decimalPad)
                            #endif

                        Picker("Unit", selection: $selectedUnit) {
                            Text("None").tag(nil as Unit?)
                            ForEach(Unit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit as Unit?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
            }
            .navigationTitle("Add Shopping Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addItem()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func addItem() {
        let todoItem = TodoItem(
            title: "Buy \(name)",
            details: "Shopping item",
            dueDate: Date()
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
