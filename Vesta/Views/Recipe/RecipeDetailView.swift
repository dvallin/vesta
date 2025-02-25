import SwiftData
import SwiftUI

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var recipe: Recipe

    // For entering new ingredient values.
    @State private var ingredientName: String = ""
    @State private var ingredientQuantity: String = ""
    @State private var ingredientUnit: Unit? = nil

    @State private var showingValidationAlert = false
    @State private var validationMessage = ""

    @State private var isEditingTitle = false
    @State private var isEditingDetails = false

    var body: some View {
        Form {
            Text(recipe.title)
                .font(.title)
                .bold()
                .onTapGesture {
                    isEditingTitle = true
                }

            IngredientsSection(
                header: "Ingredients",
                ingredients: recipe.ingredients,
                removeHandler: removeIngredient,
                quantityText: { ingredient in
                    let qtyPart =
                        ingredient.quantity.map {
                            NumberFormatter.localizedString(
                                from: NSNumber(value: $0), number: .decimal)
                        } ?? ""
                    let unitPart = ingredient.unit?.rawValue ?? ""
                    return qtyPart + " " + unitPart
                },
                nameText: { $0.name },
                ingredientName: $ingredientName,
                ingredientQuantity: $ingredientQuantity,
                ingredientUnit: $ingredientUnit,
                onAdd: addIngredient
            )
            .environment(\.editMode, .constant(.active))

            Section(header: Text("Description")) {
                Text(recipe.details)
                    .onTapGesture {
                        isEditingDetails = true
                    }
            }
        }
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .alert("Validation Error", isPresented: $showingValidationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationMessage)
        }
        .sheet(isPresented: $isEditingTitle) {
            EditTitleView(
                navigationBarTitle: "Edit Title",
                title: Binding(
                    get: { recipe.title },
                    set: { newValue in
                        recipe.title = newValue
                    }
                ))
        }
        .sheet(isPresented: $isEditingDetails) {
            EditDetailsView(
                navigationBarTitle: "Edit Description",
                details: Binding(
                    get: { recipe.details },
                    set: { newValue in
                        recipe.details = newValue
                    }
                ))
        }
    }

    // MARK: - Private Methods

    private func addIngredient() {
        guard !ingredientName.isEmpty else {
            validationMessage = "Please enter an ingredient name."
            showingValidationAlert = true
            return
        }

        let quantity = Double(ingredientQuantity)
        let newIngredient = Ingredient(
            name: ingredientName, quantity: quantity, unit: ingredientUnit)

        withAnimation {
            recipe.ingredients.append(newIngredient)
        }

        // Reset the input fields.
        ingredientName = ""
        ingredientQuantity = ""
        ingredientUnit = nil
    }

    private func removeIngredient(_ ingredient: Ingredient) {
        withAnimation {
            if let index = recipe.ingredients.firstIndex(where: { $0 === ingredient }) {
                recipe.ingredients.remove(at: index)
            }
        }
    }
}

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext

        let recipe = Recipe(
            title: "Spaghetti Bolognese",
            details: "A classic Italian pasta dish."
        )
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
