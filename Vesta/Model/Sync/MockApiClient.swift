import Combine
import Foundation
import SwiftData

class MockAPIClient: APIClient {

    private init() {}

    func syncEntities(dtos: [[String: Any]]) -> AnyPublisher<Void, Error> {
        // In a real implementation, this would make actual API calls
        // For now, we'll simulate a network call with a delay
        return Future { promise in
            // Simulate network delay
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                // Simulate occasional network errors
                if arc4random_uniform(10) == 0 {
                    promise(
                        .failure(
                            NSError(
                                domain: "NetworkError", code: 408,
                                userInfo: [NSLocalizedDescriptionKey: "Request timeout"])))
                    return
                }

                print("Successfully synced \(dtos.count) entities")
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    func fetchUpdatedEntities(entityTypes: [String], userId: String) -> AnyPublisher<
        [String: [[String: Any]]], any Error
    > {
        // Simulate fetching updated entities from a remote API
        return Future<[String: [[String: Any]]], Error> { promise in
            // Simulate network delay
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.7) {
                // Simulate occasional network errors (10% chance)
                if arc4random_uniform(10) == 0 {
                    promise(
                        .failure(
                            NSError(
                                domain: "NetworkError", code: 500,
                                userInfo: [NSLocalizedDescriptionKey: "Server error"])))
                    return
                }

                // Create mock response data using Fixtures
                var result: [String: [[String: Any]]] = [:]
                let mockUser = Fixtures.createUser()

                for entityType in entityTypes {
                    var entities: [[String: Any]] = []

                    // Create appropriate entities based on type using Fixtures
                    switch entityType {
                    case "Recipe":
                        // Use the fixtures for recipes
                        let recipes = [
                            Fixtures.bolognese(owner: mockUser),
                            Fixtures.curry(owner: mockUser),
                        ]
                        // Convert to DTOs using existing toDTO method
                        entities = recipes.map { $0.toDTO() }

                    case "TodoItem":
                        // Create todo items using fixtures and convert using toDTO
                        let todoItems = [
                            Fixtures.todayTodoItem(
                                title: "Shop for groceries", details: "Get milk and eggs",
                                owner: mockUser),
                            Fixtures.upcomingTodoItem(
                                title: "Dentist appointment", details: "Regular checkup",
                                daysFromNow: 3, owner: mockUser),
                            Fixtures.completedTodoItem(
                                title: "Pay bills", details: "Electricity and water",
                                owner: mockUser),
                            Fixtures.overdueTodoItem(
                                title: "Call mom", details: "Weekly check-in", hoursOverdue: 24,
                                owner: mockUser),
                        ]
                        // Use the toDTO method from the extension
                        entities = todoItems.map { $0.toDTO() }

                    case "ShoppingListItem":
                        // Create mock shopping list items
                        // Since we can't directly create ShoppingListItem objects without a model,
                        // we'll create mock DTOs manually
                        let items = [
                            ["name": "Milk", "isPurchased": false, "quantity": 1, "unit": "liter"],
                            ["name": "Eggs", "isPurchased": true, "quantity": 12, "unit": "piece"],
                            ["name": "Bread", "isPurchased": false, "quantity": 1, "unit": "loaf"],
                        ]

                        entities = items.map { item in
                            [
                                "entityType": "ShoppingListItem",
                                "uid": UUID().uuidString,
                                "name": item["name"] as! String,
                                "isPurchased": item["isPurchased"] as! Bool,
                                "quantity": item["quantity"] as! Int,
                                "unit": item["unit"] as! String,
                                "ownerId": userId,
                                "lastModified": Date(),
                                "lastModifiedBy": userId,
                            ]
                        }

                    case "User":
                        // Use the user fixture and its toDTO method
                        entities = [mockUser.toDTO()]

                    case "Space":
                        // Create a mock space
                        // Since we can't directly create a Space without a model context,
                        // we'll create a mock DTO
                        let mockSpace: [String: Any] = [
                            "entityType": "Space",
                            "uid": UUID().uuidString,
                            "name": "Home",
                            "ownerId": userId,
                            "lastModified": Date(),
                            "lastModifiedBy": userId,
                            "shareAllRecipes": true,
                            "shareAllMeals": true,
                            "shareAllShoppingItems": true,
                            "memberIds": [userId],
                        ]
                        entities = [mockSpace]

                    case "Meal":
                        // Create mock meal DTOs
                        for i in 0..<Int(arc4random_uniform(3) + 1) {
                            entities.append([
                                "entityType": "Meal",
                                "uid": UUID().uuidString,
                                "ownerId": userId,
                                "lastModifiedBy": userId,
                                "scalingFactor": Double(arc4random_uniform(4) + 1) / 2.0,  // 0.5, 1.0, 1.5, or 2.0
                                "mealType": ["breakfast", "lunch", "dinner", "snack"][
                                    Int(arc4random_uniform(4))],
                                "isDone": Bool.random(),
                            ])
                        }

                    default:
                        // For any other entity types, create generic entities
                        let count = Int(arc4random_uniform(3)) + 1
                        for i in 0..<count {
                            entities.append([
                                "entityType": entityType,
                                "uid": UUID().uuidString,
                                "name": "\(entityType) \(i + 1)",
                                "description": "Mock \(entityType) entity",
                                "ownerId": userId,
                                "lastModified": Date(),
                                "lastModifiedBy": userId,
                            ])
                        }
                    }

                    // Add the entities to the result
                    result[entityType] = entities
                }

                print(
                    "Fetched mock data: \(result.map { "\($0.key): \($0.value.count) items" }.joined(separator: ", "))"
                )
                promise(.success(result))
            }
        }.eraseToAnyPublisher()
    }
}
