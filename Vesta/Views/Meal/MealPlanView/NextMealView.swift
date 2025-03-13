import SwiftUI

struct NextMealView: View {
    let meal: Meal
    let onSelect: () -> Void

    var body: some View {
        Section {
            Button(action: onSelect) {
                VStack(alignment: .leading) {
                    Text(meal.recipe.title)
                        .font(.headline)
                    if let dueDate = meal.todoItem.dueDate {
                        Text(dueDate, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text(meal.mealType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text(NSLocalizedString("Next Meal", comment: "Next meal section header"))
                .font(.title)
                .foregroundColor(.primary)
        }
    }
}
