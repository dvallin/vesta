import SwiftUI

struct TempIngredient: Identifiable {
    let id = UUID()
    let name: String
    let quantity: Double?
    let unit: Unit?
}

struct AddRecipeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var details: String = ""
    @State private var tempIngredients: [TempIngredient] = []

    @State private var ingredientName: String = ""
    @State private var ingredientQuantity: String = ""
    @State private var ingredientUnit: Unit? = nil

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Title", text: $title)
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Ingredients")
                        .font(.headline)
                        .padding(.horizontal)

                    HStack {
                        TextField("Quantity", text: $ingredientQuantity)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .keyboardType(.decimalPad)
                        Picker("Unit", selection: $ingredientUnit) {
                            Text("Unit").tag(Unit?.none)
                            ForEach(Unit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit as Unit?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        TextField("Name", text: $ingredientName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button(action: addTempIngredient) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal)

                    ForEach(tempIngredients) { ingredient in
                        HStack {
                            Text(
                                "\(ingredient.quantity != nil ? NumberFormatter.localizedString(from: NSNumber(value: ingredient.quantity!), number: .decimal) : "") \(ingredient.unit?.rawValue ?? "")"
                            )
                            .frame(width: 100, alignment: .leading)
                            Text(ingredient.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                            Button(action: {
                                removeTempIngredient(ingredient)
                            }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()
                TextEditor(text: $details)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8).stroke(.tertiary, lineWidth: 1)
                    )
                    .padding(.horizontal)
            }
            .navigationTitle("Add Recipe")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("Cancel") {
                        dismiss()
                    },
                    trailing: Button("Save") {
                        saveRecipe()
                        dismiss()
                    }
                )
            #endif
        }
    }

    private func addTempIngredient() {
        guard !ingredientName.isEmpty else {
            return
        }

        let quantity = Double(ingredientQuantity)
        let newIngredient = TempIngredient(
            name: ingredientName, quantity: quantity,
            unit: ingredientUnit)
        tempIngredients.append(newIngredient)
        // Clean up text fields
        ingredientName = ""
        ingredientQuantity = ""
        ingredientUnit = nil
    }

    private func removeTempIngredient(_ ingredient: TempIngredient) {
        tempIngredients.removeAll { $0.id == ingredient.id }
    }

    private func saveRecipe() {
        // Create a new recipe
        let newRecipe = Recipe(title: title, details: details)

        // Convert TempIngredients into proper Ingredient model objects.
        // Here we add them using the Recipe's helper method which attaches the recipe
        for temp in tempIngredients {
            newRecipe.ingredients.append(
                Ingredient(name: temp.name, quantity: temp.quantity, unit: temp.unit)
            )
        }

        modelContext.insert(newRecipe)
    }
}

#Preview {
    AddRecipeView()
}
