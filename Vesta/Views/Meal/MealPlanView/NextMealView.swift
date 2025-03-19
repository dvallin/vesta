import SwiftUI

struct NextMealView: View {
    let meal: Meal
    let onSelect: () -> Void

    var body: some View {
        Section {
            Button(action: {
                HapticFeedbackManager.shared.generateSelectionFeedback()
                onSelect()
            }) {
                VStack(alignment: .leading) {
                    Text(meal.recipe?.title ?? "No Recipe")
                        .font(.headline)
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
        } header: {
            Text(NSLocalizedString("Next Meal", comment: "Next meal section header"))
                .font(.title)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    List {
        NextMealView(
            meal: Meal(
                scalingFactor: 1.0,
                todoItem: TodoItem(
                    title: "Cook Spaghetti Carbonara",
                    details: "Make dinner",
                    dueDate: Date().addingTimeInterval(3600)
                ),
                recipe: Recipe(
                    title: "Spaghetti Carbonara",
                    details: "Classic Italian pasta dish",
                    ingredients: [
                        Ingredient(name: "Spaghetti", quantity: 500, unit: .gram),
                        Ingredient(name: "Eggs", quantity: 4, unit: .piece),
                        Ingredient(name: "Pecorino Romano", quantity: 100, unit: .gram),
                    ]
                ),
                mealType: .dinner
            )
        ) {
            print("Meal selected")
        }
    }
}
