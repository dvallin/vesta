import Foundation
import SwiftData

enum MealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner

    var displayName: String {
        switch self {
        case .breakfast:
            return String(localized: "meal.mealtype.breakfast")
        case .lunch:
            return String(localized: "meal.mealtype.lunch")
        case .dinner:
            return String(localized: "meal.mealtype.dinner")
        }
    }
}

@Model
class Meal: SyncableEntity {

    @Attribute(.unique) var uid: String

    var scalingFactor: Double
    var mealType: MealType

    @Relationship(deleteRule: .noAction)
    var owner: User?

    var isShared: Bool = false
    var dirty: Bool = true

    var deletedAt: Date? = nil
    var expireAt: Date? = nil

    @Relationship(deleteRule: .nullify, inverse: \TodoItem.meal)
    var todoItem: TodoItem?

    @Relationship(deleteRule: .nullify, inverse: \Recipe.meals)
    var recipe: Recipe?

    @Relationship(deleteRule: .nullify, inverse: \ShoppingListItem.meals)
    var shoppingListItems: [ShoppingListItem]

    var isDone: Bool {
        guard let todoItem = todoItem else { return true }
        return todoItem.isCompleted
    }

    /// Returns the date when this meal was last completed, or nil if never completed
    var lastCompletionDate: Date? {
        return todoItem?.lastCompletionDate
    }

    init(
        scalingFactor: Double, todoItem: TodoItem?, recipe: Recipe?, mealType: MealType = .dinner,
        owner: User?
    ) {
        self.uid = UUID().uuidString
        self.scalingFactor = scalingFactor
        self.todoItem = todoItem
        self.recipe = recipe
        self.mealType = mealType
        self.shoppingListItems = []
        self.owner = owner
        self.dirty = true
    }

    func updateTodoItemDueDate(for mealType: MealType, on date: Date? = nil, currentUser: User) {
        guard let baseDate = date ?? todoItem?.dueDate else { return }
        let (hour, minute) = DateUtils.mealTime(for: mealType)
        if let newDueDate = DateUtils.setTime(hour: hour, minute: minute, for: baseDate) {
            todoItem?.setDueDate(dueDate: newDueDate, currentUser: currentUser)
        }
        self.markAsDirty()
    }

    func setDueDate(_ newDate: Date?, currentUser: User) {
        if let newDate = newDate {
            todoItem?.setDueDate(
                dueDate: DateUtils.preserveTime(from: todoItem?.dueDate, applying: newDate),
                currentUser: currentUser
            )
        } else {
            todoItem?.setDueDate(dueDate: nil, currentUser: currentUser)
        }
        self.markAsDirty()
    }

    func removeDueDate(currentUser: User) {
        todoItem?.setDueDate(dueDate: nil, currentUser: currentUser)
        self.markAsDirty()
    }

    func setScalingFactor(_ newScalingFactor: Double, currentUser: User) {
        self.scalingFactor = newScalingFactor
        self.markAsDirty()
    }

    func setMealType(_ newMealType: MealType, currentUser: User) {
        self.mealType = newMealType
        self.updateTodoItemDueDate(for: newMealType, currentUser: currentUser)
        self.markAsDirty()
    }

    // MARK: - Soft Delete Operations

    func softDelete(currentUser: User) {
        self.deletedAt = Date()
        self.setExpiration()
        self.markAsDirty()

        // Soft delete related todo item only if it's not already deleted
        if let todoItem = self.todoItem, todoItem.deletedAt == nil {
            todoItem.softDelete(currentUser: currentUser)
        }
    }

    func restore(currentUser: User) {
        self.deletedAt = nil
        self.clearExpiration()
        self.markAsDirty()

        // Restore related todo item only if it's currently deleted
        if let todoItem = self.todoItem, todoItem.deletedAt != nil {
            todoItem.restore(currentUser: currentUser)
        }
    }
}
