import SwiftData
import SwiftUI

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var recipe: Recipe

    @State private var ingredientName: String = ""
    @State private var ingredientQuantity: String = ""
    @State private var ingredientUnit: Unit? = nil

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                TextField(
                    "Title",
                    text: Binding(
                        get: { recipe.title },
                        set: { newValue in
                            recipe.title = newValue
                        }
                    )
                )
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
                        Button(action: addIngredient) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal)

                    ForEach(recipe.ingredients) { ingredient in
                        HStack {
                            Text(
                                "\(ingredient.quantity != nil ? NumberFormatter.localizedString(from: NSNumber(value: ingredient.quantity!), number: .decimal) : "") \(ingredient.unit?.rawValue ?? "")"
                            )
                            .frame(width: 100, alignment: .leading)
                            Text(ingredient.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                            Button(action: {
                                removeIngredient(ingredient)
                            }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer()
                    TextEditor(
                        text: Binding(
                            get: { recipe.details },
                            set: { newValue in
                                recipe.details = newValue
                            }
                        )
                    )
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8).stroke(.tertiary, lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
            }
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    private func addIngredient() {
        guard let quantity = Double(ingredientQuantity), !ingredientName.isEmpty else {
            return
        }
        recipe.ingredients.append(
            Ingredient(name: ingredientName, quantity: quantity, unit: ingredientUnit)
        )
        ingredientName = ""
        ingredientQuantity = ""
        ingredientUnit = nil
    }

    private func removeIngredient(_ ingredient: Ingredient) {
        if let index = recipe.ingredients.firstIndex(where: { $0 === ingredient }) {
            recipe.ingredients.remove(at: index)
        }
    }
}

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)

        let context = container.mainContext
        let recipe = Recipe(title: "Spaghetti Bolognese", details: "A classic Italian pasta dish.")
        recipe.ingredients.append(Ingredient(name: "Spaghetti", quantity: 200, unit: .gram))
        recipe.ingredients.append(Ingredient(name: "Ground Beef", quantity: 300, unit: .gram))
        recipe.ingredients.append(
            Ingredient(name: "Tomato Sauce", quantity: 400, unit: .milliliter))
        recipe.ingredients.append(Ingredient(name: "Salt", quantity: nil, unit: nil))

        context.insert(recipe)

        return RecipeDetailView(recipe: recipe)
            .modelContainer(container)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
