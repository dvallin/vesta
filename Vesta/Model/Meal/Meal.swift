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
class Meal: SyncableEntity {
    @Attribute(.unique) var uid: String?

    var scalingFactor: Double
    var mealType: MealType

    @Relationship(deleteRule: .noAction)
    var owner: User?

    var lastModified: Date = Date()
    var dirty: Bool = true

    @Relationship(deleteRule: .cascade, inverse: \TodoItem.meal)
    var todoItem: TodoItem?

    @Relationship(inverse: \Recipe.meals)
    var recipe: Recipe?

    @Relationship(inverse: \ShoppingListItem.meals)
    var shoppingListItems: [ShoppingListItem]

    @Relationship
    var spaces: [Space]

    var isDone: Bool {
        guard let todoItem = todoItem else { return true }
        return todoItem.isCompleted
    }

    init(
        scalingFactor: Double, todoItem: TodoItem, recipe: Recipe, mealType: MealType = .dinner,
        owner: User
    ) {
        self.uid = UUID().uuidString
        self.scalingFactor = scalingFactor
        self.todoItem = todoItem
        self.recipe = recipe
        self.mealType = mealType
        self.shoppingListItems = []
        self.owner = owner
        self.lastModified = Date()
        self.dirty = true
        self.spaces = []
    }

    func updateTodoItemDueDate(for mealType: MealType, on date: Date? = nil, currentUser: User) {
        let baseDate = date ?? todoItem?.dueDate ?? Date()
        let (hour, minute) = DateUtils.mealTime(for: mealType)
        if let newDueDate = DateUtils.setTime(hour: hour, minute: minute, for: baseDate) {
            todoItem?.setDueDate(dueDate: newDueDate, currentUser: currentUser)
        }
        self.markAsDirty()
    }

    func setDueDate(_ newDate: Date, currentUser: User) {
        todoItem?.setDueDate(
            dueDate: DateUtils.preserveTime(from: todoItem?.dueDate, applying: newDate),
            currentUser: currentUser
        )
        self.markAsDirty()
    }

    func setScalingFactor(_ newScalingFactor: Double) {
        self.scalingFactor = newScalingFactor
        self.markAsDirty()
    }

    func setMealType(_ newMealType: MealType) {
        self.mealType = newMealType
        self.markAsDirty()
    }
}
