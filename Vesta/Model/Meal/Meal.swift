import Foundation
import SwiftData

@Model
class Meal {
    var scalingFactor: Double
    @Relationship(deleteRule: .cascade)
    var todoItem: TodoItem
    @Relationship(deleteRule: .nullify)
    var recipe: Recipe

    init(scalingFactor: Double, todoItem: TodoItem, recipe: Recipe) {
        self.scalingFactor = scalingFactor
        self.todoItem = todoItem
        self.recipe = recipe
    }
}
