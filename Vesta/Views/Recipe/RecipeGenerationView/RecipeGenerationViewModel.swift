import SwiftData
import SwiftUI

enum GenerationState {
    case idle  // Initial state, showing current recipe
    case generating  // LLM call in progress
    case generated  // Result ready, showing generated version
    case applying  // Writing changes to model
}

class RecipeGenerationViewModel: ObservableObject {
    // Environment (configured after init, same pattern as RecipeDetailViewModel)
    private var modelContext: ModelContext?
    private var auth: UserAuthService?
    private var dismiss: DismissAction?

    // The actual Recipe model - only written to on accept
    let recipe: Recipe

    // The generation provider (protocol - allows mock or real)
    private let provider: RecipeGenerationProvider

    // Snapshots
    @Published var originalSnapshot: RecipeSnapshot
    @Published var generatedSnapshot: RecipeSnapshot?

    // UI State
    @Published var generationState: GenerationState = .idle
    @Published var selectedActions: Set<RecipeAction> = [.complete]  // Default to "complete"
    @Published var customPrompt: String = ""
    @Published var errorMessage: String?
    @Published var showingError: Bool = false

    init(recipe: Recipe, provider: RecipeGenerationProvider = MockRecipeGenerationProvider()) {
        self.recipe = recipe
        self.provider = provider
        self.originalSnapshot = RecipeSnapshot(from: recipe)
    }

    func configureEnvironment(
        _ context: ModelContext, _ dismiss: DismissAction, _ auth: UserAuthService
    ) {
        self.modelContext = context
        self.dismiss = dismiss
        self.auth = auth
    }

    // MARK: - Action Management

    func toggleAction(_ action: RecipeAction) {
        if selectedActions.contains(action) {
            selectedActions.remove(action)
        } else {
            selectedActions.insert(action)
        }
    }

    func isActionSelected(_ action: RecipeAction) -> Bool {
        selectedActions.contains(action)
    }

    // Builds the final list of actions to send (preset actions + custom if non-empty)
    var actionsToApply: [RecipeAction] {
        var actions = Array(selectedActions)
        let trimmedPrompt = customPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPrompt.isEmpty {
            actions.append(.custom(prompt: trimmedPrompt))
        }
        return actions
    }

    var canGenerate: Bool {
        !actionsToApply.isEmpty && generationState != .generating
    }

    var hasGeneratedResult: Bool {
        generatedSnapshot != nil && generationState == .generated
    }

    // MARK: - Generation

    @MainActor
    func generate() {
        let actions = actionsToApply
        guard !actions.isEmpty else {
            errorMessage = NSLocalizedString(
                "Please select at least one action or enter a custom prompt.",
                comment: "No actions error"
            )
            showingError = true
            return
        }

        generationState = .generating
        errorMessage = nil

        // Capture the current snapshot (the recipe as it is now)
        let currentSnapshot = RecipeSnapshot(from: recipe)

        Task {
            do {
                let result = try await provider.generate(
                    original: originalSnapshot,
                    current: currentSnapshot,
                    actions: actions
                )
                self.generatedSnapshot = result
                self.generationState = .generated
                HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)
            } catch {
                self.generationState = .idle
                self.errorMessage = error.localizedDescription
                self.showingError = true
                HapticFeedbackManager.shared.generateNotificationFeedback(type: .error)
            }
        }
    }

    // MARK: - Accept / Discard

    @MainActor
    func acceptChanges() {
        guard let generated = generatedSnapshot,
            let currentUser = auth?.currentUser
        else { return }

        generationState = .applying

        generated.apply(to: recipe, currentUser: currentUser)

        do {
            try modelContext?.save()
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)
            dismiss?()
        } catch {
            generationState = .generated
            errorMessage = String(
                format: NSLocalizedString(
                    "Error saving recipe: %@",
                    comment: "Error saving recipe message"
                ),
                error.localizedDescription
            )
            showingError = true
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .error)
        }
    }

    @MainActor
    func discardChanges() {
        generatedSnapshot = nil
        generationState = .idle
        HapticFeedbackManager.shared.generateImpactFeedback(style: .medium)
    }

    @MainActor
    func dismissView() {
        self.dismiss?()
    }
}
