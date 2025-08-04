import SwiftUI

struct MealListItem: View {
    @ObservedObject var viewModel: MealPlanViewModel
    let meal: Meal

    // MARK: - Planning State Color
    private var planningColor: Color {
        let items = meal.shoppingListItems
        if items.isEmpty {
            return .gray
        }
        let purchased = items.filter { $0.isPurchased }.count
        if purchased == 0 {
            return .blue
        } else if purchased < items.count {
            return .orange
        } else {
            return .green
        }
    }

    var body: some View {
        HStack {
            // Leading checkmark/circle with planning color
            if meal.todoItem != nil {
                Button(action: markAsDone) {
                    Image(
                        systemName: meal.isDone
                            ? "checkmark.circle.fill"
                            : "circle"
                    )
                    .foregroundColor(planningColor)
                    .scaleEffect(meal.isDone ? 1 : 1.5)
                    .animation(.easeInOut, value: meal.isDone)
                }
                .buttonStyle(BorderlessButtonStyle())
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.clear)
                    .scaleEffect(1.5)
            }

            Button(action: selectMeal) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.recipe?.title ?? "No Recipe")
                        .font(.headline)
                        .foregroundColor(.primary)
                    if let dueDate = meal.todoItem?.dueDate {
                        Text(dueDate, style: .date)
                            .font(.subheadline)
                            .foregroundColor(
                                (dueDate < Date() && !(meal.isDone)) ? .red : .secondary
                            )
                    }
                }
            }

            Spacer()

            // Meal type pill at end
            Text(meal.mealType.displayName.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .foregroundColor(.blue)
        }
        .contentShape(Rectangle())
    }

    private func selectMeal() {
        viewModel.selectMeal(meal)
        HapticFeedbackManager.shared.generateSelectionFeedback()
    }

    private func markAsDone() {
        withAnimation {
            viewModel.markMealAsDone(meal)
        }
    }
}

#Preview {
    let user = Fixtures.createUser()
    let recipe = Fixtures.bolognese(owner: user)
    let viewModel = MealPlanViewModel()

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
        MealListItem(viewModel: viewModel, meal: meal)
        MealListItem(
            viewModel: viewModel,
            meal: Meal(
                scalingFactor: 1.0,
                todoItem: TodoItem(title: "Make Lunch", details: "Quick meal", owner: user),
                recipe: Recipe(title: "Salad", details: "Fresh greens", owner: user),
                mealType: .lunch,
                owner: user
            )
        )
    }
    .padding()
}

#Preview("Planning States") {
    let user = Fixtures.createUser()
    let recipe = Fixtures.bolognese(owner: user)
    let viewModel = MealPlanViewModel()

    // No shopping items (gray)
    let mealNoShopping = Meal(
        scalingFactor: 1.0,
        todoItem: TodoItem(
            title: "No Shopping", details: "No shopping items",
            dueDate: Date().addingTimeInterval(3600), owner: user),
        recipe: recipe,
        mealType: .dinner,
        owner: user
    )

    // Has shopping items, none purchased (blue)
    let mealAllUnpurchased = Meal(
        scalingFactor: 1.0,
        todoItem: TodoItem(
            title: "All Unpurchased", details: "All items unpurchased",
            dueDate: Date().addingTimeInterval(3600), owner: user),
        recipe: recipe,
        mealType: .lunch,
        owner: user
    )
    let shopping1 = ShoppingListItem(name: "Tomatoes", todoItem: nil, owner: user)
    let shopping2 = ShoppingListItem(name: "Pasta", todoItem: nil, owner: user)
    mealAllUnpurchased.shoppingListItems = [shopping1, shopping2]

    // Has shopping items, some purchased (orange)
    let mealSomePurchased = Meal(
        scalingFactor: 1.0,
        todoItem: TodoItem(
            title: "Some Purchased", details: "Some items purchased",
            dueDate: Date().addingTimeInterval(3600), owner: user),
        recipe: recipe,
        mealType: .breakfast,
        owner: user
    )
    let shopping3 = ShoppingListItem(name: "Eggs", todoItem: nil, owner: user)
    let shopping4 = ShoppingListItem(name: "Bacon", todoItem: nil, owner: user)
    shopping3.todoItem = TodoItem(title: "Eggs", details: "", isCompleted: true, owner: user)  // purchased
    shopping4.todoItem = TodoItem(title: "Bacon", details: "", isCompleted: false, owner: user)  // not purchased
    mealSomePurchased.shoppingListItems = [shopping3, shopping4]

    // All shopping items purchased (green)
    let mealAllPurchased = Meal(
        scalingFactor: 1.0,
        todoItem: TodoItem(
            title: "All Purchased", details: "All items purchased",
            dueDate: Date().addingTimeInterval(3600), owner: user),
        recipe: recipe,
        mealType: .dinner,
        owner: user
    )
    let shopping5 = ShoppingListItem(name: "Cheese", todoItem: nil, owner: user)
    let shopping6 = ShoppingListItem(name: "Bread", todoItem: nil, owner: user)
    shopping5.todoItem = TodoItem(title: "Cheese", details: "", isCompleted: true, owner: user)
    shopping6.todoItem = TodoItem(title: "Bread", details: "", isCompleted: true, owner: user)
    mealAllPurchased.shoppingListItems = [shopping5, shopping6]

    // Overdue due date (due date text red, icon color based on shopping state)
    let mealOverdue = Meal(
        scalingFactor: 1.0,
        todoItem: TodoItem(
            title: "Overdue", details: "Overdue meal", dueDate: Date().addingTimeInterval(-3600),
            owner: user),
        recipe: recipe,
        mealType: .lunch,
        owner: user
    )
    let shopping7 = ShoppingListItem(name: "Milk", todoItem: nil, owner: user)
    mealOverdue.shoppingListItems = [shopping7]

    return VStack(spacing: 16) {
        MealListItem(viewModel: viewModel, meal: mealNoShopping)
        MealListItem(viewModel: viewModel, meal: mealAllUnpurchased)
        MealListItem(viewModel: viewModel, meal: mealSomePurchased)
        MealListItem(viewModel: viewModel, meal: mealAllPurchased)
        MealListItem(viewModel: viewModel, meal: mealOverdue)
    }
    .padding()
}
