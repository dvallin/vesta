import SwiftUI

struct IngredientInputRowView: View {
    @Binding var ingredientQuantity: String
    @Binding var ingredientUnit: Unit?
    @Binding var ingredientName: String

    let onAdd: () -> Void

    enum FocusableField: Hashable {
        case quantity
        case name
    }

    @FocusState private var focusedField: FocusableField?

    var body: some View {
        HStack {
            TextField(
                NSLocalizedString("Quantity", comment: "Ingredient quantity field placeholder"),
                text: $ingredientQuantity
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
            .frame(width: 80)

            Picker("", selection: $ingredientUnit) {
                Text(NSLocalizedString("Unit", comment: "Unit picker default option")).tag(
                    Unit?.none)
                ForEach(Unit.allCases, id: \.self) { unit in
                    Text(unit.displayName).tag(unit as Unit?)
                }
            }
            .pickerStyle(MenuPickerStyle())

            TextField(
                NSLocalizedString("Name", comment: "Ingredient name field placeholder"),
                text: $ingredientName
            )
            .focused($focusedField, equals: .name)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .submitLabel(.done)
            .onSubmit { onAdd() }

            Button(action: {
                withAnimation {
                    onAdd()
                }
            }) {
                Image(systemName: "plus.circle")
                    .foregroundColor(.green)
            }
        }
    }
}
