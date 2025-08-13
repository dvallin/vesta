import Foundation
import SwiftData

@Model
class Recipe: SyncableEntity {
    @Attribute(.unique) var uid: String

    var title: String
    var details: String

    @Relationship(deleteRule: .noAction)
    var owner: User?

    var isShared: Bool = false
    var dirty: Bool = true

    var deletedAt: Date? = nil
    var expireAt: Date? = nil

    @Relationship(deleteRule: .cascade, inverse: \Ingredient.recipe)
    var ingredients: [Ingredient]

    @Relationship(deleteRule: .cascade, inverse: \RecipeStep.recipe)
    var steps: [RecipeStep]

    @Relationship(deleteRule: .cascade)
    var meals: [Meal]

    var seasonality: Seasonality?
    var mealTypes: [MealType] = []
    var tags: [String] = []

    init(
        title: String, details: String, ingredients: [Ingredient] = [], steps: [RecipeStep] = [],
        owner: User?
    ) {
        self.uid = UUID().uuidString
        self.title = title
        self.details = details
        self.ingredients = []
        self.steps = []
        self.meals = []
        self.owner = owner
        self.dirty = true

        for ingredient in ingredients {
            ingredient.recipe = self
        }
        for step in steps {
            step.recipe = self
        }
    }

    var sortedIngredients: [Ingredient] {
        ingredients.sorted { $0.order < $1.order }
    }

    var sortedSteps: [RecipeStep] {
        steps.sorted { $0.order < $1.order }
    }

    var preparationDuration: TimeInterval {
        steps.filter { $0.type == .preparation }.reduce(0) { $0 + ($1.duration ?? 0) }
    }

    var cookingDuration: TimeInterval {
        steps.filter { $0.type == .cooking }.reduce(0) { $0 + ($1.duration ?? 0) }
    }

    var maturingDuration: TimeInterval {
        steps.filter { $0.type == .maturing }.reduce(0) { $0 + ($1.duration ?? 0) }
    }

    var totalDuration: TimeInterval {
        preparationDuration + cookingDuration + maturingDuration
    }

    var timesCookedRecently: Int {
        meals.filter { meal in
            meal.deletedAt == nil && meal.isDone
        }.count
    }

    var status: RecipeStatus {
        let now = Date()
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now

        // Check if already planned
        let hasUpcomingMeal = meals.contains { meal in
            guard let todoItem = meal.todoItem,
                let dueDate = todoItem.dueDate
            else { return false }
            return dueDate > now && dueDate <= nextWeek && !meal.isDone
        }

        if hasUpcomingMeal {
            return .planned
        }

        // Check if recently made
        let wasRecentlyMade = meals.contains { meal in
            guard let todoItem = meal.todoItem,
                let dueDate = todoItem.dueDate
            else { return false }
            return dueDate >= oneWeekAgo && dueDate <= now && meal.isDone
        }

        if wasRecentlyMade {
            return .recent
        }

        return .normal
    }

    // Mutation methods

    func addIngredient(name: String, quantity: Double?, unit: Unit?, currentUser: User) {
        let newIngredient = Ingredient(
            name: name, order: ingredients.count + 1, quantity: quantity, unit: unit, recipe: self)
        ingredients.append(newIngredient)
        markAsDirty()
    }

    func removeIngredient(_ ingredient: Ingredient, currentUser: User) {
        if let index = ingredients.firstIndex(where: { $0 === ingredient }) {
            ingredients.remove(at: index)
            markAsDirty()
        }
    }

    func moveIngredient(from source: IndexSet, to destination: Int, currentUser: User) {
        var sortedIngredients = self.sortedIngredients

        sortedIngredients.move(fromOffsets: source, toOffset: destination)
        for (index, ingredient) in sortedIngredients.enumerated() {
            ingredient.order = index + 1
        }
        ingredients = sortedIngredients
        markAsDirty()
    }

    func addStep(instruction: String, type: StepType, duration: TimeInterval?, currentUser: User) {
        let newStep = RecipeStep(
            order: steps.count + 1,
            instruction: instruction,
            type: type,
            duration: duration,
            recipe: self
        )
        steps.append(newStep)
        markAsDirty()
    }

    func removeStep(_ step: RecipeStep, currentUser: User) {
        if let index = steps.firstIndex(where: { $0 === step }) {
            steps.remove(at: index)
            markAsDirty()
        }
    }

    func moveStep(from source: IndexSet, to destination: Int, currentUser: User) {
        var sortedSteps = self.sortedSteps

        sortedSteps.move(fromOffsets: source, toOffset: destination)
        for (index, step) in sortedSteps.enumerated() {
            step.order = index + 1
        }
        steps = sortedSteps
        markAsDirty()
    }

    func setTitle(_ newTitle: String, currentUser: User) {
        title = newTitle
        markAsDirty()
    }

    func setDetails(_ newDetails: String, currentUser: User) {
        details = newDetails
        markAsDirty()
    }

    func setSeasonality(_ newSeasonality: Seasonality?, currentUser: User) {
        seasonality = newSeasonality
        markAsDirty()
    }

    func setMealTypes(_ newMealTypes: [MealType], currentUser: User) {
        mealTypes = newMealTypes
        markAsDirty()
    }

    func addTag(_ tag: String, currentUser: User) {
        if !tags.contains(tag) {
            tags.append(tag)
            markAsDirty()
        }
    }

    func removeTag(_ tag: String, currentUser: User) {
        tags.removeAll { $0 == tag }
        markAsDirty()
    }

