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

    init(scalingFactor: Double, todoItem: TodoItem, recipe: Recipe, mealType: MealType = .dinner) {
        self.scalingFactor = scalingFactor
        self.todoItem = todoItem
        self.recipe = recipe
        self.mealType = mealType
    }

    func updateTodoItemDueDate(for mealType: MealType, on date: Date = Date()) {
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)

        switch mealType {
        case .breakfast:
            dateComponents.hour = 8
            dateComponents.minute = 0
        case .lunch:
            dateComponents.hour = 12
            dateComponents.minute = 0
        case .dinner:
            dateComponents.hour = 18
            dateComponents.minute = 0
        }

        if let newDueDate = calendar.date(from: dateComponents) {
            todoItem.dueDate = newDueDate
        }
    }
}
