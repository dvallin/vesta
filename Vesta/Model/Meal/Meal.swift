import Foundation
import SwiftData

enum MealType: String, Codable {
    case breakfast
    case lunch
    case dinner
}

@Model
class Meal {
    var scalingFactor: Double
    @Relationship(deleteRule: .cascade)
    var todoItem: TodoItem
    @Relationship(deleteRule: .nullify)
    var recipe: Recipe
    var mealType: MealType
    @Relationship(deleteRule: .nullify, inverse: \ShoppingListItem.meals)
    var shoppingListItems: [ShoppingListItem]

    init(scalingFactor: Double, todoItem: TodoItem, recipe: Recipe, mealType: MealType = .dinner) {
        self.scalingFactor = scalingFactor
        self.todoItem = todoItem
        self.recipe = recipe
        self.mealType = mealType
        self.shoppingListItems = []
    }

    func updateTodoItemDueDate(for mealType: MealType, on date: Date? = nil) {
        let baseDate = date ?? todoItem.dueDate ?? Date()
        let (hour, minute) = DateUtils.mealTime(for: mealType)
        if let newDueDate = DateUtils.setTime(hour: hour, minute: minute, for: baseDate) {
            todoItem.dueDate = newDueDate
        }
    }

    func updateDueDate(_ newDate: Date) {
        todoItem.dueDate = DateUtils.preserveTime(from: todoItem.dueDate, applying: newDate)
    }
}
