import Combine
import FirebaseFirestore
import Foundation
import os

class FirebaseAPIClient: APIClient {
    private let db = Firestore.firestore()
    private let logger = Logger(subsystem: "com.app.Vesta", category: "Synchronization")

    // MARK: - Public Methods

    /// Fetches updated entities from Firebase based on last sync time
    /// - Parameters:
    ///   - entityTypes: List of entity types to fetch (e.g., "TodoItem", "Recipe")
    ///   - userId: Current user's ID
    /// - Returns: Publisher that emits fetched entities or an error
    func fetchUpdatedEntities(
        entityTypes: [String],
        userId: String
    ) -> AnyPublisher<[String: [[String: Any]]], Error> {
        logger.info("Starting fetch of updated entities for user: \(userId)")

        return Future<[String: [[String: Any]]], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FirebaseError.unknown))
                return
            }

            let lastSyncTimestamp = self.getLastSyncTimestamp(for: userId)
            self.logger.debug("Using last sync time: \(lastSyncTimestamp.dateValue().description)")

            self.fetchUserSpaces(userId: userId) { result in
                switch result {
                case .success(let spaceIds):
                    self.fetchEntitiesForUser(
                        userId: userId,
                        entityTypes: entityTypes,
                        spaceIds: spaceIds,
                        lastSyncTimestamp: lastSyncTimestamp,
                        completion: { result in
                            switch result {
                            case .success(let entities):
                                self.updateLastSyncTime(for: userId, with: entities)
                                promise(.success(entities))
                            case .failure(let error):
                                promise(.failure(error))
                            }
                        }
                    )
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }

    /// Synchronizes local entities to Firebase
    /// - Parameter dtos: Array of entity dictionaries to sync
    /// - Returns: Publisher that emits void on success or error on failure
    func syncEntities(dtos: [[String: Any]]) -> AnyPublisher<Void, Error> {
        logger.info("Starting synchronization of \(dtos.count) entities to Firebase")

        return Future<Void, Error> { promise in
            let batches = self.prepareBatches(from: dtos)

            if batches.batches.isEmpty {
                self.logger.notice("No valid entities to synchronize")
                promise(.success(()))
                return
            }

            self.logger.info(
                "Prepared \(batches.batches.count) batches with total \(batches.validCount) operations (\(batches.skippedCount) entities skipped)"
            )

            self.executeBatches(batches.batches, index: 0) { error in
                if let error = error {
                    self.logger.error(
                        "Batch execution failed: \(error.localizedDescription, privacy: .public)")
                    promise(.failure(error))
                } else {
                    self.logger.notice(
                        "Successfully synchronized \(batches.validCount) entities to Firebase")
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }

    // MARK: - Private Methods - Entity Fetching

    private func getLastSyncTimestamp(for userId: String) -> Timestamp {
        let lastSyncKey = "lastSync_\(userId)"
        let lastSyncDate =
            UserDefaults.standard.object(forKey: lastSyncKey) as? Date
            ?? Date(timeIntervalSince1970: 0)
        return Timestamp(date: lastSyncDate)
    }

    private func fetchUserSpaces(
        userId: String,
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        let spacesQuery = db.collection("space")
            .whereField("memberIds", arrayContains: userId)

        spacesQuery.getDocuments { [weak self] (snapshot, error) in
            guard let self = self else {
                completion(.failure(FirebaseError.unknown))
                return
            }

            if let error = error {
                self.logger.error(
                    "Error fetching user spaces: \(error.localizedDescription, privacy: .public)"
                )
                self.logger.error("Defaulting to empty space list for user: \(userId)")
                completion(.success([]))
                return
            }

            let spaceIds = snapshot?.documents.compactMap { $0.documentID } ?? []
            self.logger.debug("Found \(spaceIds.count) spaces for user")
            completion(.success(spaceIds))
        }
    }

    private func fetchEntitiesForUser(
        userId: String,
        entityTypes: [String],
        spaceIds: [String],
        lastSyncTimestamp: Timestamp,
        completion: @escaping (Result<[String: [[String: Any]]], Error>) -> Void
    ) {
        let group = DispatchGroup()
        var allResults: [String: [[String: Any]]] = [:]
        var fetchError: Error?

        // Initialize result arrays for each entity type
        entityTypes.forEach { allResults[$0] = [] }

        // Process each entity type
        for entityType in entityTypes {
            let entityCollection = db.collection(entityType.lowercased())

            // Fetch owned entities
            group.enter()
            fetchOwnedEntities(
                collection: entityCollection,
                entityType: entityType,
                userId: userId,
                lastSyncTimestamp: lastSyncTimestamp
            ) { result in
                switch result {
                case .success(let entities):
                    allResults[entityType]?.append(contentsOf: entities)
                    self.logger.debug("Fetched \(entities.count) owned \(entityType) documents")
                case .failure(let error):
                    fetchError = error
                }
                group.leave()
            }

            // Fetch shared entities if user has spaces
            if !spaceIds.isEmpty {
                group.enter()
                fetchSharedEntities(
                    collection: entityCollection,
                    entityType: entityType,
                    userId: userId,
                    spaceIds: spaceIds,
                    lastSyncTimestamp: lastSyncTimestamp
                ) { result in
                    switch result {
                    case .success(let entities):
                        allResults[entityType]?.append(contentsOf: entities)
                        self.logger.debug(
                            "Fetched \(entities.count) shared \(entityType) documents")
                    case .failure(let error):
                        fetchError = error
                    }
                    group.leave()
                }
            }
        }

        // When all queries complete, process results
        group.notify(queue: .main) {
            if let error = fetchError {
                completion(.failure(error))
                return
            }

            let totalFetched = allResults.values.flatMap { $0 }.count
            self.logger.info("Successfully fetched \(totalFetched) updated entities")
            completion(.success(allResults))
        }
    }

    private func fetchOwnedEntities(
        collection: CollectionReference,
        entityType: String,
        userId: String,
        lastSyncTimestamp: Timestamp,
        completion: @escaping (Result<[[String: Any]], Error>) -> Void
    ) {
        let query =
            collection
            .whereField("ownerId", isEqualTo: userId)
            .whereField("lastModified", isGreaterThan: lastSyncTimestamp)

        query.getDocuments { [weak self] (snapshot, error) in
            guard let self = self else {
                completion(.failure(FirebaseError.unknown))
                return
            }

            if let error = error {
                self.logger.error(
                    "Error fetching owned \(entityType): \(error.localizedDescription, privacy: .public)"
                )
                completion(.failure(error))
                return
            }

            let results =
                snapshot?.documents.map {
                    self.processDocument($0, entityType: entityType)
                } ?? []

            completion(.success(results))
        }
    }

    private func fetchSharedEntities(
        collection: CollectionReference,
        entityType: String,
        userId: String,
        spaceIds: [String],
        lastSyncTimestamp: Timestamp,
        completion: @escaping (Result<[[String: Any]], Error>) -> Void
    ) {
        let query =
            collection
            .whereField("spaces", arrayContainsAny: spaceIds)
            .whereField("lastModified", isGreaterThan: lastSyncTimestamp)

        query.getDocuments { [weak self] (snapshot, error) in
            guard let self = self else {
                completion(.failure(FirebaseError.unknown))
                return
            }

            if let error = error {
                self.logger.error(
                    "Error fetching shared \(entityType): \(error.localizedDescription, privacy: .public)"
                )
                completion(.failure(error))
                return
            }

            // Filter out entities modified by the current user to avoid duplicates
            let results =
                snapshot?.documents
                .filter { $0.data()["lastModifiedBy"] as? String != userId }
                .map { self.processDocument($0, entityType: entityType) } ?? []

            completion(.success(results))
        }
    }

    private func processDocument(_ document: DocumentSnapshot, entityType: String) -> [String: Any]
    {
        var data = document.data() ?? [:]
        data["uid"] = document.documentID
        data["entityType"] = entityType
        return data
    }

    private func updateLastSyncTime(for userId: String, with entities: [String: [[String: Any]]]) {
        var latestTimestamp: Date?

        // Find the latest modified timestamp
        for entityDocs in entities.values {
            for doc in entityDocs {
                if let timestamp = doc["lastModified"] as? Timestamp {
                    let date = timestamp.dateValue()
                    if latestTimestamp == nil || date > latestTimestamp! {
                        latestTimestamp = date
                    }
                }
            }
        }

        // Update last sync time if we found a newer timestamp
        if let latestDate = latestTimestamp {
            let lastSyncKey = "lastSync_\(userId)"
            UserDefaults.standard.set(latestDate, forKey: lastSyncKey)
            logger.debug("Updated last sync time to: \(latestDate.description)")
        }
    }

    // MARK: - Private Methods - Entity Syncing

    private struct BatchResult {
        let batches: [WriteBatch]
        let validCount: Int
        let skippedCount: Int
    }

    private func prepareBatches(from dtos: [[String: Any]]) -> BatchResult {
        let batchSize = 450  // Slightly less than Firestore's limit of 500
        var batches: [WriteBatch] = []
        var currentBatch = self.db.batch()
        var operationCount = 0
        var validOperations = 0
        var skippedOperations = 0

        for (index, dto) in dtos.enumerated() {
            guard let entityType = dto["entityType"] as? String,
                let uid = dto["uid"] as? String
            else {
                skippedOperations += 1
                logger.warning(
                    "Skipping entity at index \(index): missing required fields (entityType or uid), dto: \(dto, privacy: .private)"
                )
                continue
            }

            // Create document reference and prepare data
            let docRef = db.collection(entityType.lowercased()).document(uid)
            var sanitizedDTO = sanitizeDTO(dto)
            sanitizedDTO["lastModified"] = FieldValue.serverTimestamp()

            // Add to batch
            currentBatch.setData(sanitizedDTO, forDocument: docRef, merge: true)

            validOperations += 1
            operationCount += 1

            logger.debug(
                "Added entity to batch: type=\(entityType), uid=\(uid), batchCount=\(operationCount)"
            )

            // If we've reached batch limit, start a new batch
            if operationCount >= batchSize {
                batches.append(currentBatch)
                logger.info("Batch complete with \(operationCount) operations, creating new batch")
                currentBatch = db.batch()
                operationCount = 0
            }
        }

        // Add final batch if it has operations
        if operationCount > 0 {
            batches.append(currentBatch)
            logger.info("Added final batch with \(operationCount) operations")
        }

        return BatchResult(
            batches: batches,
            validCount: validOperations,
            skippedCount: skippedOperations
        )
    }

    private func executeBatches(
        _ batches: [WriteBatch],
        index: Int,
        completion: @escaping (Error?) -> Void
    ) {
        guard index < batches.count else {
            logger.debug("All batches executed successfully")
            completion(nil)
            return
        }

        let batchNumber = index + 1
        logger.info("Executing batch \(batchNumber)/\(batches.count)")

        let signpostID = OSSignpostID(log: .default)
        os_signpost(
            .begin, log: .default, name: "BatchCommit", signpostID: signpostID, "Batch %d",
            batchNumber
        )

        batches[index].commit { [weak self] error in
            guard let self = self else {
                completion(FirebaseError.unknown)
                return
            }

            os_signpost(
                .end, log: .default, name: "BatchCommit", signpostID: signpostID, "Batch %d",
                batchNumber
            )

            if let error = error {
                self.logger.error(
                    "Batch \(batchNumber) failed: \(error.localizedDescription, privacy: .public)"
                )
                completion(error)
                return
            }

            self.logger.info("Batch \(batchNumber) committed successfully")

            // Continue with the next batch
            self.executeBatches(batches, index: index + 1, completion: completion)
        }
    }

    private func sanitizeDTO(_ dto: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]

        for (key, value) in dto {
            if let date = value as? Date {
                // Convert Date to Timestamp for Firestore
                result[key] = Timestamp(date: date)
            } else if let array = value as? [[String: Any]] {
                // Recursively sanitize arrays of dictionaries
                result[key] = array.map { sanitizeDTO($0) }
            } else if let nestedDict = value as? [String: Any] {
                // Recursively sanitize nested dictionaries
                result[key] = sanitizeDTO(nestedDict)
            } else {
                // Use the value as is
                result[key] = value
            }
        }

        return result
    }
}

// MARK: - Error Types
extension FirebaseAPIClient {
    enum FirebaseError: Error {
        case batchWriteFailure
        case invalidEntityData
        case unknown
    }
}
