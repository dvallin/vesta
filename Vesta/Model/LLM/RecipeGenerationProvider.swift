import Foundation

// MARK: - Recipe Generation Provider Protocol

protocol RecipeGenerationProvider {
    func generate(
        original: RecipeSnapshot,
        current: RecipeSnapshot,
        actions: [RecipeAction]
    ) async throws -> RecipeSnapshot
}

// MARK: - Recipe Generation Error

enum RecipeGenerationError: LocalizedError {
    case noActionsProvided
    case generationFailed(underlying: Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noActionsProvided:
            return NSLocalizedString(
                "Please select at least one action.", comment: "No actions error")
        case .generationFailed(let underlying):
            return String(
                format: NSLocalizedString(
                    "Generation failed: %@", comment: "Generation failed error"),
                underlying.localizedDescription)
        case .invalidResponse:
            return NSLocalizedString(
                "Received an invalid response. Please try again.", comment: "Invalid response error"
            )
        }
    }
}
