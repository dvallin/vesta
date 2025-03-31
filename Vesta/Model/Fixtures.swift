import Foundation
import SwiftData

struct Fixtures {

    static var defaultUser = User(
        uid: "fixture-user-123",
        email: "demo@example.com",
        displayName: "Demo User",
        photoURL: nil,
        isEmailVerified: true,
        createdAt: Date().addingTimeInterval(-30 * 24 * 60 * 60),  // 30 days ago
        lastSignInAt: Date()
    )

    static var bolognese = Recipe(
        title: "Spaghetti Bolognese",
        details:
            "A classic Italian pasta dish. [link to original recipe](https://www.youtube.com/watch?v=0O2Xd-Yw\\_cQ)",
        ingredients: [
            Ingredient(name: "Spaghetti", order: 1, quantity: 200, unit: .gram),
            Ingredient(name: "Ground Beef", order: 2, quantity: 300, unit: .gram),
            Ingredient(name: "Tomato Sauce", order: 3, quantity: 400, unit: .milliliter),
            Ingredient(name: "Salt", order: 4, quantity: nil, unit: nil),
        ],
        steps: [
            RecipeStep(
                order: 1, instruction: "Bring a large pot of water to boil", type: .preparation,
                duration: 300),
            RecipeStep(
                order: 2, instruction: "Brown the ground beef in a large pan over medium heat",
                type: .cooking, duration: 600),
            RecipeStep(
                order: 3, instruction: "Add tomato sauce and seasonings to the beef",
                type: .cooking, duration: 120),
            RecipeStep(
                order: 4, instruction: "Let the sauce simmer", type: .cooking, duration: 1800),
            RecipeStep(
                order: 5,
                instruction: "Cook spaghetti in boiling water according to package instructions",
                type: .cooking, duration: 600),
            RecipeStep(
                order: 6, instruction: "Drain spaghetti and combine with sauce", type: .cooking,
                duration: 120),
        ],
        owner: Fixtures.defaultUser
    )

    static var curry = Recipe(
        title: "Chicken Curry",
        details: "Spicy Indian curry",
        ingredients: [
            Ingredient(name: "Chicken", order: 1, quantity: 1, unit: .kilogram),
            Ingredient(name: "Curry Powder", order: 2, quantity: 2, unit: .tablespoon),
            Ingredient(name: "Coconut Milk", order: 3, quantity: 400, unit: .milliliter),
        ],
        owner: Fixtures.defaultUser
    )

    // MARK: - TodoItem Factories

    static func todoItem(
        title: String,
        details: String,
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        priority: Int = 2,
        category: TodoItemCategory? = nil,
        recurrenceFrequency: RecurrenceFrequency? = nil,
        recurrenceType: RecurrenceType = .flexible,
        owner: User = Fixtures.defaultUser
    ) -> TodoItem {
        TodoItem(
            title: title,
            details: details,
            dueDate: dueDate,
            isCompleted: isCompleted,
            recurrenceFrequency: recurrenceFrequency,
            recurrenceType: recurrenceType,
            priority: priority,
            category: category,
            owner: owner
        )
    }

    static func overdueTodoItem(
        title: String,
        details: String,
        hoursOverdue: Double = 3,
        isCompleted: Bool = false,
        priority: Int = 2,
        category: TodoItemCategory? = nil,
        recurrenceFrequency: RecurrenceFrequency? = nil,
        recurrenceType: RecurrenceType = .flexible,
        owner: User = Fixtures.defaultUser
    ) -> TodoItem {
        todoItem(
            title: title,
            details: details,
            dueDate: Date().addingTimeInterval(-3600 * hoursOverdue),
            isCompleted: isCompleted,
            priority: priority,
            category: category,
            recurrenceFrequency: recurrenceFrequency,
            recurrenceType: recurrenceType,
            owner: owner
        )
    }

    static func todayTodoItem(
        title: String,
        details: String,
        hoursFromNow: Double = 0,
        isCompleted: Bool = false,
        priority: Int = 2,
        category: TodoItemCategory? = nil,
        recurrenceFrequency: RecurrenceFrequency? = nil,
        recurrenceType: RecurrenceType = .flexible,
        owner: User = Fixtures.defaultUser
    ) -> TodoItem {
        let date = Calendar.current.startOfDay(for: Date()).addingTimeInterval(3600 * hoursFromNow)
        return todoItem(
            title: title,
            details: details,
            dueDate: date,
            isCompleted: isCompleted,
            priority: priority,
            category: category,
            recurrenceFrequency: recurrenceFrequency,
            recurrenceType: recurrenceType,
            owner: owner
        )
    }

    static func upcomingTodoItem(
        title: String,
        details: String,
        daysFromNow: Double = 1,
        isCompleted: Bool = false,
        priority: Int = 2,
        category: TodoItemCategory? = nil,
        recurrenceFrequency: RecurrenceFrequency? = nil,
        recurrenceType: RecurrenceType = .flexible,
        owner: User = Fixtures.defaultUser
    ) -> TodoItem {
        todoItem(
            title: title,
            details: details,
            dueDate: Date().addingTimeInterval(3600 * 24 * daysFromNow),
            isCompleted: isCompleted,
            priority: priority,
            category: category,
            recurrenceFrequency: recurrenceFrequency,
            recurrenceType: recurrenceType,
            owner: owner
        )
    }

    static func completedTodoItem(
        title: String,
        details: String,
        dueDate: Date? = nil,
        priority: Int = 2,
        category: TodoItemCategory? = nil,
        recurrenceFrequency: RecurrenceFrequency? = nil,
        recurrenceType: RecurrenceType = .flexible,
        owner: User = Fixtures.defaultUser
    ) -> TodoItem {
        todoItem(
            title: title,
            details: details,
            dueDate: dueDate,
            isCompleted: true,
            priority: priority,
            category: category,
            recurrenceFrequency: recurrenceFrequency,
            recurrenceType: recurrenceType,
            owner: owner
        )
    }
}
