import SwiftUI

struct AddMealRecipeRow: View {
    let recipe: Recipe
    let status: RecipeStatus

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)

                Text(LocalizedStringKey(recipe.details))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }

            Spacer()

            // Status indicators
            statusIndicator
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch status {
        case .planned:
            Label("Planned", systemImage: "calendar.badge.checkmark")
                .font(.caption)
                .foregroundColor(.orange)
                .labelStyle(.iconOnly)
        case .recent:
            Label("Recent", systemImage: "clock.badge.checkmark")
                .font(.caption)
                .foregroundColor(.green)
                .labelStyle(.iconOnly)
        case .normal:
            EmptyView()
        }
    }
}

#Preview {
    let recipe = Recipe(title: "Sample Recipe", details: "A delicious sample recipe", owner: nil)

    VStack {
        AddMealRecipeRow(recipe: recipe, status: .normal)
        AddMealRecipeRow(recipe: recipe, status: .planned)
        AddMealRecipeRow(recipe: recipe, status: .recent)
    }
    .padding()
}
