import SwiftUI

struct TempIngredient: Identifiable {
    let id = UUID()
    let name: String
    let quantity: Double?
    let unit: Unit?
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

    @State private var tempSteps: [TempStep] = []
    @State private var stepInstruction: String = ""
    @State private var stepType: StepType = .cooking
    @State private var stepDuration: TimeInterval? = nil

    @State private var seasonality: Seasonality? = nil
    @State private var selectedMealTypes: Set<MealType> = []
    @State private var tags: [String] = []
    @State private var newTag: String = ""

    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @State private var showingDiscardAlert = false
    @State private var isSaving = false

    @FocusState private var focusedField: String?

    var body: some View {
        NavigationView {
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
                        HStack {
                            Text(mealType.displayName)
                            Spacer()
                            if selectedMealTypes.contains(mealType) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedMealTypes.contains(mealType) {
                                selectedMealTypes.remove(mealType)
                            } else {
                                selectedMealTypes.insert(mealType)
                            }
                        }
                    }
                }

                // Tags Section
                Section(
                    header: Text(NSLocalizedString("Tags", comment: "Section header for tags"))
                ) {
                    if !tags.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                        .font(.caption)
                                    Button(action: {
                                        withAnimation {
                                            tags.removeAll { $0 == tag }
                                        }
                                    }) {
                                        Image(systemName: "xmark")
                                            .font(.caption2)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.1))
                                .foregroundColor(.accentColor)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    HStack {
                        TextField(
                            NSLocalizedString("Add tag", comment: "Add tag placeholder"),
                            text: $newTag
                        )
                        .onSubmit {
                            addTag()
                        }

                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                        .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

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
                    ingredientName: $ingredientName,
                    ingredientQuantity: $ingredientQuantity,
                    ingredientUnit: $ingredientUnit,
                    onAdd: addTempIngredient
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

                ToolbarItem(placement: .keyboard) {
                    Button(NSLocalizedString("Done", comment: "Done button")) {
                        focusedField = nil
                    }
                }
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
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .error)
            validationMessage = NSLocalizedString(
                "Please enter an ingredient name.", comment: "Validation error message")
            showingValidationAlert = true
            return
        }

        // Convert the quantity text to a Double; if conversion fails, it ends up as nil.
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let quantity = numberFormatter.number(from: ingredientQuantity)?.doubleValue
        let newIngredient = TempIngredient(
            name: ingredientName,
            quantity: quantity,
            unit: ingredientUnit
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
        withAnimation {
            tempIngredients.removeAll { $0.id == ingredient.id }
        }
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
        withAnimation {
            tempSteps.removeAll { $0.id == step.id }
        }
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
                    unit: temp.unit
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

    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty && !tags.contains(trimmedTag) else { return }

        withAnimation {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
}

#Preview {
    AddRecipeView()
}
