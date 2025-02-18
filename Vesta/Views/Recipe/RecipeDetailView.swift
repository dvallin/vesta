import SwiftData
import SwiftUI

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var recipe: Recipe

    @State private var ingredientName: String = ""
    @State private var ingredientQuantity: String = ""
    @State private var ingredientUnit: String = ""

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

                VStack(alignment: .leading, spacing: 8) {
                    Text("Ingredients")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(recipe.ingredients) { ingredient in
                        HStack {
                            Text(
                                "\(ingredient.quantity, specifier: "%.2f") \(ingredient.unit) \(ingredient.name)"
                            )
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

                    HStack {
                        TextField("Name", text: $ingredientName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Quantity", text: $ingredientQuantity)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        TextField("Unit", text: $ingredientUnit)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button(action: addIngredient) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle(recipe.title)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    private func addIngredient() {
        guard let quantity = Double(ingredientQuantity), !ingredientName.isEmpty,
            !ingredientUnit.isEmpty
        else {
            return
        }
        recipe.addIngredient(name: ingredientName, quantity: quantity, unit: ingredientUnit)
        ingredientName = ""
        ingredientQuantity = ""
        ingredientUnit = ""
    }

    private func removeIngredient(_ ingredient: Ingredient) {
        recipe.removeIngredient(ingredient: ingredient)
    }
}

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)

        let context = container.mainContext
        let recipe = Recipe(title: "Spaghetti Bolognese", details: "A classic Italian pasta dish.")
        recipe.addIngredient(name: "Spaghetti", quantity: 200, unit: "g")
        recipe.addIngredient(name: "Ground Beef", quantity: 300, unit: "g")
        recipe.addIngredient(name: "Tomato Sauce", quantity: 400, unit: "ml")

        context.insert(recipe)

        return RecipeDetailView(recipe: recipe)
            .modelContainer(container)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
