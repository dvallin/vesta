import SwiftUI

struct DurationSectionView: View {
    let recipe: Recipe

    var body: some View {
        Section(header: Text(NSLocalizedString("Duration", comment: "Section header"))) {
            if recipe.preparationDuration > 0 {
                DurationRow(
                    label: NSLocalizedString("Preparation", comment: "Duration label"),
                    duration: recipe.preparationDuration
                )
            }
            if recipe.cookingDuration > 0 {
                DurationRow(
                    label: NSLocalizedString("Cooking", comment: "Duration label"),
                    duration: recipe.cookingDuration
                )
            }
            if recipe.maturingDuration > 0 {
                DurationRow(
                    label: NSLocalizedString("Maturing", comment: "Duration label"),
                    duration: recipe.maturingDuration
                )
            }
            DurationRow(
                label: NSLocalizedString("Total", comment: "Duration label"),
                duration: recipe.totalDuration
            )
            .bold()
        }
    }
}

struct DurationRow: View {
    let label: String
    let duration: TimeInterval

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(DateUtils.formattedDuration(duration))
        }
    }
}
