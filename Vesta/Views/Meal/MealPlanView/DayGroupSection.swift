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

#Preview {
    List {
        // Preview with multiple meals on a single day
        DayGroupSectionView(
            group: DayGroup(
                date: Date(),
                meals: [
                    Meal(
                        scalingFactor: 1.0,
                        todoItem: TodoItem(
                            title: "Cook Spaghetti Carbonara",
                            details: "Classic Italian pasta dish",
                            dueDate: Date(),
                            isCompleted: false
                        ),
                        recipe: Recipe(
                            title: "Spaghetti Carbonara",
                            details: "Traditional Roman pasta"
                        ),
                        mealType: .dinner
                    ),
                    Meal(
                        scalingFactor: 1.0,
                        todoItem: TodoItem(
                            title: "Make Pancakes",
                            details: "Fluffy breakfast pancakes",
                            dueDate: Date(),
                            isCompleted: true
                        ),
                        recipe: Recipe(
                            title: "Classic Pancakes",
                            details: "American style pancakes"
                        ),
                        mealType: .breakfast
                    ),
                    Meal(
                        scalingFactor: 1.0,
                        todoItem: TodoItem(
                            title: "Prepare Caesar Salad",
                            details: "Fresh lunch salad",
                            dueDate: Date(),
                            isCompleted: false
                        ),
                        recipe: Recipe(
                            title: "Caesar Salad",
                            details: "Classic Caesar salad"
                        ),
                        mealType: .lunch
                    ),
                ],
                weekTitle: "This Week"
            ),
            onMealSelect: { _ in },
            onDelete: { _ in },
            onMarkAsDone: { _ in }
        )
    }
    .modelContainer(for: [Meal.self, TodoItem.self, Recipe.self])
}

#Preview("Empty Day") {
    List {
        // Preview with no meals
        DayGroupSectionView(
            group: DayGroup(
                date: Date().addingTimeInterval(86400),  // Tomorrow
                meals: [],
                weekTitle: "Next Week"
            ),
            onMealSelect: { _ in },
            onDelete: { _ in },
            onMarkAsDone: { _ in }
        )
    }
    .modelContainer(for: [Meal.self, TodoItem.self, Recipe.self])
}
