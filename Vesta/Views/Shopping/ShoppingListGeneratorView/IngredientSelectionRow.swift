import SwiftData
import SwiftUI

struct IngredientSelectionRow: View {
    @Binding var selection: ShoppingListGeneratorViewModel.IngredientSelection

    var body: some View {
        HStack {
            Text(selection.ingredient.name)
                .font(.body)

            Spacer()

            HStack(spacing: 4) {
                TextField(
                    NSLocalizedString("Qty", comment: "Quantity input field placeholder"),
                    value: $selection.quantity,
                    format: .number
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
                .multilineTextAlignment(.trailing)

                if let unit = selection.unit {
                    Text(unit.displayName)
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .leading)
                }
            }
        }
        .badge(formatDaysBadge(selection.earliestDueDate))
        .swipeActions(edge: .trailing) {
            Button(
                selection.isSelected
                    ? NSLocalizedString("Exclude", comment: "Button to exclude ingredient")
                    : NSLocalizedString("Include", comment: "Button to include ingredient")
            ) {
                selection.isSelected.toggle()
            }
            .tint(selection.isSelected ? .red : .green)
        }
        .listRowBackground(
            selection.isSelected ? Color(.systemBackground) : Color(.systemGray6)
        )
    }

    private func formatDaysBadge(_ date: Date) -> String {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        let days = calendar.dateComponents([.day], from: startOfToday, to: date).day ?? 0
        switch days {
        case 0: return NSLocalizedString("today", comment: "Badge text for today")
        case 1: return NSLocalizedString("1d", comment: "Badge text for tomorrow")
        default:
            return String(
                format: NSLocalizedString("%dd", comment: "Badge text for future days"), days)
        }
    }
}

#Preview {
    List {
        // Regular ingredient with quantity and unit
        IngredientSelectionRow(
            selection: .constant(
                ShoppingListGeneratorViewModel.IngredientSelection(
                    ingredient: Ingredient(name: "Tomatoes", quantity: 4, unit: .piece),
                    meals: [],
                    isSelected: true,
                    quantity: 4,
                    earliestDueDate: Date().addingTimeInterval(24 * 3600),
                    unit: .piece
                )
            )
        )

        // Ingredient for today without unit
        IngredientSelectionRow(
            selection: .constant(
                ShoppingListGeneratorViewModel.IngredientSelection(
                    ingredient: Ingredient(name: "Salt", quantity: 1, unit: nil),
                    meals: [],
                    isSelected: true,
                    quantity: 1,
                    earliestDueDate: Date(),
                    unit: nil
                )
            )
        )

        // Deselected ingredient with future date
        IngredientSelectionRow(
            selection: .constant(
                ShoppingListGeneratorViewModel.IngredientSelection(
                    ingredient: Ingredient(name: "Flour", quantity: 500, unit: .gram),
                    meals: [],
                    isSelected: false,
                    quantity: 500,
                    earliestDueDate: Date().addingTimeInterval(3 * 24 * 3600),
                    unit: .gram
                )
            )
        )
    }
}
