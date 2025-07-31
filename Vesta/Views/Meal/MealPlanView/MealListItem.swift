import SwiftUI

struct MealListItem: View {
    let meal: Meal
    let onComplete: () -> Void

    var body: some View {
        HStack {
            if meal.todoItem != nil {
                Button(action: onComplete) {
                    Image(
                        systemName: meal.isDone
                            ? "checkmark.circle.fill"
                            : "circle"
                    )
                    .foregroundColor(meal.isDone ? .gray : .blue)
                    .scaleEffect(meal.isDone ? 1 : 1.5)
                    .animation(.easeInOut, value: meal.isDone)
                }
                .buttonStyle(BorderlessButtonStyle())
            } else {
                // Add spacing to maintain consistent layout when no button is shown
                Image(systemName: "circle")
                    .foregroundColor(.clear)
                    .scaleEffect(1.5)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(meal.recipe?.title ?? "No Recipe")
                    .font(.headline)
                HStack(spacing: 8) {
                    if let dueDate = meal.todoItem?.dueDate {
                        Text(dueDate, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text(meal.mealType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if meal.isDone {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    let user = Fixtures.createUser()
    let recipe = Fixtures.bolognese(owner: user)

    let todoItem = TodoItem(
        title: "Cook Spaghetti",
        details: "Dinner",
        dueDate: Date(),
        owner: user
    )

    let meal = Meal(
        scalingFactor: 1.0,
        todoItem: todoItem,
        recipe: recipe,
        mealType: .dinner,
        owner: user
    )

    return VStack {
        MealListItem(meal: meal) {}
        MealListItem(
            meal: Meal(
                scalingFactor: 1.0,
                todoItem: TodoItem(title: "Make Lunch", details: "Quick meal", owner: user),
                recipe: Recipe(title: "Salad", details: "Fresh greens", owner: user),
                mealType: .lunch,
                owner: user
            )
        ) {}
    }
    .padding()
}
