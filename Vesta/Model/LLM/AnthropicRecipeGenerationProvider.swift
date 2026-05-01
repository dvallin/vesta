import Foundation
import OSLog

#if canImport(SwiftAnthropic)

    import SwiftAnthropic

    class AnthropicRecipeGenerationProvider: RecipeGenerationProvider {
        private let apiKey: String
        private let logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "com.vesta",
            category: "AnthropicRecipeGeneration"
        )

        init(apiKey: String) {
            self.apiKey = apiKey
        }

        func generate(
            original: RecipeSnapshot,
            current: RecipeSnapshot,
            actions: [RecipeAction]
        ) async throws -> RecipeSnapshot {
            guard !actions.isEmpty else {
                throw RecipeGenerationError.noActionsProvided
            }

            let service = AnthropicServiceFactory.service(apiKey: apiKey, betaHeaders: nil)

            let systemPrompt = buildSystemPrompt()
            let userPrompt = buildUserPrompt(original: original, current: current, actions: actions)

            logger.debug("Generating recipe with \(actions.count) action(s)")

            let message = MessageParameter.Message(role: .user, content: .text(userPrompt))
            let parameters = MessageParameter(
                model: .other("claude-haiku-4-5"),
                messages: [message],
                maxTokens: 2048,
                system: .list([
                    MessageParameter.Cache(
                        text: systemPrompt,
                        cacheControl: MessageParameter.CacheControl(type: .ephemeral)
                    )
                ]),
                temperature: 0.7
            )

            do {
                let response = try await service.createMessage(parameters)
                let snapshot = try parseResponse(response)
                logger.info("Successfully generated recipe: \(snapshot.title)")
                return snapshot
            } catch let error as RecipeGenerationError {
                logger.error("Recipe generation error: \(error.localizedDescription)")
                throw error
            } catch {
                logger.error("Unexpected error during generation: \(error.localizedDescription)")
                throw RecipeGenerationError.generationFailed(underlying: error)
            }
        }

        // MARK: - System Prompt

        private func buildSystemPrompt() -> String {
            let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
            let languageName =
                Locale.current.localizedString(forLanguageCode: languageCode) ?? "English"

            return """
                Recipe assistant. Transform recipes per user instructions. All text in \(languageName) (\(languageCode)).

                Respond with ONLY valid JSON, no markdown or fences:
                {"title":"str","details":"str","ingredients":[{"name":"str","order":int,"quantity":num|null,"unit":"teaspoon|tablespoon|cup|milliliter|liter|gram|kilogram|ounce|pound|piece"|null}],"steps":[{"order":int,"instruction":"str","type":"preparation|cooking|maturing","duration":seconds|null}],"seasonality":"spring|summer|autumn|winter|yearRound"|null,"mealTypes":["breakfast|lunch|dinner"],"tags":["str"]}

                Rules: Preserve recipe identity. Respect existing ingredients unless action requires changes. Normalize names. Clear actionable steps. Sequential order from 1. Duration in seconds. quantity/unit can be null.
                """
        }

        // MARK: - User Prompt

        private func buildUserPrompt(
            original: RecipeSnapshot, current: RecipeSnapshot, actions: [RecipeAction]
        ) -> String {
            let currentJSON = encodeToJSON(current)
            let actionDescriptions = actions.map { "- \(describeAction($0))" }.joined(
                separator: "\n")

            // Only include original recipe if it differs from current (avoids duplicate tokens)
            if original != current {
                let originalJSON = encodeToJSON(original)
                return """
                    Original:
                    \(originalJSON)

                    Current (transform this):
                    \(currentJSON)

                    Apply:
                    \(actionDescriptions)
                    """
            }

            return """
                Recipe:
                \(currentJSON)

                Apply:
                \(actionDescriptions)
                """
        }

        // MARK: - Action Descriptions

        private func describeAction(_ action: RecipeAction) -> String {
            switch action {
            case .complete:
                return
                    "Complete Recipe: Fill in any missing details. Add a description if empty. Add cooking instructions if missing or incomplete. Add reasonable ingredients if the recipe seems incomplete. Normalize ingredient names. Add appropriate tags."
            case .makeVegan:
                return
                    "Make Vegan: Replace ALL animal products (meat, dairy, eggs, honey) with plant-based alternatives. Update instructions accordingly."
            case .makeVegetarian:
                return
                    "Make Vegetarian: Replace all meat and fish with vegetarian alternatives. Dairy and eggs are acceptable."
            case .makeKidFriendly:
                return
                    "Make Kid-Friendly: Remove or reduce spicy ingredients. Simplify complex flavors. Keep it approachable for children."
            case .makeFaster:
                return
                    "Make Faster: Reduce cooking times. Suggest shortcuts. Remove or shorten unnecessary waiting/maturing steps."
            case .simplify:
                return
                    "Simplify: Reduce the number of ingredients and steps. Use common, easy-to-find ingredients. Make instructions straightforward."
            case .makeMoreDetailed:
                return
                    "Add More Detail: Expand instructions with specific temperatures, techniques, and timing. Add helpful tips."
            case .rewrite:
                return
                    "Rewrite & Translate: Completely rewrite the recipe in the user's preferred language. Normalize all ingredient names to standard culinary terms in that language. Improve the writing quality of all instructions and the description. Ensure consistent style and tone throughout."
            case .custom(let prompt):
                return "Custom instruction: \(prompt)"
            }
        }

        // MARK: - JSON Encoding

        private func encodeToJSON(_ snapshot: RecipeSnapshot) -> String {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            guard let data = try? encoder.encode(snapshot),
                let json = String(data: data, encoding: .utf8)
            else {
                logger.warning("Failed to encode RecipeSnapshot to JSON")
                return "{}"
            }
            return json
        }

        // MARK: - Response Parsing

        private func parseResponse(_ response: MessageResponse) throws -> RecipeSnapshot {
            guard
                let textContent = response.content.first(where: {
                    if case .text = $0 { return true }
                    return false
                }), case .text(let text, _) = textContent
            else {
                logger.error("No text content found in response")
                throw RecipeGenerationError.invalidResponse
            }

            let jsonString = extractJSON(from: text)

            guard let data = jsonString.data(using: .utf8) else {
                logger.error("Failed to convert extracted JSON to data")
                throw RecipeGenerationError.invalidResponse
            }

            do {
                return try JSONDecoder().decode(RecipeSnapshot.self, from: data)
            } catch {
                logger.error(
                    "Failed to decode RecipeSnapshot from JSON: \(error.localizedDescription)")
                throw RecipeGenerationError.invalidResponse
            }
        }

        private func extractJSON(from text: String) -> String {
            var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

            // Remove markdown code fences if present
            if cleaned.hasPrefix("```json") {
                cleaned = String(cleaned.dropFirst(7))
            } else if cleaned.hasPrefix("```") {
                cleaned = String(cleaned.dropFirst(3))
            }
            if cleaned.hasSuffix("```") {
                cleaned = String(cleaned.dropLast(3))
            }
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

            // Find the JSON object boundaries
            if let start = cleaned.firstIndex(of: "{"),
                let end = cleaned.lastIndex(of: "}")
            {
                return String(cleaned[start...end])
            }

            return cleaned
        }
    }

#else

    /// Fallback when SwiftAnthropic is not available.
    /// This allows the project to compile without the package linked,
    /// falling back to MockRecipeGenerationProvider at runtime.
    class AnthropicRecipeGenerationProvider: RecipeGenerationProvider {
        init(apiKey: String) {}

        func generate(
            original: RecipeSnapshot,
            current: RecipeSnapshot,
            actions: [RecipeAction]
        ) async throws -> RecipeSnapshot {
            throw RecipeGenerationError.generationFailed(
                underlying: NSError(
                    domain: "AnthropicRecipeGeneration",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "SwiftAnthropic package is not linked. Please add it to the target in Xcode."
                    ]
                )
            )
        }
    }

#endif
