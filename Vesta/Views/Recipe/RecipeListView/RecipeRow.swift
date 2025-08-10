import SwiftUI

struct RecipeRow: View {
    let recipe: Recipe

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(recipe.title)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    // Status indicator
                    statusIndicator
                }

                Text(LocalizedStringKey(recipe.details))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)

                HStack(spacing: 12) {
                    // Duration
                    if recipe.totalDuration > 0 {
                        Label(formatDuration(recipe.totalDuration), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Seasonality
                    if let seasonality = recipe.seasonality {
                        Label(seasonality.displayName, systemImage: "leaf")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Meal types
                    if !recipe.mealTypes.isEmpty {
                        HStack(spacing: 2) {
                            ForEach(recipe.mealTypes.prefix(2), id: \.self) { mealType in
                                Image(systemName: mealTypeIcon(for: mealType))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if recipe.mealTypes.count > 2 {
                                Text("+\(recipe.mealTypes.count - 2)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()
                }
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch recipe.status {
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
            if recipe.timesCookedRecently > 0 {
                Label("\(recipe.timesCookedRecently)", systemImage: "flame")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .labelStyle(.titleAndIcon)
            }
        }
    }

    private func mealTypeIcon(for mealType: MealType) -> String {
        switch mealType {
        case .breakfast:
            return "sunrise"
        case .lunch:
            return "sun.max"
        case .dinner:
            return "moon"
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "< 1m"
        }
    }
}

#Preview {
    let user = Fixtures.createUser()
    VStack {
        RecipeRow(recipe: Fixtures.bolognese(owner: user))
        Divider()
        RecipeRow(recipe: Fixtures.curry(owner: user))
    }
    .padding()
}
