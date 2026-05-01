import SwiftUI

struct RecipeContentView<R: RecipeDisplayable>: View {
    let recipe: R
    var scalingFactor: Double = 1.0
    var label: String? = nil

    var body: some View {
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
                Text(LocalizedStringKey(recipe.details))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            // Metadata (seasonality + meal types as chips)
            if recipe.seasonality != nil || !recipe.mealTypes.isEmpty {
                metadataSection
            }

            // Tags
            if !recipe.tags.isEmpty {
                tagsSection
            }

            // Duration
            if recipe.totalDuration > 0 {
                durationSection
            }

            // Ingredients
            if !recipe.sortedIngredients.isEmpty {
                ingredientsSection
            }

            // Steps
            if !recipe.sortedSteps.isEmpty {
                stepsSection
            }
        }
        .padding(.vertical)
    }

    // MARK: - Metadata

    @ViewBuilder
    private var metadataSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                if let seasonality = recipe.seasonality {
                    metadataChip(icon: "leaf", text: seasonality.displayName)
                }
                ForEach(recipe.mealTypes, id: \.self) { mealType in
                    metadataChip(icon: "fork.knife", text: mealType.displayName)
                }
            }
            .padding(.horizontal)
        }
    }

    private func metadataChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
        .foregroundColor(.secondary)
        .cornerRadius(8)
    }

    // MARK: - Tags

    private var tagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(recipe.tags, id: \.self) { tag in
                    Text(tag)
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

    // MARK: - Duration

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("Duration", comment: "Section header"))
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 16) {
                if recipe.preparationDuration > 0 {
                    durationItem(
                        label: NSLocalizedString("Prep", comment: "Duration label"),
                        duration: recipe.preparationDuration
                    )
                }
                if recipe.cookingDuration > 0 {
                    durationItem(
                        label: NSLocalizedString("Cook", comment: "Duration label"),
                        duration: recipe.cookingDuration
                    )
                }
                if recipe.maturingDuration > 0 {
                    durationItem(
                        label: NSLocalizedString("Mature", comment: "Duration label"),
                        duration: recipe.maturingDuration
                    )
                }
                durationItem(
                    label: NSLocalizedString("Total", comment: "Duration label"),
                    duration: recipe.totalDuration,
                    isBold: true
                )
            }
            .padding(.horizontal)
        }
    }

    private func durationItem(label: String, duration: TimeInterval, isBold: Bool = false)
        -> some View
    {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(DateUtils.formattedDuration(duration))
                .font(.subheadline)
                .fontWeight(isBold ? .semibold : .regular)
        }
    }

    // MARK: - Ingredients

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("Ingredients", comment: "Section header"))
                .font(.headline)
                .padding(.horizontal)

            ForEach(recipe.sortedIngredients) { ingredient in
                HStack {
                    Text("•")
                    Text(ingredient.name)
                    Spacer()
                    Text(formattedQuantity(for: ingredient))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
        }
    }

    private func formattedQuantity(for ingredient: some IngredientDisplayable) -> String {
        guard let quantity = ingredient.quantity else { return "" }
        let scaledQuantity = quantity * scalingFactor
        let qtyPart = NumberFormatter.localizedString(
            from: NSNumber(value: scaledQuantity), number: .decimal)
        let unitPart = ingredient.unit?.displayName ?? ""
        return unitPart.isEmpty ? qtyPart : qtyPart + " " + unitPart
    }

    // MARK: - Steps

    private var stepsSection: some View {
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

#Preview {
    ScrollView {
        RecipeContentView(recipe: Fixtures.bolognese())
    }
}
