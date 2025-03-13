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

    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @State private var showingDiscardAlert = false
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            Form {
                RecipeTitleInputView(title: $title)

                IngredientsSection(
                    header: NSLocalizedString(
                        "Ingredients", comment: "Section header for ingredients"),
                    ingredients: tempIngredients,
                    removeHandler: removeTempIngredient,
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
                    onAdd: addTempIngredient
                )
                #if os(iOS)
                    .environment(\.editMode, .constant(.active))
                #endif

                RecipeDetailsEditorView(details: $details)
            }
            .navigationTitle(
                NSLocalizedString("Add Recipe", comment: "Navigation title for add recipe view")
            )
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                            if !title.isEmpty || !details.isEmpty || !tempIngredients.isEmpty {
                                showingDiscardAlert = true
                            } else {
                                dismiss()
                            }
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(NSLocalizedString("Save", comment: "Save button")) {
                            validateAndSave()
                        }
                        .disabled(isSaving)
                    }
                #endif
            }
            .alert(
                NSLocalizedString("Validation Error", comment: "Validation error alert title"),
                isPresented: $showingValidationAlert
            ) {
                Button(
                    NSLocalizedString("OK", comment: "Validation error accept button"),
                    role: .cancel
                ) {}
            } message: {
                Text(validationMessage)
            }
            .alert(
                NSLocalizedString("Discard Changes?", comment: "Alert title"),
                isPresented: $showingDiscardAlert
            ) {
                Button(NSLocalizedString("Discard", comment: "Alert button"), role: .destructive) {
                    dismiss()
                }
                Button(
                    NSLocalizedString("Continue Editing", comment: "Alert button"), role: .cancel
                ) {}
            }
        }
    }

    // MARK: - Private Methods

    private func addTempIngredient() {
        guard !ingredientName.isEmpty else {
            validationMessage = NSLocalizedString(
                "Please enter an ingredient name.", comment: "Validation error message")
            showingValidationAlert = true
            return
        }

        // Convert the quantity text to a Double; if conversion fails, it ends up as nil.
        let quantity = Double(ingredientQuantity)
        let newIngredient = TempIngredient(
            name: ingredientName,
            quantity: quantity,
            unit: ingredientUnit
        )

        withAnimation {
            tempIngredients.append(newIngredient)
        }

        // Reset the input fields.
        ingredientName = ""
        ingredientQuantity = ""
        ingredientUnit = nil
    }

    private func removeTempIngredient(_ ingredient: TempIngredient) {
        withAnimation {
            tempIngredients.removeAll { $0.id == ingredient.id }
        }
    }

    private func validateAndSave() {
        guard !title.isEmpty else {
            validationMessage = NSLocalizedString(
                "Please enter a recipe title.", comment: "Validation error message")
            showingValidationAlert = true
            return
        }
        guard !tempIngredients.isEmpty else {
            validationMessage = NSLocalizedString(
                "Please add at least one ingredient.", comment: "Validation error message")
            showingValidationAlert = true
            return
        }
        saveRecipe()
    }

    private func saveRecipe() {
        isSaving = true
        do {
            let newRecipe = Recipe(title: title, details: details)
            for temp in tempIngredients {
                newRecipe.ingredients.append(
                    Ingredient(name: temp.name, quantity: temp.quantity, unit: temp.unit))
            }
            modelContext.insert(newRecipe)
            try modelContext.save()
            dismiss()
        } catch {
            validationMessage = String(
                format: NSLocalizedString(
                    "Error saving recipe: %@", comment: "Error saving recipe message"),
                error.localizedDescription)
            showingValidationAlert = true
        }
        isSaving = false
    }
}

#Preview {
    AddRecipeView()
}
