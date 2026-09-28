import SwiftUI

struct TempIngredient: Identifiable {
    let id = UUID()
    let name: String
    let quantity: Double?
    let unit: Unit?
    let group: String?
}

struct TempStep: Identifiable {
    let id = UUID()
    let instruction: String
    let type: StepType
    let duration: TimeInterval?
}

struct AddRecipeView: View {
    @EnvironmentObject private var auth: UserAuthService

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var details: String = ""

    @State private var tempIngredients: [TempIngredient] = []
    @State private var ingredientName: String = ""
    @State private var ingredientQuantity: String = ""
    @State private var ingredientUnit: Unit? = nil

    @State private var editingTempIngredient: TempIngredient? = nil

    @State private var tempSteps: [TempStep] = []
    @State private var stepInstruction: String = ""
    @State private var stepType: StepType = .cooking
    @State private var stepDuration: TimeInterval? = nil

    @State private var seasonality: Seasonality? = nil
    @State private var selectedMealTypes: Set<MealType> = []
    @State private var tags: [String] = []

    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @State private var showingDiscardAlert = false
    @State private var isSaving = false
    @State private var toastMessages: [ToastMessage] = []

    @FocusState private var focusedField: String?

    var body: some View {
        NavigationStack {
            Form {
                RecipeTitleDetailsSection(
                    title: $title,
                    details: $details,
                    focusedField: $focusedField
                )

                // Seasonality Section
                Section(
                    header: Text(
                        NSLocalizedString("Seasonality", comment: "Section header for seasonality"))
                ) {
                    Picker(
                        NSLocalizedString("Season", comment: "Seasonality picker label"),
                        selection: $seasonality
                    ) {
                        Text(NSLocalizedString("None", comment: "No seasonality selected"))
                            .tag(Seasonality?.none)
                        ForEach(Seasonality.allCases, id: \.self) { season in
                            Text(season.displayName).tag(season as Seasonality?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Meal Types Section
                Section(
                    header: Text(
                        NSLocalizedString("Meal Types", comment: "Section header for meal types"))
                ) {
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        Toggle(
                            mealType.displayName,
                            isOn: Binding(
                                get: { selectedMealTypes.contains(mealType) },
                                set: { isOn in
                                    if isOn {
                                        selectedMealTypes.insert(mealType)
                                    } else {
                                        selectedMealTypes.remove(mealType)
                                    }
                                }
                            )
                        )
                    }
                }

                MultiSelector(
                    title: NSLocalizedString("Tags", comment: "Section header for tags"),
                    placeholder: NSLocalizedString("Add tag", comment: "Add tag placeholder"),
                    items: Array<SelectorEntry>.from(tags),
                    onAdd: { newTag in
                        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
                            withAnimation {
                                tags.append(trimmedTag)
                            }
                        }
                    },
                    onRemove: { tagEntry in
                        withAnimation {
                            tags.removeAll { $0 == tagEntry.name }
                        }
                    }
                )

                IngredientsSection(
                    header: NSLocalizedString(
                        "Ingredients", comment: "Section header for ingredients"),
                    ingredients: tempIngredients,
                    moveHandler: moveTempIngredient,
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
                    groupText: { $0.group },
                    ingredientName: $ingredientName,
                    ingredientQuantity: $ingredientQuantity,
                    ingredientUnit: $ingredientUnit,
                    onAdd: addTempIngredient,
                    onEdit: { ingredient in
                        editingTempIngredient = ingredient
                    }
                )
                .focused($focusedField, equals: "ingredients")
                #if os(iOS)
                    .environment(\.editMode, .constant(.active))
                #endif

                StepsSection(
                    header: NSLocalizedString("Steps", comment: "Section header for steps"),
                    steps: tempSteps,
                    moveHandler: moveTempStep,
                    removeHandler: removeTempStep,
                    typeText: { $0.type.displayName },
                    durationText: { step in
                        guard let duration = step.duration else { return "" }
                        return String(format: "%.0f min", duration / 60)
                    },
                    instructionText: { $0.instruction },
                    instruction: $stepInstruction,
                    type: $stepType,
                    duration: $stepDuration,
                    onAdd: addTempStep
                )
                .focused($focusedField, equals: "steps")
                #if os(iOS)
                    .environment(\.editMode, .constant(.active))
                #endif
            }
            .navigationTitle(
                NSLocalizedString("Add Recipe", comment: "Navigation title for add recipe view")
            )
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                            if !title.isEmpty || !details.isEmpty || !tempIngredients.isEmpty
                                || !tempSteps.isEmpty || seasonality != nil
                                || !selectedMealTypes.isEmpty || !tags.isEmpty
                            {
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
            .sheet(item: $editingTempIngredient) { tempIngredient in
                IngredientEditSheet(
                    name: tempIngredient.name,
                    quantityText: tempIngredient.quantity.map {
                        NumberFormatter.localizedString(from: NSNumber(value: $0), number: .decimal)
                    } ?? "",
                    unit: tempIngredient.unit,
                    onSave: { name, quantity, unit in
                        if let index = tempIngredients.firstIndex(where: {
                            $0.id == tempIngredient.id
                        }) {
                            tempIngredients[index] = TempIngredient(
                                name: name,
                                quantity: quantity,
                                unit: unit,
                                group: tempIngredient.group
                            )
                        }
                    }
                )
            }
            .toast(messages: $toastMessages)
        }
    }

    // MARK: - Private Methods

    private func addTempIngredient() {
        guard !ingredientName.isEmpty else {
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .error)
            validationMessage = NSLocalizedString(
                "Please enter an ingredient name.", comment: "Validation error message")
            showingValidationAlert = true
            return
        }

        let name: String
        let quantity: Double?
        let unit: Unit?

        // If quantity/unit fields are empty, try smart parsing from the name field
        if ingredientQuantity.isEmpty && ingredientUnit == nil {
            let parsed = IngredientParser.parse(ingredientName)
            name = parsed.name
            quantity = parsed.quantity
            unit = parsed.unit
        } else {
            name = ingredientName
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            quantity = numberFormatter.number(from: ingredientQuantity)?.doubleValue
            unit = ingredientUnit
        }

        let newIngredient = TempIngredient(
            name: name,
            quantity: quantity,
            unit: unit,
            group: nil
        )

        withAnimation {
            tempIngredients.append(newIngredient)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }

        // Reset the input fields.
        ingredientName = ""
        ingredientQuantity = ""
        ingredientUnit = nil
    }

    private func removeTempIngredient(_ ingredient: TempIngredient) {
        guard let index = tempIngredients.firstIndex(where: { $0.id == ingredient.id }) else {
            return
        }
        withAnimation {
            tempIngredients.remove(at: index)
        }

        let toastId = UUID()
        let toast = ToastMessage(
            id: toastId,
            message: String(
                format: NSLocalizedString(
                    "%@ deleted", comment: "Toast message for deleting ingredient"),
                ingredient.name
            ),
            undoAction: { [self] in
                withAnimation {
                    let insertIndex = min(index, self.tempIngredients.count)
                    self.tempIngredients.insert(ingredient, at: insertIndex)
                    self.toastMessages.removeAll { $0.id == toastId }
                    HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
                }
            }
        )
        toastMessages.append(toast)
    }

    private func moveTempIngredient(from source: IndexSet, to destination: Int) {
        tempIngredients.move(fromOffsets: source, toOffset: destination)
    }

    private func addTempStep() {
        guard !stepInstruction.isEmpty else {
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .error)
            validationMessage = NSLocalizedString(
                "Please enter step instructions.",
                comment: "Validation error message")
            showingValidationAlert = true
            return
        }

        let newStep = TempStep(
            instruction: stepInstruction,
            type: stepType,
            duration: stepDuration
        )

        withAnimation {
            tempSteps.append(newStep)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
        }

        // Reset the input fields
        stepInstruction = ""
        stepType = .cooking
        stepDuration = nil
    }

    private func removeTempStep(_ step: TempStep) {
        guard let index = tempSteps.firstIndex(where: { $0.id == step.id }) else { return }
        withAnimation {
            tempSteps.remove(at: index)
        }

        let toastId = UUID()
        let toast = ToastMessage(
            id: toastId,
            message: String(
                format: NSLocalizedString(
                    "Step %d deleted", comment: "Toast message for deleting step"),
                index + 1
            ),
            undoAction: { [self] in
                withAnimation {
                    let insertIndex = min(index, self.tempSteps.count)
                    self.tempSteps.insert(step, at: insertIndex)
                    self.toastMessages.removeAll { $0.id == toastId }
                    HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
                }
            }
        )
        toastMessages.append(toast)
    }

    private func moveTempStep(from source: IndexSet, to destination: Int) {
        tempSteps.move(fromOffsets: source, toOffset: destination)
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
            guard let currentUser = auth.currentUser else { return }

            let newRecipe = Recipe(title: title, details: details, owner: currentUser)

            // Set new fields
            newRecipe.setSeasonality(seasonality, currentUser: currentUser)
            newRecipe.setMealTypes(Array(selectedMealTypes), currentUser: currentUser)
            newRecipe.setTags(tags, currentUser: currentUser)

            // Save ingredients
            for (index, temp) in tempIngredients.enumerated() {
                let ingredient = Ingredient(
                    name: temp.name,
                    order: index + 1,
                    quantity: temp.quantity,
                    unit: temp.unit,
                    group: temp.group
                )
                newRecipe.ingredients.append(ingredient)
            }

            // Save steps
            for (index, temp) in tempSteps.enumerated() {
                let step = RecipeStep(
                    order: index + 1,
                    instruction: temp.instruction,
                    type: temp.type,
                    duration: temp.duration
                )
                newRecipe.steps.append(step)
            }

            modelContext.insert(newRecipe)
            try modelContext.save()
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)
            dismiss()
        } catch {
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .error)
            validationMessage = String(
                format: NSLocalizedString(
                    "Error saving recipe: %@",
                    comment: "Error saving recipe message"
                ),
                error.localizedDescription
            )
            showingValidationAlert = true
        }
        isSaving = false
    }

}

#Preview {
    AddRecipeView()
}
