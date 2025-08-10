import SwiftData
import SwiftUI

struct ReadOnlyRecipeDetailView: View {
    let recipe: Recipe
    let scalingFactor: Double

    var body: some View {
        Form {
            Section(header: Text(NSLocalizedString("Recipe Details", comment: "Section header"))) {
                Text(recipe.title)
                    .font(.title)
                    .bold()
                Text(LocalizedStringKey(recipe.details))
            }

            // Seasonality Section
            if let seasonality = recipe.seasonality {
                Section(header: Text(NSLocalizedString("Seasonality", comment: "Section header"))) {
                    Text(seasonality.displayName)
                }
            }

            // Meal Types Section
            if !recipe.mealTypes.isEmpty {
                Section(header: Text(NSLocalizedString("Meal Types", comment: "Section header"))) {
                    ForEach(recipe.mealTypes, id: \.self) { mealType in
                        Text(mealType.displayName)
                    }
                }
            }

            // Tags Section
            if !recipe.tags.isEmpty {
                Section(header: Text(NSLocalizedString("Tags", comment: "Section header"))) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
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
                    .padding(.vertical, 4)
                }
            }

            DurationSectionView(recipe: recipe)

            Section(header: Text(NSLocalizedString("Ingredients", comment: "Section header"))) {
                ForEach(recipe.sortedIngredients) { ingredient in
                    HStack {
                        Text(ingredient.name)
                        Spacer()
                        Text(formattedQuantity(for: ingredient))
                    }
                }
            }

            Section(header: Text(NSLocalizedString("Steps", comment: "Section header"))) {
                ForEach(recipe.sortedSteps) { step in
                    VStack(alignment: .leading) {
                        Text(step.instruction)
                        if let duration = step.duration {
                            Text(DateUtils.formattedDuration(duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func formattedQuantity(for ingredient: Ingredient) -> String {
        if ingredient.quantity == nil {
            return ""
        }
        let scaledQuantity = (ingredient.quantity ?? 0) * scalingFactor
        let qtyPart = NumberFormatter.localizedString(
            from: NSNumber(value: scaledQuantity), number: .decimal)
        let unitPart = ingredient.unit?.displayName ?? ""
        return qtyPart + " " + unitPart
    }
}

#Preview {
    let recipe = Fixtures.bolognese()
    return ReadOnlyRecipeDetailView(recipe: recipe, scalingFactor: 1.0)
}