    func setTags(_ newTags: [String], currentUser: User) {
        tags = newTags
        markAsDirty()
    }

    // MARK: - Soft Delete Operations

    func softDelete(currentUser: User) {
        self.deletedAt = Date()
        self.setExpiration()
        self.markAsDirty()
    }

    func restore(currentUser: User) {
        self.deletedAt = nil
        self.clearExpiration()
        self.markAsDirty()
    }
}

@Model
class Ingredient {
    var name: String
    var order: Int
    var quantity: Double?
    var unit: Unit?

    @Relationship
    var recipe: Recipe?

    init(name: String, order: Int, quantity: Double?, unit: Unit?, recipe: Recipe? = nil) {
        self.name = name
        self.order = order
        self.quantity = quantity
        self.unit = unit
        self.recipe = recipe
    }
}

@Model
class RecipeStep {
    var order: Int
    var instruction: String
    var type: StepType
    var duration: TimeInterval?

    @Relationship
    var recipe: Recipe?

    init(
        order: Int, instruction: String, type: StepType, duration: TimeInterval?,
        recipe: Recipe? = nil
    ) {
        self.order = order
        self.instruction = instruction
        self.type = type
        self.duration = duration
        self.recipe = recipe
    }
}

enum StepType: String, Codable, CaseIterable {
    case preparation
    case cooking
    case maturing

    var displayName: String {
        switch self {
        case .preparation:
            return NSLocalizedString("Preparation", comment: "Preparation step type")
        case .cooking:
            return NSLocalizedString("Cooking", comment: "Cooking step type")
        case .maturing:
            return NSLocalizedString("Maturing", comment: "Maturing step type")
        }
    }
}

enum RecipeStatus {
    case normal
    case planned
    case recent
}

enum Unit: String, Codable, CaseIterable {
    case teaspoon
    case tablespoon
    case cup
    case milliliter
    case liter
    case gram
    case kilogram
    case ounce
    case pound
    case piece

    var displayName: String {
        switch self {
        case .teaspoon:
            return NSLocalizedString("tsp", comment: "Teaspoon unit abbreviation")
        case .tablespoon:
            return NSLocalizedString("tbsp", comment: "Tablespoon unit abbreviation")
        case .cup:
            return NSLocalizedString("cup", comment: "Cup unit abbreviation")
        case .milliliter:
            return NSLocalizedString("ml", comment: "Milliliter unit abbreviation")
        case .liter:
            return NSLocalizedString("l", comment: "Liter unit abbreviation")
        case .gram:
            return NSLocalizedString("g", comment: "Gram unit abbreviation")
        case .kilogram:
            return NSLocalizedString("kg", comment: "Kilogram unit abbreviation")
        case .ounce:
            return NSLocalizedString("oz", comment: "Ounce unit abbreviation")
        case .pound:
            return NSLocalizedString("lb", comment: "Pound unit abbreviation")
        case .piece:
            return NSLocalizedString("pc", comment: "Piece unit abbreviation")
        }
    }
}

enum Seasonality: String, Codable, CaseIterable {
    case spring
    case summer
    case autumn
    case winter
    case yearRound

    var displayName: String {
        switch self {
        case .spring:
            return NSLocalizedString("Spring", comment: "Spring season")
        case .summer:
            return NSLocalizedString("Summer", comment: "Summer season")
        case .autumn:
            return NSLocalizedString("Autumn", comment: "Autumn season")
        case .winter:
            return NSLocalizedString("Winter", comment: "Winter season")
        case .yearRound:
            return NSLocalizedString("Year Round", comment: "Year round availability")
        }
    }

    /// Returns the date interval for this season in the northern hemisphere for a given year
    /// - Parameter year: The year to get the season interval for (defaults to current year)
    /// - Returns: DateInterval representing the season's start and end dates
    func dateInterval(for year: Int = Calendar.current.component(.year, from: Date()))
        -> DateInterval
    {
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = year

        switch self {
        case .spring:
            // March 20 - June 20
            dateComponents.month = 3
            dateComponents.day = 20
            let start = calendar.date(from: dateComponents)!
            dateComponents.month = 6
            dateComponents.day = 20
            let end = calendar.date(from: dateComponents)!
            return DateInterval(start: start, end: end)

        case .summer:
            // June 21 - September 22
            dateComponents.month = 6
            dateComponents.day = 21
            let start = calendar.date(from: dateComponents)!
            dateComponents.month = 9
            dateComponents.day = 22
            let end = calendar.date(from: dateComponents)!
            return DateInterval(start: start, end: end)

        case .autumn:
            // September 23 - December 20
            dateComponents.month = 9
            dateComponents.day = 23
            let start = calendar.date(from: dateComponents)!
            dateComponents.month = 12
            dateComponents.day = 20
            let end = calendar.date(from: dateComponents)!
            return DateInterval(start: start, end: end)

        case .winter:
            // December 21 - March 19 (next year)
            dateComponents.month = 12
            dateComponents.day = 21
            let start = calendar.date(from: dateComponents)!
            dateComponents.year = year + 1
            dateComponents.month = 3
            dateComponents.day = 19
            let end = calendar.date(from: dateComponents)!
            return DateInterval(start: start, end: end)

        case .yearRound:
            // January 1 - December 31
            dateComponents.month = 1
            dateComponents.day = 1
            let start = calendar.date(from: dateComponents)!
            dateComponents.month = 12
            dateComponents.day = 31
            let end = calendar.date(from: dateComponents)!
            return DateInterval(start: start, end: end)
        }
    }
}
