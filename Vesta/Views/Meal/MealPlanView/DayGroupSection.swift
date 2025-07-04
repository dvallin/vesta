import SwiftUI

struct DayGroupSectionView: View {
    let group: DayGroup
    let onMealSelect: (Meal) -> Void
    let onDelete: (IndexSet) -> Void
    let onMarkAsDone: (TodoItem?) -> Void

    var body: some View {
        Section {
            ForEach(group.meals) { meal in
                HStack {
                    Button(action: {
                        HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)
                        onMarkAsDone(meal.todoItem)
                    }) {
                        Image(
                            systemName: meal.isDone
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                        .foregroundColor(
                            meal.isDone ? .secondary : .blue
                        )
                        .scaleEffect(meal.isDone ? 1 : 1.5)
                        .animation(.easeInOut, value: meal.isDone)
                    }
                    .disabled(meal.isDone)
                    .buttonStyle(BorderlessButtonStyle())

                    Button(action: {
                        HapticFeedbackManager.shared.generateSelectionFeedback()
                        onMealSelect(meal)
                    }) {
                        VStack(alignment: .leading) {
                            Text(meal.recipe?.title ?? "No Recipe")
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
    let user = Fixtures.createUser()
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
                            isCompleted: false,
                            owner: user
                        ),
                        recipe: Recipe(
                            title: "Spaghetti Carbonara",
                            details: "Traditional Roman pasta",
                            owner: user
                        ),
                        mealType: .dinner,
                        owner: user
                    ),
                    Meal(
                        scalingFactor: 1.0,
                        todoItem: TodoItem(
                            title: "Make Pancakes",
                            details: "Fluffy breakfast pancakes",
                            dueDate: Date(),
                            isCompleted: true,
                            owner: user
                        ),
                        recipe: Recipe(
                            title: "Classic Pancakes",
                            details: "American style pancakes",
                            owner: user
                        ),
                        mealType: .breakfast,
                        owner: user
                    ),
                    Meal(
                        scalingFactor: 1.0,
                        todoItem: TodoItem(
                            title: "Prepare Caesar Salad",
                            details: "Fresh lunch salad",
                            dueDate: Date(),
                            isCompleted: false,
                            owner: user
                        ),
                        recipe: Recipe(
                            title: "Caesar Salad",
                            details: "Classic Caesar salad",
                            owner: user
                        ),
                        mealType: .lunch,
                        owner: user
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
