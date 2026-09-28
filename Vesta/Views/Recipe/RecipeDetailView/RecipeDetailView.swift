import SwiftData
import SwiftUI

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: UserAuthService
    @State private var viewModel: RecipeDetailViewModel

    @State private var ingredientName: String = ""
    @State private var ingredientQuantity: String = ""
    @State private var ingredientUnit: Unit? = nil

    @State private var editingIngredient: Ingredient? = nil

    @State private var stepInstruction: String = ""
    @State private var stepType: StepType = .cooking
    @State private var stepDuration: TimeInterval? = nil

    @State private var showingValidationAlert = false
    @State private var validationMessage = ""

    @FocusState private var focusedField: String?

    init(recipe: Recipe) {
        _viewModel = State(initialValue: RecipeDetailViewModel(recipe: recipe))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        Form {
            RecipeTitleDetailsSection(
                title: $viewModel.recipe.title,
                details: $viewModel.recipe.details,
                focusedField: $focusedField
            )

            // Seasonality Section
            Section(
                header: Text(
                    NSLocalizedString("Seasonality", comment: "Section header for seasonality"))
            ) {
                Picker(
                    NSLocalizedString("Season", comment: "Seasonality picker label"),
                    selection: Binding(
                        get: { viewModel.recipe.seasonality },
                        set: { newValue in
                            guard let currentUser = auth.currentUser else { return }
                            viewModel.recipe.setSeasonality(newValue, currentUser: currentUser)
                        }
                    )
                ) {
                    Text(NSLocalizedString("None", comment: "No seasonality selected"))
                        .tag(Seasonality?.none)
                    ForEach(Seasonality.allCases, id: \.self) { season in
                        Text(season.displayName).tag(season as Seasonality?)
                    }
                }
                .pickerStyle(.menu)
            }

            // Servings & Difficulty Section
            Section(
                header: Text(
                    NSLocalizedString(
                        "Servings & Difficulty",
                        comment: "Section header for servings and difficulty"))
            ) {
                Stepper(
                    value: Binding(
                        get: { viewModel.recipe.servings },
                        set: { viewModel.setServings($0) }
                    ),
                    in: 1...99
                ) {
                    HStack {
                        Text(NSLocalizedString("Servings", comment: "Servings label"))
                        Spacer()
                        Text("\(viewModel.recipe.servings)")
                            .foregroundColor(.secondary)
                    }
                }

                Picker(
                    NSLocalizedString("Difficulty", comment: "Difficulty picker label"),
                    selection: Binding(
                        get: { viewModel.recipe.difficulty },
                        set: { viewModel.setDifficulty($0) }
                    )
                ) {
                    Text(NSLocalizedString("None", comment: "No difficulty selected"))
                        .tag(Difficulty?.none)
                    ForEach(Difficulty.allCases, id: \.self) { difficulty in
                        Text(difficulty.displayName).tag(difficulty as Difficulty?)
                    }
                }
                .pickerStyle(.menu)
            }

            // Source URL Section
            Section(
                header: Text(
                    NSLocalizedString("Source", comment: "Section header for source URL"))
            ) {
                TextField(
                    NSLocalizedString("Recipe URL (optional)", comment: "Source URL placeholder"),
                    text: Binding(
                        get: { viewModel.recipe.sourceURL ?? "" },
                        set: { viewModel.setSourceURL($0) }
                    )
                )
                .keyboardType(.URL)
                .autocapitalization(.none)
                .autocorrectionDisabled()
            }

            // Notes Section
            Section(
                header: Text(
                    NSLocalizedString("Notes", comment: "Section header for personal notes"))
            ) {
                TextEditor(
                    text: Binding(
                        get: { viewModel.recipe.notes },
                        set: { viewModel.setNotes($0) }
                    )
                )
                .frame(minHeight: 80)
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
                            get: { viewModel.recipe.mealTypes.contains(mealType) },
                            set: { isOn in
                                guard let currentUser = auth.currentUser else { return }
                                var newMealTypes = viewModel.recipe.mealTypes
                                if isOn {
                                    if !newMealTypes.contains(mealType) {
                                        newMealTypes.append(mealType)
                                    }
                                } else {
                                    newMealTypes.removeAll { $0 == mealType }
                                }
                                viewModel.recipe.setMealTypes(
                                    newMealTypes, currentUser: currentUser)
                            }
                        )
                    )
                }
            }

            MultiSelector(
                title: NSLocalizedString("Tags", comment: "Section header for tags"),
                placeholder: NSLocalizedString("Add tag", comment: "Add tag placeholder"),
                items: Array<SelectorEntry>.from(viewModel.recipe.tags),
                onAdd: { newTag in
                    let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedTag.isEmpty && !viewModel.recipe.tags.contains(trimmedTag) {
                        guard let currentUser = auth.currentUser else { return }
                        withAnimation {
                            viewModel.recipe.addTag(trimmedTag, currentUser: currentUser)
                        }
                    }
                },
                onRemove: { tagEntry in
                    viewModel.removeTag(tagEntry.name)
                }
            )

            DurationSectionView(recipe: viewModel.recipe)

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
                groupText: { $0.group },
                ingredientName: $ingredientName,
                ingredientQuantity: $ingredientQuantity,
                ingredientUnit: $ingredientUnit,
                onAdd: addIngredient,
                onEdit: { ingredient in
                    editingIngredient = ingredient
                }
            )
            .focused($focusedField, equals: "ingredients")
            #if os(iOS)
                .environment(\.editMode, .constant(.active))
            #endif

            StepsSection(
                header: NSLocalizedString("Steps", comment: "Section header for steps"),
                steps: viewModel.recipe.sortedSteps,
                moveHandler: viewModel.moveStep,
                removeHandler: viewModel.removeStep,
                typeText: { $0.type.displayName },
                durationText: { step in
                    guard let duration = step.duration else { return "" }
                    return String(format: "%.0f min", duration / 60)
                },
                instructionText: { $0.instruction },
                instruction: $stepInstruction,
                type: $stepType,
                duration: $stepDuration,
                onAdd: addStep
            )
            .focused($focusedField, equals: "steps")
            #if os(iOS)
                .environment(\.editMode, .constant(.active))
            #endif
        }
        .scrollDismissesKeyboard(.interactively)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                        Task {
                            viewModel.cancel()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.save()
                    }
                }
            #endif

        }
        .alert(
            NSLocalizedString("Validation Error", comment: "Validation error alert title"),
            isPresented: $viewModel.showingValidationAlert
        ) {
            Button(
                NSLocalizedString("OK", comment: "Validation error accept button"),
                role: .cancel
            ) {}
        } message: {
            Text(viewModel.validationMessage)
        }
        .onAppear {
            viewModel.configureEnvironment(modelContext, dismiss, auth)
        }
        .sheet(item: $editingIngredient) { ingredient in
            IngredientEditSheet(
                name: ingredient.name,
                quantityText: ingredient.quantity.map {
                    NumberFormatter.localizedString(from: NSNumber(value: $0), number: .decimal)
                } ?? "",
                unit: ingredient.unit,
                onSave: { name, quantity, unit in
                    viewModel.updateIngredient(
                        ingredient, name: name, quantity: quantity, unit: unit)
                }
            )
        }
        .toast(messages: $viewModel.toastMessages)

    }

    // MARK: - Private Methods

    private func addIngredient() {
        guard !ingredientName.isEmpty else {
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

        viewModel.addIngredient(
            name: name, quantity: quantity, unit: unit, group: nil)

        // Reset the input fields.
        ingredientName = ""
        ingredientQuantity = ""
        ingredientUnit = nil
    }

    private func addStep() {
        guard !stepInstruction.isEmpty else {
            validationMessage = NSLocalizedString(
                "Please enter step instructions.",
                comment: "Validation error message")
            showingValidationAlert = true
            return
        }

        viewModel.addStep(
            instruction: stepInstruction,
            type: stepType,
            duration: stepDuration
        )

        // Reset the input fields
        stepInstruction = ""
        stepType = .cooking
        stepDuration = nil
    }

}

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext

        let recipe = Fixtures.bolognese()
        context.insert(recipe)
        return RecipeDetailView(recipe: recipe)
            .modelContainer(container)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
