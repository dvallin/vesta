import Foundation
import SwiftData

enum MealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner

    var displayName: String {
        switch self {
        case .breakfast:
            return NSLocalizedString("breakfast", comment: "Breakfast meal type")
        case .lunch:
            return NSLocalizedString("lunch", comment: "Lunch meal type")
        case .dinner:
            return NSLocalizedString("dinner", comment: "Dinner meal type")
        }
    }
}

@Model
class Meal {
    var scalingFactor: Double
    var mealType: MealType

    @Relationship(deleteRule: .cascade)
    var todoItem: TodoItem?

    @Relationship(inverse: \Recipe.meals)
    var recipe: Recipe?

    @Relationship(inverse: \ShoppingListItem.meals)
    var shoppingListItems: [ShoppingListItem]

    var isDone: Bool {
        guard let todoItem = todoItem else { return true }
        return todoItem.isCompleted
    }

    init(scalingFactor: Double, todoItem: TodoItem, recipe: Recipe, mealType: MealType = .dinner) {
        self.scalingFactor = scalingFactor
        self.todoItem = todoItem
        self.recipe = recipe
        self.mealType = mealType
        self.shoppingListItems = []
    }

    func updateTodoItemDueDate(for mealType: MealType, on date: Date? = nil) {
        let baseDate = date ?? todoItem?.dueDate ?? Date()
        let (hour, minute) = DateUtils.mealTime(for: mealType)
        if let newDueDate = DateUtils.setTime(hour: hour, minute: minute, for: baseDate) {
            todoItem?.dueDate = newDueDate
        }
    }

    func updateDueDate(_ newDate: Date) {
        todoItem?.dueDate = DateUtils.preserveTime(from: todoItem?.dueDate, applying: newDate)
    }
}
