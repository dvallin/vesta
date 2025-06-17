import Combine
import Foundation
import SwiftData

class MockAPIClient: SyncAPIClient {

    private init() {}

    // Dictionary to store mock subscription handlers
    private var activeSubscriptions:
        [String: PassthroughSubject<[String: [[String: Any]]], Never>] = [:]

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

    func fetchUpdatedEntities(userId: String) -> AnyPublisher<
        [String: [[String: Any]]], Error
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

                // Define entity types to generate - this used to be passed as a parameter
                let entityTypes = ["User", "TodoItem", "Recipe", "Meal", "ShoppingListItem"]

                // Generate mock data for each entity type
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
                            ]
                        }

                    case "User":
                        // Use the user fixture and its toDTO method
                        // Note: User is now stored differently but still represented the same way in the response
                        entities = [mockUser.toDTO()]

                    case "Meal":
                        // Create mock meal DTOs
                        for i in 0..<Int(arc4random_uniform(3) + 1) {
                            entities.append([
                                "entityType": "Meal",
                                "uid": UUID().uuidString,
                                "ownerId": userId,
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

    /// Subscribes to real-time updates for a user's entities
    /// - Parameters:
    ///   - userId: The ID of the user whose entities to subscribe to
    ///   - onUpdate: Callback function triggered when entities are updated
    /// - Returns: A cancellable object that, when cancelled, will unsubscribe from updates
    func subscribeToEntityUpdates(
        for userId: String,
        onUpdate: @escaping (_ entityData: [String: [[String: Any]]]) -> Void
    ) -> AnyCancellable {
        print("Setting up mock real-time subscription for user: \(userId)")

        // Create a subject for this subscription if it doesn't exist
        let subject =
            activeSubscriptions[userId] ?? PassthroughSubject<[String: [[String: Any]]], Never>()
        activeSubscriptions[userId] = subject

        // Set up a timer to simulate periodic updates
        let timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // 30% chance of sending an update on each timer fire
            if arc4random_uniform(100) < 30 {
                // Generate a random entity update
                self.generateRandomUpdate(for: userId) { update in
                    // Dispatch to main thread as the real implementation would
                    DispatchQueue.main.async {
                        onUpdate(update)
                        subject.send(update)
                    }
                }
            }
        }

        // Return a cancellable that cleans up when cancelled
        return AnyCancellable {
            print("Cancelling mock real-time subscription for user: \(userId)")
            timer.invalidate()
            // We keep the subject in case it's used by other subscribers,
            // but we could also remove it if this is the only subscriber
        }
    }

    // Helper method to generate random entity updates
    private func generateRandomUpdate(
        for userId: String, completion: @escaping ([String: [[String: Any]]]) -> Void
    ) {
        DispatchQueue.global().async {
            // Generate a random entity type to update
            let entityTypes = ["User", "TodoItem", "Recipe", "Meal", "ShoppingListItem"]
            let randomType = entityTypes[Int(arc4random_uniform(UInt32(entityTypes.count)))]

            var result: [String: [[String: Any]]] = [:]

            if randomType == "User" {
                // Update user information
                let mockUser = Fixtures.createUser()
                result["User"] = [mockUser.toDTO()]
            } else {
                // Create a random entity of the selected type
                var entity: [String: Any] = [
                    "entityType": randomType,
                    "uid": UUID().uuidString,
                    "ownerId": userId,
                    "lastModified": Date(),
                    "isShared": Bool.random(),
                ]

                // Add type-specific fields
                switch randomType {
                case "TodoItem":
                    entity["title"] = "Updated task \(Int(arc4random_uniform(100)))"
                    entity["details"] = "This task was updated via real-time sync"
                    entity["isCompleted"] = Bool.random()
                    entity["priority"] = Int(arc4random_uniform(3))

                case "Recipe":
                    entity["title"] = "Updated recipe \(Int(arc4random_uniform(100)))"
                    entity["details"] = "This recipe was updated via real-time sync"

                case "Meal":
                    entity["scalingFactor"] = Double(arc4random_uniform(4) + 1) / 2.0
                    entity["mealType"] =
                        ["breakfast", "lunch", "dinner", "snack"][Int(arc4random_uniform(4))]
                    entity["isDone"] = Bool.random()

                case "ShoppingListItem":
                    entity["name"] = "Updated item \(Int(arc4random_uniform(100)))"
                    entity["isPurchased"] = Bool.random()
                    entity["quantity"] = Int(arc4random_uniform(10) + 1)

                default:
                    entity["name"] = "Updated \(randomType) \(Int(arc4random_uniform(100)))"
                    entity["description"] = "This entity was updated via real-time sync"
                }

                result[randomType] = [entity]
            }

            print("Generated mock real-time update for \(randomType)")
            completion(result)
        }
    }
}
