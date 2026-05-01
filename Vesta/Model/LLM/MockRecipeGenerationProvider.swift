import Foundation

class MockRecipeGenerationProvider: RecipeGenerationProvider {
    func generate(
        original: RecipeSnapshot,
        current: RecipeSnapshot,
        actions: [RecipeAction]
    ) async throws -> RecipeSnapshot {
        guard !actions.isEmpty else {
            throw RecipeGenerationError.noActionsProvided
        }

        // Simulate network latency (1–2 seconds)
        try await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...2_000_000_000))

        var result = current

        for action in actions {
            result = applyAction(action, to: result, original: original)
        }

        result = renumber(result)
        return result
    }

    // MARK: - Action Dispatch

    private func applyAction(
        _ action: RecipeAction, to snapshot: RecipeSnapshot, original: RecipeSnapshot
    ) -> RecipeSnapshot {
        switch action {
        case .complete:
            return applyComplete(to: snapshot)
        case .makeVegan:
            return applyMakeVegan(to: snapshot)
        case .makeVegetarian:
            return applyMakeVegetarian(to: snapshot)
        case .makeKidFriendly:
            return applyMakeKidFriendly(to: snapshot)
        case .makeFaster:
            return applyMakeFaster(to: snapshot)
        case .simplify:
            return applySimplify(to: snapshot)
        case .makeMoreDetailed:
            return applyMakeMoreDetailed(to: snapshot)
        case .custom(let prompt):
            return applyCustom(prompt: prompt, to: snapshot)
        }
    }

    // MARK: - Complete

    private func applyComplete(to snapshot: RecipeSnapshot) -> RecipeSnapshot {
        var result = snapshot

        // Add a description if details are empty
        if result.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result.details =
                "A delicious \(result.title) recipe that brings together fresh ingredients and simple techniques for a satisfying meal."
        }

        // Normalize ingredient names (capitalize first letter)
        result.ingredients = result.ingredients.map { ingredient in
            var modified = ingredient
            modified.name =
                ingredient.name.prefix(1).uppercased()
                + ingredient.name.dropFirst()
            return modified
        }

        // Add steps if there are fewer than 2
        if result.steps.count < 2 {
            let nextOrder = (result.steps.map(\.order).max() ?? 0) + 1
            var newSteps = result.steps

            newSteps.append(
                StepSnapshot(
                    order: nextOrder,
                    instruction:
                        "Prepare all ingredients: wash, peel, and chop as needed. Measure out spices and liquids.",
                    type: .preparation,
                    duration: 600
                ))
            newSteps.append(
                StepSnapshot(
                    order: nextOrder + 1,
                    instruction:
                        "Heat a large pan over medium heat. Add oil and wait until it shimmers.",
                    type: .cooking,
                    duration: 120
                ))
            newSteps.append(
                StepSnapshot(
                    order: nextOrder + 2,
                    instruction:
                        "Cook the main ingredients, stirring occasionally, until done to your liking.",
                    type: .cooking,
                    duration: 900
                ))
            newSteps.append(
                StepSnapshot(
                    order: nextOrder + 3,
                    instruction:
                        "Season to taste, plate up, and serve immediately while hot.",
                    type: .cooking,
                    duration: 120
                ))

            result.steps = newSteps
        }

        // Add a tag if tags are empty
        if result.tags.isEmpty {
            result.tags.append("Homemade")
        }

        return result
    }

    // MARK: - Make Vegan

    private func applyMakeVegan(to snapshot: RecipeSnapshot) -> RecipeSnapshot {
        var result = snapshot

        let veganReplacements: [(String, String)] = [
            ("Chicken", "Tofu"),
            ("Beef", "Tempeh"),
            ("Pork", "Tempeh"),
            ("Bacon", "Coconut Bacon"),
            ("Fish", "Jackfruit"),
            ("Milk", "Oat Milk"),
            ("Butter", "Vegan Butter"),
            ("Cheese", "Nutritional Yeast"),
            ("Eggs", "Flax Egg"),
            ("Egg", "Flax Egg"),
            ("Cream", "Coconut Cream"),
            ("Honey", "Maple Syrup"),
        ]

        result.ingredients = result.ingredients.map { ingredient in
            var modified = ingredient
            for (animal, vegan) in veganReplacements {
                if modified.name.localizedCaseInsensitiveContains(animal) {
                    modified.name = modified.name.replacingOccurrences(
                        of: animal,
                        with: vegan,
                        options: .caseInsensitive
                    )
                }
            }
            return modified
        }

        // Update step instructions with the same replacements
        result.steps = result.steps.map { step in
            var modified = step
            for (animal, vegan) in veganReplacements {
                modified.instruction = modified.instruction.replacingOccurrences(
                    of: animal,
                    with: vegan,
                    options: .caseInsensitive
                )
            }
            return modified
        }

        if !result.tags.contains("Vegan") {
            result.tags.append("Vegan")
        }

        return result
    }

    // MARK: - Make Vegetarian

    private func applyMakeVegetarian(to snapshot: RecipeSnapshot) -> RecipeSnapshot {
        var result = snapshot

        let vegetarianReplacements: [(String, String)] = [
            ("Ground Beef", "Lentils"),
            ("Chicken", "Halloumi"),
            ("Beef", "Lentils"),
            ("Pork", "Mushrooms"),
            ("Bacon", "Smoked Tofu"),
            ("Fish", "Paneer"),
        ]

        result.ingredients = result.ingredients.map { ingredient in
            var modified = ingredient
            for (meat, veggie) in vegetarianReplacements {
                if modified.name.localizedCaseInsensitiveContains(meat) {
                    modified.name = modified.name.replacingOccurrences(
                        of: meat,
                        with: veggie,
                        options: .caseInsensitive
                    )
                }
            }
            return modified
        }

        // Update step instructions with the same replacements
        result.steps = result.steps.map { step in
            var modified = step
            for (meat, veggie) in vegetarianReplacements {
                modified.instruction = modified.instruction.replacingOccurrences(
                    of: meat,
                    with: veggie,
                    options: .caseInsensitive
                )
            }
            return modified
        }

        if !result.tags.contains("Vegetarian") {
            result.tags.append("Vegetarian")
        }

        return result
    }

    // MARK: - Make Kid-Friendly

    private func applyMakeKidFriendly(to snapshot: RecipeSnapshot) -> RecipeSnapshot {
        var result = snapshot

        let kidFriendlyReplacements: [(String, String?)] = [
            ("Chili", "Bell Pepper"),
            ("Chilli", "Bell Pepper"),
            ("Hot Sauce", nil),
            ("Cayenne", "Paprika"),
            ("Jalapeño", "Bell Pepper"),
            ("Habanero", nil),
            ("Curry Powder", "Mild Curry Powder"),
            ("Red Pepper Flakes", nil),
        ]

        result.ingredients = result.ingredients.compactMap { ingredient in
            var modified = ingredient
            for (spicy, replacement) in kidFriendlyReplacements {
                if modified.name.localizedCaseInsensitiveContains(spicy) {
                    if let replacement = replacement {
                        modified.name = modified.name.replacingOccurrences(
                            of: spicy,
                            with: replacement,
                            options: .caseInsensitive
                        )
                    } else {
                        // Remove the ingredient entirely
                        return nil
                    }
                }
            }
            return modified
        }

        // Prefix heat-related steps with safety note
        let heatKeywords = ["heat", "boil", "fry", "bake", "roast", "grill", "sauté", "sear"]
        result.steps = result.steps.map { step in
            var modified = step
            let lowercased = modified.instruction.lowercased()
            let involvesHeat = heatKeywords.contains { lowercased.contains($0) }
            if involvesHeat && !modified.instruction.hasPrefix("With adult help: ") {
                modified.instruction = "With adult help: " + modified.instruction
            }
            return modified
        }

        if !result.tags.contains("Kid-Friendly") {
            result.tags.append("Kid-Friendly")
        }

        return result
    }

    // MARK: - Make Faster

    private func applyMakeFaster(to snapshot: RecipeSnapshot) -> RecipeSnapshot {
        var result = snapshot

        result.steps = result.steps.compactMap { step in
            var modified = step

            if modified.type == .maturing {
                // Reduce maturing steps significantly or remove if very long
                if let duration = modified.duration {
                    if duration > 7200 {
                        // Remove very long maturing steps (over 2 hours)
                        return nil
                    } else {
                        modified.duration = duration * 0.25
                    }
                }
            } else if let duration = modified.duration {
                // Reduce other step durations by 30-50%
                let reduction = Double.random(in: 0.5...0.7)
                modified.duration = (duration * reduction).rounded()
            }

            return modified
        }

        if !result.tags.contains("Quick") {
            result.tags.append("Quick")
        }

        return result
    }

    // MARK: - Simplify

    private func applySimplify(to snapshot: RecipeSnapshot) -> RecipeSnapshot {
        var result = snapshot

        // Keep only first 6 ingredients
        if result.ingredients.count > 6 {
            result.ingredients = Array(result.ingredients.prefix(6))
        }

        // Merge/reduce steps to max 4
        if result.steps.count > 4 {
            let grouped = stride(
                from: 0, to: result.steps.count, by: max(1, result.steps.count / 4)
            )
            .map { startIndex -> StepSnapshot in
                let endIndex = min(startIndex + max(1, result.steps.count / 4), result.steps.count)
                let chunk = Array(result.steps[startIndex..<endIndex])
                let mergedInstruction = chunk.map(\.instruction).joined(separator: " Then, ")
                let totalDuration = chunk.compactMap(\.duration).reduce(0, +)
                let type = chunk.first?.type ?? .cooking
                return StepSnapshot(
                    order: (startIndex / max(1, result.steps.count / 4)) + 1,
                    instruction: mergedInstruction,
                    type: type,
                    duration: totalDuration > 0 ? totalDuration : nil
                )
            }
            result.steps = Array(grouped.prefix(4))
        }

        if !result.tags.contains("Simple") {
            result.tags.append("Simple")
        }

        return result
    }

    // MARK: - Make More Detailed

    private func applyMakeMoreDetailed(to snapshot: RecipeSnapshot) -> RecipeSnapshot {
        var result = snapshot

        let preparationEnhancements = [
            "Carefully ",
            "Thoroughly ",
            "Gently ",
        ]

        let cookingSuffixes = [
            " until golden brown",
            ", stirring occasionally",
            " until fragrant and slightly caramelized",
            ", adjusting heat as needed to prevent burning",
        ]

        let temperatureHints = [
            " (around 180°C/350°F)",
            " (medium-high heat, approximately 200°C/400°F)",
            " (low and slow at 150°C/300°F)",
        ]

        result.steps = result.steps.enumerated().map { index, step in
            var modified = step

            switch step.type {
            case .preparation:
                let prefix = preparationEnhancements[index % preparationEnhancements.count]
                if !modified.instruction.hasPrefix(prefix) {
                    // Lowercase the first character of the original instruction when prefixing
                    let lowercasedFirst =
                        modified.instruction.prefix(1).lowercased()
                        + modified.instruction.dropFirst()
                    modified.instruction = prefix + lowercasedFirst
                }
            case .cooking:
                let suffix = cookingSuffixes[index % cookingSuffixes.count]
                if !modified.instruction.hasSuffix(".") {
                    modified.instruction += suffix
                } else {
                    // Replace trailing period with suffix + period
                    modified.instruction =
                        String(modified.instruction.dropLast()) + suffix + "."
                }
                // Add temperature hint to first cooking step
                if index < temperatureHints.count {
                    modified.instruction += temperatureHints[index % temperatureHints.count]
                }
            case .maturing:
                modified.instruction +=
                    " — patience is key here; do not rush this step"
            }

            return modified
        }

        if !result.tags.contains("Detailed") {
            result.tags.append("Detailed")
        }

        return result
    }

    // MARK: - Custom

    private func applyCustom(prompt: String, to snapshot: RecipeSnapshot) -> RecipeSnapshot {
        var result = snapshot
        let note = "\n\n[AI Note: \(prompt)]"
        result.details += note
        return result
    }

    // MARK: - Renumber

    private func renumber(_ snapshot: RecipeSnapshot) -> RecipeSnapshot {
        var result = snapshot

        result.ingredients = result.ingredients.enumerated().map { index, ingredient in
            var modified = ingredient
            modified.order = index + 1
            return modified
        }

        result.steps = result.steps.enumerated().map { index, step in
            var modified = step
            modified.order = index + 1
            return modified
        }

        return result
    }
}
