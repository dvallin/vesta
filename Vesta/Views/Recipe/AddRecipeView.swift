import SwiftUI

struct TempIngredient: Identifiable {
    let id = UUID()
    let name: String
    let quantity: Double
    let unit: String
}

struct AddRecipeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var details: String = ""
    @State private var tempIngredients: [TempIngredient] = []

    @State private var ingredientName: String = ""
    @State private var ingredientQuantity: String = ""
    @State private var ingredientUnit: String = ""

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Title", text: $title)
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)

                TextEditor(text: $details)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8).stroke(.tertiary, lineWidth: 1)
                    )
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Ingredients")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(tempIngredients) { ingredient in
                        HStack {
                            Text(
                                "\(ingredient.quantity, specifier: "%.2f") \(ingredient.unit) \(ingredient.name)"
                            )
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

                    HStack {
                        TextField("Name", text: $ingredientName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Quantity", text: $ingredientQuantity)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        TextField("Unit", text: $ingredientUnit)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button(action: addTempIngredient) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
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
        guard let quantity = Double(ingredientQuantity),
            !ingredientName.isEmpty,
            !ingredientUnit.isEmpty
        else {
            return
        }
        let newIngredient = TempIngredient(
            name: ingredientName, quantity: quantity, unit: ingredientUnit)
        tempIngredients.append(newIngredient)
        // Clean up text fields
        ingredientName = ""
        ingredientQuantity = ""
        ingredientUnit = ""
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
            newRecipe.addIngredient(name: temp.name, quantity: temp.quantity, unit: temp.unit)
        }

        modelContext.insert(newRecipe)
    }
}

#Preview {
    return AddRecipeView()
}
