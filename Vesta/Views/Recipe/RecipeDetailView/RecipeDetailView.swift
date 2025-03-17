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

    @State private var isEditingTitle = false
    @State private var isEditingDetails = false

    init(recipe: Recipe) {
        _viewModel = StateObject(wrappedValue: RecipeDetailViewModel(recipe: recipe))
    }

    var body: some View {
        Form {
            Text(viewModel.recipe.title)
                .font(.title)
                .bold()
                .onTapGesture {
                    isEditingTitle = true
                }

            IngredientsSection(
                header: NSLocalizedString("Ingredients", comment: "Section header for ingredients"),
                ingredients: viewModel.recipe.ingredients,
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
            #if os(iOS)
                .environment(\.editMode, .constant(.active))
            #endif

            Section(
                header: Text(NSLocalizedString("Description", comment: "Section header"))
            ) {
                Text(viewModel.recipe.details)
                    .onTapGesture {
                        isEditingDetails = true
                    }
            }
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
        .sheet(isPresented: $isEditingTitle) {
            EditTitleView(
                navigationBarTitle: NSLocalizedString("Edit Title", comment: "Navigation title"),
                title: Binding(
                    get: { viewModel.recipe.title },
                    set: { newValue in
                        viewModel.recipe.title = newValue
                    }
                ))
        }
        .sheet(isPresented: $isEditingDetails) {
            EditDetailsView(
                navigationBarTitle: NSLocalizedString(
                    "Edit Description", comment: "Navigation title"),
                details: Binding(
                    get: { viewModel.recipe.details },
                    set: { newValue in
                        viewModel.recipe.details = newValue
                    }
                ))
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
