import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Foundation

class FirebaseAPIClient: APIClient {
    static let shared = FirebaseAPIClient()

    private let db = Firestore.firestore()
    private var userId: String? {
        return Auth.auth().currentUser?.uid
    }

    private init() {}

    func syncEntities(entityName: String, dtos: [[String: Any]]) -> AnyPublisher<
        Void, Error
    > {
        guard let userId = userId else {
            return Fail(error: SyncError.notAuthenticated).eraseToAnyPublisher()
        }

        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(SyncError.unknown))
                return
            }

            // Create a batch
            let batch = self.db.batch()

            for dto in dtos {
                // Ensure each entity has an ID
                guard let id = dto["id"] as? String else {
                    print("Error: Entity missing ID")
                    continue
                }

                // Add ownership info
                var enrichedDTO = dto
                enrichedDTO["ownerId"] = userId
                enrichedDTO["lastSynced"] = FieldValue.serverTimestamp()

                // Create document reference
                let docRef = self.db.collection("users").document(userId)
                    .collection(entityName).document(id)

                // Add to batch
                batch.setData(enrichedDTO, forDocument: docRef, merge: true)
            }

            // Commit the batch
            batch.commit { error in
                if let error = error {
                    print("Error syncing \(entityName): \(error.localizedDescription)")
                    promise(.failure(error))
                } else {
                    print("Successfully synced \(dtos.count) \(entityName) entities to Firebase")
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }

    func fetchEntities<T: SyncableEntity>(entityName: String) -> AnyPublisher<[T], Error> {
        guard let userId = userId else {
            return Fail(error: SyncError.notAuthenticated).eraseToAnyPublisher()
        }

        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(SyncError.unknown))
                return
            }

            self.db.collection("users").document(userId).collection(entityName)
                .getDocuments { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        promise(.success([]))
                        return
                    }

                    // Convert Firebase documents to DTOs
                    // Note: This part is a placeholder - you'll need to implement
                    // proper conversion based on your entity types
                    let entities: [T] = []
                    promise(.success(entities))
                }
        }.eraseToAnyPublisher()
    }
}
