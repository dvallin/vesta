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
                let sanitizedDTO = self.sanitizeDTO(dto)
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
    }
}
