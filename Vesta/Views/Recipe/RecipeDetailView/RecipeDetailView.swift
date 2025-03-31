import SwiftData
import SwiftUI

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: RecipeDetailViewModel

    @State private var ingredientName: String = ""
    @State private var ingredientQuantity: String = ""
    @State private var ingredientUnit: Unit? = nil

    @State private var stepInstruction: String = ""
    @State private var stepType: StepType = .cooking
    @State private var stepDuration: TimeInterval? = nil

    @State private var showingValidationAlert = false
    @State private var validationMessage = ""

    @FocusState private var focusedField: String?

    init(recipe: Recipe) {
        _viewModel = StateObject(wrappedValue: RecipeDetailViewModel(recipe: recipe))
    }

    var body: some View {
        Form {
            RecipeTitleDetailsSection(
                title: $viewModel.recipe.title,
                details: $viewModel.recipe.details,
                focusedField: $focusedField
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
                ingredientName: $ingredientName,
                ingredientQuantity: $ingredientQuantity,
                ingredientUnit: $ingredientUnit,
                onAdd: addIngredient
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

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let quantity = numberFormatter.number(from: ingredientQuantity)?.doubleValue
        viewModel.addIngredient(name: ingredientName, quantity: quantity, unit: ingredientUnit)

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

        let recipe = Fixtures.createRecipe()
        context.insert(recipe)
        return RecipeDetailView(recipe: recipe)
            .modelContainer(container)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
