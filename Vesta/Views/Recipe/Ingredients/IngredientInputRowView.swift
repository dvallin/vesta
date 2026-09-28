import SwiftUI

struct IngredientInputRowView: View {
    @Binding var ingredientName: String
    @Binding var ingredientQuantity: String
    @Binding var ingredientUnit: Unit?

    let onAdd: () -> Void

    enum FocusableField: Hashable {
        case name
        case quantity
    }

    @FocusState private var focusedField: FocusableField?

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                TextField(
                    NSLocalizedString("Name", comment: "Ingredient name field placeholder"),
                    text: $ingredientName
                )
                .focused($focusedField, equals: .name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .onSubmit {
                    onAdd()
                    focusedField = .name
                }

                Button(action: {
                    withAnimation {
                        onAdd()
                        focusedField = .name
                    }
                }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.green)
                }.accessibilityIdentifier("AddButton")
            }

            HStack {
                TextField(
                    NSLocalizedString("Quantity", comment: "Ingredient quantity field placeholder"),
                    text: $ingredientQuantity
                )
                .focused($focusedField, equals: .quantity)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                #if os(iOS)
                    .keyboardType(.numbersAndPunctuation)
                #endif
                .frame(width: 80)

                Picker("", selection: $ingredientUnit) {
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
        .onAppear {
            focusedField = .name
        }
    }
}

#Preview {
    @Previewable @State var name = ""
    @Previewable @State var quantity = ""
    @Previewable @State var unit: Unit? = nil

    Form {
        IngredientInputRowView(
            ingredientName: $name,
            ingredientQuantity: $quantity,
            ingredientUnit: $unit,
            onAdd: {}
        )
        .padding()
    }
}

#Preview("With Values") {
    Form {
        IngredientInputRowView(
            ingredientName: .constant("Flour"),
            ingredientQuantity: .constant("100"),
            ingredientUnit: .constant(.gram),
            onAdd: {}
        )
        .padding()
    }
}
