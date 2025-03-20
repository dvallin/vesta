import SwiftData
import SwiftUI

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: RecipeDetailViewModel

    // For entering new ingredient values.
    @State private var ingredientName: String = ""
    @State private var ingredientQuantity: String = ""
    @State private var ingredientUnit: Unit? = nil

    @State private var showingValidationAlert = false
    @State private var validationMessage = ""

    @FocusState private var focusedField: String?

    init(recipe: Recipe) {
        _viewModel = StateObject(wrappedValue: RecipeDetailViewModel(recipe: recipe))
    }

    var body: some View {
        Form {
            RecipeTitleInputView(title: $viewModel.recipe.title)
                .focused($focusedField, equals: "title")

            IngredientsSection(
                header: NSLocalizedString("Ingredients", comment: "Section header for ingredients"),
                ingredients: viewModel.recipe.sortedIngredients,
                moveHandler: viewModel.moveIngredient,
                removeHandler: viewModel.removeIngredient,
                quantityText: { ingredient in
                    let qtyPart =
                        ingredient.quantity.map {
                            NumberFormatter.localizedString(
                                from: NSNumber(value: $0), number: .decimal)
                        } ?? ""
                    let unitPart = ingredient.unit?.displayName ?? ""
                    return qtyPart + " " + unitPart
                },
                nameText: { $0.name },
                ingredientName: $ingredientName,
                ingredientQuantity: $ingredientQuantity,
                ingredientUnit: $ingredientUnit,
                onAdd: addIngredient
            )
            .focused($focusedField, equals: "ingredients")
            #if os(iOS)
                .environment(\.editMode, .constant(.active))
            #endif

            RecipeDetailsEditorView(details: $viewModel.recipe.details)
                .focused($focusedField, equals: "details")
        }
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .alert(
            NSLocalizedString("Validation Error", comment: "Validation error alert title"),
            isPresented: $showingValidationAlert
        ) {
            Button(
                NSLocalizedString("OK", comment: "Validation error accept button"), role: .cancel
            ) {}
        } message: {
            Text(validationMessage)
        }
        .toolbar {
            #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.save()
                        dismiss()
                    }
                }
            #endif

            ToolbarItem(placement: .keyboard) {
                Button(NSLocalizedString("Done", comment: "Done button")) {
                    focusedField = nil
                }
            }
        }
        .onAppear {
            viewModel.configureEnvironment(modelContext)
        }
    }

    // MARK: - Private Methods

    private func addIngredient() {
        guard !ingredientName.isEmpty else {
            validationMessage = NSLocalizedString(
                "Please enter an ingredient name.", comment: "Validation error message")
            showingValidationAlert = true
            return
        }

        let quantity = Double(ingredientQuantity)
        viewModel.addIngredient(name: ingredientName, quantity: quantity, unit: ingredientUnit)

        // Reset the input fields.
        ingredientName = ""
        ingredientQuantity = ""
        ingredientUnit = nil
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
        recipe.ingredients.append(
            Ingredient(name: "Spaghetti", order: 1, quantity: 200, unit: .gram))
        recipe.ingredients.append(
            Ingredient(name: "Ground Beef", order: 2, quantity: 300, unit: .gram))
        recipe.ingredients.append(
            Ingredient(name: "Tomato Sauce", order: 3, quantity: 400, unit: .milliliter))
        recipe.ingredients.append(Ingredient(name: "Salt", order: 4, quantity: nil, unit: nil))

        context.insert(recipe)
        return RecipeDetailView(recipe: recipe)
            .modelContainer(container)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
