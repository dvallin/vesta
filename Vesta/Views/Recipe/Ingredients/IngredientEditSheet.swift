import SwiftUI

struct IngredientEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var quantityText: String
    @State private var unit: Unit?

    let onSave: (String, Double?, Unit?) -> Void

    @FocusState private var isNameFocused: Bool

    init(
        name: String, quantityText: String, unit: Unit?,
        onSave: @escaping (String, Double?, Unit?) -> Void
    ) {
        _name = State(initialValue: name)
        _quantityText = State(initialValue: quantityText)
        _unit = State(initialValue: unit)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(
                    NSLocalizedString("Name", comment: "Ingredient name field placeholder"),
                    text: $name
                )
                .focused($isNameFocused)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.words)

                HStack {
                    TextField(
                        NSLocalizedString(
                            "Quantity", comment: "Ingredient quantity field placeholder"),
                        text: $quantityText
                    )
                    #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                    #endif
                    .frame(width: 80)

                    Picker(
                        NSLocalizedString("Unit", comment: "Ingredient unit picker label"),
                        selection: $unit
                    ) {
                        Text("None").tag(nil as Unit?)
                        ForEach(Unit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit as Unit?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .fixedSize()

                    Spacer()
                }
            }
            .navigationTitle(
                NSLocalizedString("Edit Ingredient", comment: "Edit ingredient sheet title")
            )
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("Save", comment: "Save button")) {
                        let parsedQuantity = parseQuantity(quantityText)
                        onSave(name, parsedQuantity, unit)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                isNameFocused = true
            }
        }
    }

    private func parseQuantity(_ text: String) -> Double? {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.number(from: text)?.doubleValue
    }
}

#Preview {
    IngredientEditSheet(
        name: "Flour",
        quantityText: "100",
        unit: .gram,
        onSave: { _, _, _ in }
    )
}

#Preview("Empty") {
    IngredientEditSheet(
        name: "",
        quantityText: "",
        unit: nil,
        onSave: { _, _, _ in }
    )
}
