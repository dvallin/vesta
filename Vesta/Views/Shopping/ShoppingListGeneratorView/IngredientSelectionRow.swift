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
                TextField("Qty", value: $selection.quantity, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)

                if let unit = selection.unit {
                    Text(unit.rawValue)
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .leading)
                }
            }
        }
        .badge(formatDaysBadge(selection.earliestDueDate))
        .swipeActions(edge: .trailing) {
            Button(selection.isSelected ? "Exclude" : "Include") {
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
        case 0: return "today"
        case 1: return "1d"
        default: return "\(days)d"
        }
    }
}
