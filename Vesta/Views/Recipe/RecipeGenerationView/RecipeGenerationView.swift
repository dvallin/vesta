import SwiftData
import SwiftUI

struct RecipeGenerationView: View {
    @EnvironmentObject private var auth: UserAuthService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: RecipeGenerationViewModel

    init(recipe: Recipe) {
        _viewModel = StateObject(wrappedValue: RecipeGenerationViewModel(recipe: recipe))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Recipe Preview

                    recipePreview

                    Divider()

                    // MARK: - Accept/Discard Buttons (Phase 2)

                    if viewModel.hasGeneratedResult {
                        acceptDiscardButtons

                        Divider()
                    }

                    // MARK: - Actions Section

                    actionsSection
                }
            }
            .navigationTitle(NSLocalizedString("AI Recipe Assistant", comment: "Navigation title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert(
                NSLocalizedString("Error", comment: "Error alert title"),
                isPresented: $viewModel.showingError
            ) {
                Button(NSLocalizedString("OK", comment: "OK button"), role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear {
                viewModel.configureEnvironment(modelContext, dismiss, auth)
            }
        }
    }
}

// MARK: - Toolbar

extension RecipeGenerationView {
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(NSLocalizedString("Close", comment: "Close button")) {
                viewModel.dismissView()
            }
        }
    }
}

// MARK: - Recipe Preview

extension RecipeGenerationView {
    @ViewBuilder
    private var recipePreview: some View {
        if viewModel.hasGeneratedResult, let generated = viewModel.generatedSnapshot {
            recipeContent(
                for: generated,
                label: NSLocalizedString("AI Generated", comment: "Generated recipe label")
            )
        } else {
            recipeContent(
                for: viewModel.originalSnapshot,
                label: NSLocalizedString("Current Recipe", comment: "Current recipe label")
            )
        }
    }

    @ViewBuilder
    private func recipeContent<R: RecipeDisplayable>(for recipe: R, label: String?) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let label = label {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .padding(.horizontal)
            }

            // Title
            Text(recipe.title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            // Details
            if !recipe.details.isEmpty {
                Text(recipe.details)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            // Ingredients
            if !recipe.sortedIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Ingredients", comment: "Section header"))
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(recipe.sortedIngredients) { ingredient in
                        HStack {
                            Text("•")
                            Text(ingredient.name)
                            Spacer()
                            if let qty = ingredient.quantity {
                                Text(
                                    NumberFormatter.localizedString(
                                        from: NSNumber(value: qty), number: .decimal)
                                        + " " + (ingredient.unit?.displayName ?? "")
                                )
                                .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }

            // Steps
            if !recipe.sortedSteps.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Steps", comment: "Section header"))
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(Array(recipe.sortedSteps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.accentColor)
                                .frame(width: 24, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.instruction)
                                    .font(.subheadline)
                                if let duration = step.duration {
                                    Text(DateUtils.formattedDuration(duration))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Actions Section

extension RecipeGenerationView {
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Transform", comment: "Section header"))
                .font(.headline)
                .padding(.horizontal)

            // Icon-only action toggles
            HStack(spacing: 8) {
                ForEach(RecipeAction.presets) { action in
                    actionIcon(for: action)
                }
            }
            .padding(.horizontal)

            // Selected action labels
            if !viewModel.selectedActions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(viewModel.selectedActions).sorted(by: { $0.id < $1.id })) {
                            action in
                            Text(action.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.1))
                                .foregroundColor(.accentColor)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Custom instruction — single-line with submit
            HStack(spacing: 8) {
                TextField(
                    NSLocalizedString(
                        "e.g., Make it Korean style",
                        comment: "Custom prompt placeholder"
                    ),
                    text: $viewModel.customPrompt
                )
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .onSubmit {
                    viewModel.generate()
                }

                if !viewModel.customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        viewModel.generate()
                    } label: {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal)
            .animation(.easeInOut(duration: 0.2), value: viewModel.customPrompt)

            // Generate button
            generateButton
                .padding(.horizontal)
                .padding(.bottom)
        }
        .padding(.vertical)
    }

    private func actionIcon(for action: RecipeAction) -> some View {
        let isSelected = viewModel.isActionSelected(action)
        return Button {
            viewModel.toggleAction(action)
            HapticFeedbackManager.shared.generateImpactFeedback(style: .light)
        } label: {
            Image(systemName: action.systemImage)
                .font(.body)
                .frame(width: 40, height: 40)
                .background(isSelected ? Color.accentColor : Color.clear)
                .foregroundColor(isSelected ? .white : .accentColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Generate Button

extension RecipeGenerationView {
    @ViewBuilder
    private var generateButton: some View {
        Button {
            viewModel.generate()
        } label: {
            HStack {
                if viewModel.generationState == .generating {
                    ProgressView()
                        .tint(.white)
                    Text(NSLocalizedString("Generating...", comment: "Generate button loading"))
                } else if viewModel.hasGeneratedResult {
                    Image(systemName: "sparkles")
                    Text(NSLocalizedString("Regenerate", comment: "Regenerate button"))
                } else {
                    Image(systemName: "sparkles")
                    Text(NSLocalizedString("Generate", comment: "Generate button"))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.canGenerate ? Color.accentColor : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!viewModel.canGenerate)
    }
}

// MARK: - Accept / Discard Buttons

extension RecipeGenerationView {
    @ViewBuilder
    private var acceptDiscardButtons: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.acceptChanges()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text(NSLocalizedString("Accept Changes", comment: "Accept button"))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.generationState == .applying)

            Button {
                viewModel.discardChanges()
            } label: {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text(NSLocalizedString("Discard", comment: "Discard button"))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.red)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red, lineWidth: 1)
                )
            }
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    do {
        let container = try ModelContainerHelper.createModelContainer(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let recipe = Fixtures.bolognese()
        context.insert(recipe)
        return RecipeGenerationView(recipe: recipe)
            .modelContainer(container)
    } catch {
        return Text("Failed to create ModelContainer")
    }
}
