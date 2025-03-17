import SwiftUI

struct IngredientInputRowView: View {
    @Binding var ingredientQuantity: String
    @Binding var ingredientUnit: Unit
    @Binding var ingredientName: String

    let onAdd: () -> Void

    enum FocusableField: Hashable {
        case quantity
        case name
    }

    @FocusState private var focusedField: FocusableField?

    var body: some View {
        HStack {
            HStack(spacing: 4) {
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
                .layoutPriority(1)

                Picker("", selection: $ingredientUnit) {
                    ForEach(Unit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit as Unit?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .fixedSize()
            }
            .frame(width: 150)

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

#Preview {
    @Previewable @State var quantity = ""
    @Previewable @State var unit: Unit = .piece
    @Previewable @State var name = ""

    Form {
        IngredientInputRowView(
            ingredientQuantity: $quantity,
            ingredientUnit: $unit,
            ingredientName: $name,
            onAdd: {}
        )
        .padding()
    }
}

#Preview("With Values") {
    Form {
        IngredientInputRowView(
            ingredientQuantity: .constant("100"),
            ingredientUnit: .constant(.gram),
            ingredientName: .constant("Flour"),
            onAdd: {}
        )
        .padding()
    }
}
