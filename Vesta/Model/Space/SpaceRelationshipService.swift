import Foundation
import SwiftData

class SpaceRelationshipService {
    private let modelContext: ModelContext
    private let auth: UserAuthService

    init(modelContext: ModelContext, auth: UserAuthService) {
        self.modelContext = modelContext
        self.auth = auth
    }

    // MARK: - Single Entity Update Methods

    /// Updates space relationships for a single recipe
    func updateSpaceRelationships(for recipe: Recipe) throws {
        let spaces = try fetchAllSpaces()
        updateSpaces(for: recipe, spaces: spaces)
    }

    /// Updates space relationships for a single meal
    func updateSpaceRelationships(for meal: Meal) throws {
        let spaces = try fetchAllSpaces()
        updateSpaces(for: meal, spaces: spaces)
    }

    /// Updates space relationships for a single shopping list item
    func updateSpaceRelationships(for shoppingItem: ShoppingListItem) throws {
        let spaces = try fetchAllSpaces()
        updateSpaces(for: shoppingItem, spaces: spaces)
    }

    /// Updates space relationships for a single todo item
    func updateSpaceRelationships(for todoItem: TodoItem) throws {
        let spaces = try fetchAllSpaces()
        updateSpaces(for: todoItem, spaces: spaces)
    }

    /// Updates space relationships for all entities owned by a specific user
    func updateAllSpaceRelationships(for user: User) throws {
        // Fetch all entities owned by this user
        let spaces = try fetchAllSpaces()
        let recipes = try fetchRecipes(ownedBy: user)
        let meals = try fetchMeals(ownedBy: user)
        let shoppingItems = try fetchShoppingItems(ownedBy: user)
        let todoItems = try fetchTodoItems(ownedBy: user)

        // Update relationships for each entity
        for recipe in recipes {
            updateSpaces(for: recipe, spaces: spaces)
        }

        for meal in meals {
            updateSpaces(for: meal, spaces: spaces)
        }

        for item in shoppingItems {
            updateSpaces(for: item, spaces: spaces)
        }

        for todoItem in todoItems {
            updateSpaces(for: todoItem, spaces: spaces)
        }
    }

    // MARK: - Additional Fetch Methods

    private func fetchAllSpaces() throws -> [Space] {
        let fetchDescriptor = FetchDescriptor<Space>()
        return try modelContext.fetch(fetchDescriptor)
    }

    private func fetchRecipes(ownedBy user: User) throws -> [Recipe] {
        let fetchDescriptor = FetchDescriptor<Recipe>()
        let allRecipes = try modelContext.fetch(fetchDescriptor)
        return allRecipes.filter { $0.owner?.id == user.id }
    }

    private func fetchMeals(ownedBy user: User) throws -> [Meal] {
        let fetchDescriptor = FetchDescriptor<Meal>()
        let allMeals = try modelContext.fetch(fetchDescriptor)
        return allMeals.filter { $0.owner?.id == user.id }
    }

    private func fetchShoppingItems(ownedBy user: User) throws -> [ShoppingListItem] {
        let fetchDescriptor = FetchDescriptor<ShoppingListItem>()
        let allItems = try modelContext.fetch(fetchDescriptor)
        return allItems.filter { $0.owner?.id == user.id }
    }

    private func fetchTodoItems(ownedBy user: User) throws -> [TodoItem] {
        let fetchDescriptor = FetchDescriptor<TodoItem>()
        let allItems = try modelContext.fetch(fetchDescriptor)
        return allItems.filter { $0.owner?.id == user.id }
    }

    // MARK: - Relationship Update Methods

    private func updateSpaces(for recipe: Recipe, spaces: [Space]) {
        guard let currentUser = auth.currentUser else { return }
        guard let owner = recipe.owner else { return }

        var newSpaces: [Space] = []

        // Find spaces that should include this recipe
        for space in spaces {
            // Check if owner is a member of the space AND sharing all recipes is enabled
            if space.members.contains(where: { $0.id == owner.id }) && space.shareAllRecipes {
                newSpaces.append(space)
            }
        }

        // Check if spaces have changed
        if !areSpaceArraysEqual(recipe.spaces, newSpaces) {
            recipe.spaces = newSpaces
            recipe.markAsDirty(currentUser)
        }
    }

    private func updateSpaces(for meal: Meal, spaces: [Space]) {
        guard let currentUser = auth.currentUser else { return }
        guard let owner = meal.owner else { return }

        var newSpaces: [Space] = []

        // Find spaces that should include this meal
        for space in spaces {
            // Check if owner is a member of the space AND sharing all meals is enabled
            if space.members.contains(where: { $0.id == owner.id }) && space.shareAllMeals {
                newSpaces.append(space)
            }
        }

        // Check if spaces have changed
        if !areSpaceArraysEqual(meal.spaces, newSpaces) {
            meal.spaces = newSpaces
            meal.markAsDirty(currentUser)
        }
    }

    private func updateSpaces(for shoppingItem: ShoppingListItem, spaces: [Space]) {
        guard let currentUser = auth.currentUser else { return }
        guard let owner = shoppingItem.owner else { return }

        var newSpaces: [Space] = []

        // Find spaces that should include this shopping item
        for space in spaces {
            // Check if owner is a member of the space AND sharing all shopping items is enabled
            if space.members.contains(where: { $0.id == owner.id }) && space.shareAllShoppingItems {
                newSpaces.append(space)
            }
        }

        // Check if spaces have changed
        if !areSpaceArraysEqual(shoppingItem.spaces, newSpaces) {
            shoppingItem.spaces = newSpaces
            shoppingItem.markAsDirty(currentUser)
        }
    }

    private func updateSpaces(for todoItem: TodoItem, spaces: [Space]) {
        guard let currentUser = auth.currentUser else { return }
        guard let owner = todoItem.owner else { return }

        var newSpaces: [Space] = []

        // Find spaces that should include this todo item
        for space in spaces {
            // Check if owner is a member of the space AND the todo item's category is in the space's shared categories
            if space.members.contains(where: { $0.id == owner.id })
                && (todoItem.category != nil
                    && space.sharedCategories.contains(where: {
                        $0.name == todoItem.category?.name
                    }))
            {
                newSpaces.append(space)
            }
        }

        // Check if spaces have changed
        if !areSpaceArraysEqual(todoItem.spaces, newSpaces) {
            todoItem.spaces = newSpaces
            todoItem.markAsDirty(currentUser)

            // Update spaces for todoItem events
            for event in todoItem.events {
                event.spaces = newSpaces
                event.markAsDirty(currentUser)
            }
        }
    }

    // MARK: - Helper Methods

    /// Compare two arrays of spaces for equality (based on space IDs)
    private func areSpaceArraysEqual(_ first: [Space], _ second: [Space]) -> Bool {
        guard first.count == second.count else { return false }

        let firstIds = Set(first.map { $0.id })
        let secondIds = Set(second.map { $0.id })

        return firstIds == secondIds
    }
}
