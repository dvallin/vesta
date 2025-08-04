import SwiftData
import SwiftUI

class ShoppingListGeneratorViewModel: ObservableObject {
    private var auth: UserAuthService?
    private var modelContext: ModelContext?
    private var categoryService: TodoItemCategoryService?
    private var syncService: SyncService?

    func configureContext(
        _ context: ModelContext, _ auth: UserAuthService,
        _ syncService: SyncService
    ) {
        self.modelContext = context
        self.auth = auth
        self.categoryService = TodoItemCategoryService(modelContext: context)
        self.syncService = syncService
    }

    struct IngredientSelection: Identifiable {
        let id = UUID()
        let ingredient: Ingredient
        let meals: [Meal]
        var isSelected: Bool
        var quantity: Double
        var earliestDueDate: Date
        var unit: Unit?
    }

    @Published var ingredientSelections: [IngredientSelection] = []

    func prepareMealsForShoppingList(_ meals: [Meal]) {
        let eligibleMeals = meals.filter { meal in
            return !meal.isDone && meal.shoppingListItems.isEmpty
        }

        let groupedIngredients = Dictionary(
            grouping: eligibleMeals.flatMap { meal in
                meal.recipe?.ingredients.map { ($0, meal) } ?? []
            }
        ) { $0.0.name }

        ingredientSelections = groupedIngredients.map { name, ingredientMealPairs in
            let firstIngredient = ingredientMealPairs[0].0
            let totalQuantity = ingredientMealPairs.reduce(0.0) { sum, pair in
                sum + (pair.0.quantity ?? 0) * pair.1.scalingFactor
            }
            let earliestDueDate =
                ingredientMealPairs.compactMap { $0.1.todoItem?.dueDate }.min() ?? Date()

            return IngredientSelection(
                ingredient: firstIngredient,
                meals: ingredientMealPairs.map { $0.1 },
                isSelected: true,
                quantity: totalQuantity,
                earliestDueDate: earliestDueDate,
                unit: firstIngredient.unit
            )
        }.sorted { l, r in l.earliestDueDate < r.earliestDueDate }
    }

    func generateShoppingList() {
        guard let currentUser = auth?.currentUser else { return }
        guard let categoryService = categoryService else { return }
        guard let modelContext = modelContext else { return }

        let shoppingCategory = categoryService.fetchOrCreate(
            named: NSLocalizedString("Shopping", comment: "Shopping category name")
        )

        for selection in ingredientSelections where selection.isSelected {
            let todoTitle = String(
                format: NSLocalizedString("Buy %@", comment: "Shopping list item title"),
                selection.ingredient.name)

            let todoDetails = String(
                format: NSLocalizedString("Buy for: %@", comment: "Shopping list item details"),
                selection.meals.map { $0.recipe?.title ?? "" }.joined(separator: ", "))

            let todoItem = TodoItem.create(
                title: todoTitle,
                details: todoDetails,
                dueDate: selection.earliestDueDate,
                ignoreTimeComponent: false,
                category: shoppingCategory,
                owner: currentUser
            )
            modelContext.insert(todoItem)

            let shoppingListItem = ShoppingListItem(
                name: selection.ingredient.name,
                quantity: selection.quantity,
                unit: selection.unit,
                todoItem: todoItem,
                owner: currentUser
            )
            shoppingListItem.meals = selection.meals

            modelContext.insert(shoppingListItem)
        }
        do {
            try modelContext.save()
            _ = syncService?.pushLocalChanges()
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .success)
        } catch {
            HapticFeedbackManager.shared.generateNotificationFeedback(type: .error)
        }
    }
}
