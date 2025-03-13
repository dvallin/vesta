import SwiftUI

struct DayGroupSectionView: View {
    let group: DayGroup
    let onMealSelect: (Meal) -> Void
    let onDelete: (IndexSet) -> Void
    let onMarkAsDone: (TodoItem) -> Void

    var body: some View {
        Section {
            ForEach(group.meals) { meal in
                HStack {
                    Button(action: {
                        onMarkAsDone(meal.todoItem)
                    }) {
                        Image(
                            systemName: meal.todoItem.isCompleted
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                        .foregroundColor(
                            meal.todoItem.isCompleted ? .secondary : .accentColor
                        )
                        .scaleEffect(meal.todoItem.isCompleted ? 1 : 1.5)
                        .animation(.easeInOut, value: meal.todoItem.isCompleted)
                    }
                    .disabled(meal.todoItem.isCompleted)
                    .buttonStyle(BorderlessButtonStyle())

                    Button(action: {
                        onMealSelect(meal)
                    }) {
                        VStack(alignment: .leading) {
                            Text(meal.recipe.title)
                                .font(.headline)
                            Text(meal.mealType.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .onDelete(perform: onDelete)
        } header: {
            VStack(alignment: .leading, spacing: 4) {
                if let weekTitle = group.weekTitle {
                    Text(weekTitle)
                        .font(.title2)
                        .padding(.bottom, 2)
                        .foregroundColor(.primary)
                }
                Text(group.date, style: .date)
                    .font(.headline)
            }
            .padding(.vertical, 4)
        }
    }
}
