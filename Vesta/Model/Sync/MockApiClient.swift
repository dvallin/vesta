import Combine
import Foundation
import SwiftData

class MockAPIClient: APIClient {
    private init() {}

    func syncEntities(entityName: String, dtos: [[String: Any]]) -> AnyPublisher<Void, Error> {
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

                print("Successfully synced \(dtos.count) \(entityName) entities")
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }
}
