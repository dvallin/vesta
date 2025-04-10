import Combine
import FirebaseFirestore
import Foundation
import os

class FirebaseAPIClient: APIClient {
    private let db = Firestore.firestore()

    // Configure logger with appropriate subsystem and category
    private let logger = Logger(
        subsystem: "com.app.Vesta",
        category: "Synchronization"
    )

    /// Fetches updated entities from Firebase based on last sync time
    /// - Parameters:
    ///   - entityTypes: List of entity types to fetch (e.g., "TodoItem", "Recipe")
    ///   - userId: Current user's ID
    ///   - lastSyncTime: Timestamp of the last successful sync
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

            // Get last sync time from UserDefaults or use epoch if not available
            let lastSyncKey = "lastSync_\(userId)"
            let lastSyncDate =
                UserDefaults.standard.object(forKey: lastSyncKey) as? Date
                ?? Date(timeIntervalSince1970: 0)
            let lastSyncTimestamp = Timestamp(date: lastSyncDate)

            self.logger.debug("Using last sync time: \(lastSyncDate.description)")

            // First, get all spaces the current user is a member of
            let spacesQuery = self.db.collection("space")
                .whereField("memberIds", arrayContains: userId)

            spacesQuery.getDocuments { (spaceSnapshot, spaceError) in
                if let error = spaceError {
                    self.logger.error(
                        "Error fetching user spaces: \(error.localizedDescription, privacy: .public)"
                    )
                    promise(.failure(error))
                    return
                }

                // Extract space IDs
                let spaceIds = spaceSnapshot?.documents.compactMap { $0.documentID } ?? []
                self.logger.debug("Found \(spaceIds.count) spaces for user")

                // Create a dispatch group to track completion of all queries
                let group = DispatchGroup()
                var allResults: [String: [[String: Any]]] = [:]
                var fetchError: Error?

                // Process each entity type
                for entityType in entityTypes {
                    allResults[entityType] = []
                    let entityCollection = self.db.collection(entityType.lowercased())

                    // Query 1: Fetch entities owned by the user and modified after last sync
                    group.enter()
                    let ownedQuery =
                        entityCollection
                        .whereField("ownerId", isEqualTo: userId)
                        .whereField("lastModified", isGreaterThan: lastSyncTimestamp)

                    ownedQuery.getDocuments { (ownedSnapshot, ownedError) in
                        if let error = ownedError {
                            self.logger.error(
                                "Error fetching owned \(entityType): \(error.localizedDescription, privacy: .public)"
                            )
                            fetchError = error
                            group.leave()
                            return
                        }

                        if let docs = ownedSnapshot?.documents {
                            let results = docs.map {
                                self.processDocument($0, entityType: entityType)
                            }
                            allResults[entityType]?.append(contentsOf: results)
                            self.logger.debug("Fetched \(docs.count) owned \(entityType) documents")
                        }
                        group.leave()
                    }

                    // Only proceed with spaces query if we have spaces
                    if !spaceIds.isEmpty {
                        // Query 2: Fetch entities shared in the user's spaces and modified after last sync
                        group.enter()
                        let sharedQuery =
                            entityCollection
                            .whereField("spaces", arrayContainsAny: spaceIds)
                            .whereField("lastModified", isGreaterThan: lastSyncTimestamp)

                        sharedQuery.getDocuments { (sharedSnapshot, sharedError) in
                            if let error = sharedError {
                                self.logger.error(
                                    "Error fetching shared \(entityType): \(error.localizedDescription, privacy: .public)"
                                )
                                fetchError = error
                                group.leave()
                                return
                            }

                            if let docs = sharedSnapshot?.documents {
                                // Filter out entities that were modified by the current user to avoid duplicates with owned query
                                let results =
                                    docs
                                    .filter { $0.data()["lastModifiedBy"] as? String != userId }
                                    .map { self.processDocument($0, entityType: entityType) }
                                allResults[entityType]?.append(contentsOf: results)
                                self.logger.debug(
                                    "Fetched \(results.count) shared \(entityType) documents")
                            }
                            group.leave()
                        }
                    } else {
                        self.logger.debug("User has no spaces, skipping shared entities query")
                    }
                }

                // When all queries complete, process results
                group.notify(queue: .main) {
                    if let error = fetchError {
                        promise(.failure(error))
                        return
                    }

                    // Find the latest modified timestamp to update the last sync time
                    var latestTimestamp: Date?

                    for entityDocs in allResults.values {
                        for doc in entityDocs {
                            if let timestamp = doc["lastModified"] as? Timestamp {
                                let date = timestamp.dateValue()
                                if latestTimestamp == nil || date > latestTimestamp! {
                                    latestTimestamp = date
                                }
                            }
                        }
                    }

                    // Update lastSync time if we found a newer timestamp
                    if let latestDate = latestTimestamp {
                        UserDefaults.standard.set(latestDate, forKey: lastSyncKey)
                        self.logger.debug("Updated last sync time to: \(latestDate.description)")
                    }

                    let totalFetched = allResults.values.flatMap { $0 }.count
                    self.logger.info("Successfully fetched \(totalFetched) updated entities")
                    promise(.success(allResults))
                }
            }
        }.eraseToAnyPublisher()
    }

    private func processDocument(_ document: DocumentSnapshot, entityType: String) -> [String: Any]
    {
        var data = document.data() ?? [:]
        data["uid"] = document.documentID
        data["entityType"] = entityType

        return data
    }

    func syncEntities(dtos: [[String: Any]]) -> AnyPublisher<Void, Error> {
        logger.info("Starting synchronization of \(dtos.count) entities to Firebase")

        return Future<Void, Error> { promise in
            // Use batches to efficiently write multiple documents
            // Firestore has a limit of 500 operations per batch, so we might need multiple batches
            let batchSize = 450  // Slightly less than 500 to be safe
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
                    self.logger.warning(
                        "Skipping entity at index \(index): missing required fields (entityType or uid), dto: \(dto, privacy: .private)"
                    )
                    continue  // Skip if missing required fields
                }
                // Create a reference to the document based on the entity type and id
                let docRef = self.db.collection(entityType.lowercased()).document(uid)

                // Add write operation to the current batch
                var sanitizedDTO = self.sanitizeDTO(dto)
                sanitizedDTO["lastModified"] = FieldValue.serverTimestamp()

                currentBatch.setData(sanitizedDTO, forDocument: docRef, merge: true)

                validOperations += 1
                operationCount += 1

                self.logger.debug(
                    "Added entity to batch: type=\(entityType), uid=\(uid), batchCount=\(operationCount)"
                )

                // If we've reached the batch limit, create a new batch
                if operationCount >= batchSize {
                    batches.append(currentBatch)
                    self.logger.info(
                        "Batch complete with \(operationCount) operations, creating new batch")
                    currentBatch = self.db.batch()
                    operationCount = 0
                }
            }

            // Add the last batch if it has any operations
            if operationCount > 0 {
                batches.append(currentBatch)
                self.logger.info("Added final batch with \(operationCount) operations")
            }

            // If no batches, we're done
            if batches.isEmpty {
                self.logger.notice("No valid entities to synchronize")
                promise(.success(()))
                return
            }

            self.logger.info(
                "Prepared \(batches.count) batches with total \(validOperations) operations (\(skippedOperations) entities skipped)"
            )

            // Execute all batches in sequence
            self.executeBatches(batches, index: 0) { error in
                if let error = error {
                    self.logger.error(
                        "Batch execution failed: \(error.localizedDescription, privacy: .public)")
                    promise(.failure(error))
                } else {
                    self.logger.notice(
                        "Successfully synchronized \(validOperations) entities to Firebase")
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // Helper function to execute batches sequentially
    private func executeBatches(
        _ batches: [WriteBatch], index: Int, completion: @escaping (Error?) -> Void
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
            batchNumber)

        batches[index].commit { error in
            os_signpost(
                .end, log: .default, name: "BatchCommit", signpostID: signpostID, "Batch %d",
                batchNumber)

            if let error = error {
                self.logger.error(
                    "Batch \(batchNumber) failed: \(error.localizedDescription, privacy: .public)")
                completion(error)
                return
            }

            self.logger.info("Batch \(batchNumber) committed successfully")

            // Continue with the next batch
            self.executeBatches(batches, index: index + 1, completion: completion)
        }
    }

    // Process the DTO to ensure all values are Firestore-compatible
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

// Add specific Firebase-related errors
extension FirebaseAPIClient {
    enum FirebaseError: Error {
        case batchWriteFailure
        case invalidEntityData
        case unknown
    }
}
