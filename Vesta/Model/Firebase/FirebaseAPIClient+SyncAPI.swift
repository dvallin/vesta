import Combine
import FirebaseFirestore
import Foundation
import os

// MARK: - SyncAPIClient Implementation
extension FirebaseAPIClient: SyncAPIClient {
    // MARK: - Public Methods

    /// Fetches updated entities from Firebase based on last sync time
    /// - Parameters:
    ///   - userId: Current user's ID
    /// - Returns: Publisher that emits fetched entities or an error
    func fetchUpdatedEntities(
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

            // Get all entities including shared ones from friends
            self.fetchEntitiesForUserAndFriends(
                userId: userId,
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

        // Try to get the stored timestamp components
        if let seconds = UserDefaults.standard.object(forKey: "\(lastSyncKey)_seconds") as? Int64,
            let nanoseconds = UserDefaults.standard.object(forKey: "\(lastSyncKey)_nanoseconds")
                as? Int32
        {
            return Timestamp(seconds: seconds, nanoseconds: nanoseconds)
        }

        // Fallback to the old way or default
        let lastSyncDate =
            UserDefaults.standard.object(forKey: lastSyncKey) as? Date
            ?? Date(timeIntervalSince1970: 0)
        return Timestamp(date: lastSyncDate)
    }

    private func fetchEntitiesForUserAndFriends(
        userId: String,
        lastSyncTimestamp: Timestamp,
        completion: @escaping (Result<[String: [[String: Any]]], Error>) -> Void
    ) {
        let group = DispatchGroup()
        var allResults: [String: [[String: Any]]] = [:]
        var fetchError: Error?
        var friendIds: [String] = []

        // First, fetch the user document to get friend IDs
        group.enter()
        let userDocRef = db.collection("users").document(userId)
        userDocRef.getDocument { [weak self] (document, error) in
            guard let self = self else {
                // Create an atomic operation by updating using the notify queue
                DispatchQueue.global().async {
                    fetchError = FirebaseError.unknown
                    group.leave()
                }
                return
            }

            if let error = error {
                self.logger.error(
                    "Error fetching user document: \(error.localizedDescription, privacy: .public)")
                // Don't fail the entire operation for this - just log and continue
                group.leave()
                return
            }

            if let document = document, document.exists {
                let data = document.data() ?? [:]
                var localFriendIds: [String] = []

                // Always add user document regardless of last modified timestamp
                // This ensures we always have the latest user data
                var userData = data
                userData["uid"] = document.documentID
                userData["entityType"] = "User"
                userData["ownerId"] = document.documentID  // Ensure ownerId is set

                // Initialize User array if it doesn't exist
                if allResults["User"] == nil {
                    allResults["User"] = []
                }

                // Add to User results
                allResults["User"]?.append(userData)
                self.logger.debug("Added current user document to results: \(document.documentID)")

                // Store the user's friend IDs for later use
                if let friends = data["friendIds"] as? [String] {
                    localFriendIds = friends
                    self.logger.debug("User has \(friends.count) friends")
                    
                    // Store friend IDs for processing
                    DispatchQueue.global().async {
                        friendIds = localFriendIds
                    }
                }
            }

            group.leave()
        }

        // Wait for user fetch to complete before proceeding
        group.notify(queue: .global(qos: .userInitiated)) { [weak self] in
            guard let self = self else {
                completion(.failure(FirebaseError.unknown))
                return
            }

            let mainGroup = DispatchGroup()

            // Create thread synchronization objects
            let resultQueue = DispatchQueue(label: "com.app.Vesta.resultQueue")
            let errorQueue = DispatchQueue(label: "com.app.Vesta.errorQueue")

            // Fetch friend user documents first
            for friendId in friendIds {
                mainGroup.enter()
                self.fetchFriendUserDocument(
                    friendId: friendId,
                    lastSyncTimestamp: lastSyncTimestamp,
                    resultQueue: resultQueue,
                    resultsDict: allResults,
                    errorQueue: errorQueue,
                    errorRef: fetchError,
                    group: mainGroup
                )
            }

            // Fetch user's own entities
            mainGroup.enter()
            self.fetchEntitiesForUser(
                userId: userId,
                lastSyncTimestamp: lastSyncTimestamp,
                resultQueue: resultQueue,
                resultsDict: allResults,
                errorQueue: errorQueue,
                errorRef: fetchError,
                group: mainGroup
            )

            // Fetch shared entities from each friend
            for friendId in friendIds {
                mainGroup.enter()
                self.fetchSharedEntitiesFromFriend(
                    friendId: friendId,
                    lastSyncTimestamp: lastSyncTimestamp,
                    resultQueue: resultQueue,
                    resultsDict: allResults,
                    errorQueue: errorQueue,
                    errorRef: fetchError,
                    group: mainGroup
                )
            }

            // When all fetches complete, process results
            mainGroup.notify(queue: .main) {
                if let error = fetchError {
                    completion(.failure(error))
                    return
                }

                let totalFetched = allResults.values.flatMap { $0 }.count
                self.logger.info(
                    "Successfully fetched \(totalFetched) updated entities (including shared)")
                completion(.success(allResults))
            }
        }
    }

    private func fetchEntitiesForUser(
        userId: String,
        lastSyncTimestamp: Timestamp,
        resultQueue: DispatchQueue,
        resultsDict: [String: [[String: Any]]],
        errorQueue: DispatchQueue,
        errorRef: Error?,
        group: DispatchGroup
    ) {
        // Get reference to user's entities collection
        let entitiesCollection = db.collection("users").document(userId).collection("entities")

        // Fetch all entities from the user's entities collection
        entitiesCollection
            .whereField("lastModified", isGreaterThan: lastSyncTimestamp)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else {
                    errorQueue.sync {
                        _ = errorRef != nil ? errorRef : FirebaseError.unknown
                    }
                    group.leave()
                    return
                }

                if let error = error {
                    self.logger.error(
                        "Error fetching entities: \(error.localizedDescription, privacy: .public)"
                    )
                    errorQueue.sync {
                        _ = errorRef != nil ? errorRef : error
                    }
                    group.leave()
                    return
                }

                guard let documents = snapshot?.documents else {
                    group.leave()
                    return
                }

                // Use a local collection to gather results
                var localResults = [String: [[String: Any]]]()

                // Process documents and organize by entity type
                for document in documents {
                    var data = document.data()
                    data["uid"] = document.documentID

                    // Group entities by entity type
                    guard let entityType = data["entityType"] as? String else {
                        self.logger.warning(
                            "Entity missing entityType field: \(document.documentID)")
                        continue
                    }

                    // Initialize array for this entity type if it doesn't exist
                    if localResults[entityType] == nil {
                        localResults[entityType] = []
                    }

                    // Add to appropriate array
                    localResults[entityType]?.append(data)
                }

                // Now merge the results back into the shared dictionary in a thread-safe way
                resultQueue.sync {
                    var mutableResultsDict = resultsDict
                    for (entityType, entities) in localResults {
                        var existingEntities = mutableResultsDict[entityType] ?? []
                        existingEntities.append(contentsOf: entities)
                        mutableResultsDict[entityType] = existingEntities
                    }
                }

                self.logger.debug(
                    "Fetched \(documents.count) entities from collection for user \(userId)")
                group.leave()
            }
    }

    /// Fetches the friend's user document if it has been modified since last sync
    private func fetchFriendUserDocument(
        friendId: String,
        lastSyncTimestamp: Timestamp,
        resultQueue: DispatchQueue,
        resultsDict: [String: [[String: Any]]],
        errorQueue: DispatchQueue,
        errorRef: Error?,
        group: DispatchGroup
    ) {
        // Get reference to friend's user document
        let friendDocRef = db.collection("users").document(friendId)
        
        // Fetch the friend's user document
        friendDocRef.getDocument { [weak self] (document, error) in
            guard let self = self else {
                errorQueue.sync {
                    _ = errorRef != nil ? errorRef : FirebaseError.unknown
                }
                group.leave()
                return
            }
            
            if let error = error {
                self.logger.error(
                    "Error fetching friend user document \(friendId): \(error.localizedDescription, privacy: .public)"
                )
                // Don't fail the entire operation for this - just log and continue
                group.leave()
                return
            }
            
            guard let document = document, document.exists else {
                group.leave()
                return
            }
            
            let data = document.data() ?? [:]
            
            // Check if friend document was modified since last sync
            if let lastModified = data["lastModified"] as? Timestamp,
               lastModified.compare(lastSyncTimestamp) == .orderedDescending {
                
                // Add entityType and other required fields for consistency
                var userData = data
                userData["uid"] = document.documentID
                userData["entityType"] = "User"
                userData["ownerId"] = document.documentID
                
                // Add to results in a thread-safe way
                resultQueue.sync {
                    var mutableResultsDict = resultsDict
                    if mutableResultsDict["User"] == nil {
                        mutableResultsDict["User"] = []
                    }
                    mutableResultsDict["User"]?.append(userData)
                }
                
                self.logger.debug("Added friend user document to results: \(document.documentID)")
            } else {
                self.logger.debug("Friend user document \(friendId) not modified since last sync")
            }
            
            group.leave()
        }
    }
    
    private func fetchSharedEntitiesFromFriend(
        friendId: String,
        lastSyncTimestamp: Timestamp,
        resultQueue: DispatchQueue,
        resultsDict: [String: [[String: Any]]],
        errorQueue: DispatchQueue,
        errorRef: Error?,
        group: DispatchGroup
    ) {
        // Get reference to friend's entities collection
        let friendEntitiesCollection = db.collection("users").document(friendId).collection(
            "entities")

        // Fetch only shared entities from the friend's collection
        friendEntitiesCollection
            .whereField("isShared", isEqualTo: true)
            .whereField("lastModified", isGreaterThan: lastSyncTimestamp)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else {
                    errorQueue.sync {
                        _ = errorRef != nil ? errorRef : FirebaseError.unknown
                    }
                    group.leave()
                    return
                }

                if let error = error {
                    self.logger.error(
                        "Error fetching shared entities from friend \(friendId): \(error.localizedDescription, privacy: .public)"
                    )
                    // Don't fail the entire operation for this - just log and continue
                    group.leave()
                    return
                }

                guard let documents = snapshot?.documents else {
                    group.leave()
                    return
                }

                // Use a local collection to gather results
                var localResults = [String: [[String: Any]]]()

                // Process documents and organize by entity type
                for document in documents {
                    var data = document.data()
                    data["uid"] = document.documentID

                    // Group entities by entity type
                    guard let entityType = data["entityType"] as? String else {
                        self.logger.warning(
                            "Entity missing entityType field: \(document.documentID)")
                        continue
                    }

                    // Initialize array for this entity type if it doesn't exist
                    if localResults[entityType] == nil {
                        localResults[entityType] = []
                    }

                    // Add to appropriate array
                    localResults[entityType]?.append(data)
                }

                // Now merge the results back into the shared dictionary in a thread-safe way
                resultQueue.sync {
                    var mutableResultsDict = resultsDict
                    for (entityType, entities) in localResults {
                        var existingEntities = mutableResultsDict[entityType] ?? []
                        existingEntities.append(contentsOf: entities)
                        mutableResultsDict[entityType] = existingEntities
                    }
                }

                self.logger.debug(
                    "Fetched \(documents.count) shared entities from friend \(friendId)")
                group.leave()
            }
    }

    private func updateLastSyncTime(for userId: String, with entities: [String: [[String: Any]]]) {
        var latestTimestamp: Timestamp?

        // Find the latest modified timestamp
        for entityDocs in entities.values {
            for doc in entityDocs {
                if let timestamp = doc["lastModified"] as? Timestamp {
                    if latestTimestamp == nil || timestamp.seconds > latestTimestamp!.seconds
                        || (timestamp.seconds == latestTimestamp!.seconds
                            && timestamp.nanoseconds > latestTimestamp!.nanoseconds)
                    {
                        latestTimestamp = timestamp
                    }
                }
            }
        }

        // Update last sync time if we found a newer timestamp
        if let latestTimestamp = latestTimestamp {
            let lastSyncKey = "lastSync_\(userId)"

            // Store the raw timestamp components
            UserDefaults.standard.set(latestTimestamp.seconds, forKey: "\(lastSyncKey)_seconds")
            UserDefaults.standard.set(
                latestTimestamp.nanoseconds, forKey: "\(lastSyncKey)_nanoseconds")

            // Also store as Date for backward compatibility
            UserDefaults.standard.set(latestTimestamp.dateValue(), forKey: lastSyncKey)

            logger.debug(
                "Updated last sync time to: \(latestTimestamp.dateValue().description), seconds: \(latestTimestamp.seconds), nanoseconds: \(latestTimestamp.nanoseconds)"
            )
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
                let uid = dto["uid"] as? String,
                let ownerId = dto["ownerId"] as? String
            else {
                skippedOperations += 1
                logger.warning(
                    "Skipping entity at index \(index): missing required fields (entityType, uid, or ownerId), dto: \(dto, privacy: .private)"
                )
                continue
            }

            var sanitizedDTO = sanitizeDTO(dto)
            sanitizedDTO["lastModified"] = FieldValue.serverTimestamp()

            // Create document reference based on entity type
            let docRef: DocumentReference

            if entityType == "User" {
                // User entities are stored directly in /users/{userId}
                docRef = db.collection("users").document(uid)

                // Remove entityType field for User documents to keep them clean
                sanitizedDTO.removeValue(forKey: "entityType")
            } else {
                // All other entities go in the entities subcollection
                docRef = db.collection("users").document(ownerId).collection("entities").document(
                    uid)
            }

            // Add to batch
            currentBatch.setData(sanitizedDTO, forDocument: docRef, merge: true)

            validOperations += 1
            operationCount += 1

            logger.debug(
                "Added entity to batch: type=\(entityType), uid=\(uid), ownerId=\(ownerId), batchCount=\(operationCount)"
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

    // MARK: - Real-time Subscription

    /// Subscribes to real-time updates for a user's entities and shared entities from friends
    /// - Parameters:
    ///   - userId: The ID of the user whose entities to subscribe to
    ///   - onUpdate: Callback function triggered when entities are updated
    /// - Returns: A cancellable object that, when cancelled, will unsubscribe from updates
    func subscribeToEntityUpdates(
        for userId: String,
        onUpdate: @escaping (_ entityData: [String: [[String: Any]]]) -> Void
    ) -> AnyCancellable {
        logger.info("Setting up real-time subscription for user: \(userId)")

        // Create a set to collect all listener cancellables
        let cancellables = Set<AnyCancellable>()

        // Create a subject to represent the stream of updates
        let subject = PassthroughSubject<[String: [[String: Any]]], Never>()

        // Subscribe to user document changes
        let userDocRef = db.collection("users").document(userId)
        let userListenerKey = "user_\(userId)"

        // Remove any existing user document listener
        listeners[userListenerKey]?.remove()

        // Set up a new listener for the user document
        let userListener = userDocRef.addSnapshotListener { [weak self] (document, error) in
            guard let self = self else { return }

            if let error = error {
                self.logger.error(
                    "Error listening for user updates: \(error.localizedDescription, privacy: .public)"
                )
                return
            }

            guard let document = document, document.exists else { return }

            var userData = document.data() ?? [:]

            // Only process if this is a data update (not just metadata)
            if document.metadata.hasPendingWrites || document.metadata.isFromCache {
                return
            }

            // Add required fields for consistency
            userData["uid"] = document.documentID
            userData["entityType"] = "User"
            userData["ownerId"] = document.documentID

            // Create the update payload
            var entityUpdates: [String: [[String: Any]]] = ["User": [userData]]

            self.logger.debug("Emitting real-time update for user document: \(document.documentID)")

            // Use the main thread for the callback to ensure UI updates work correctly
            DispatchQueue.main.async {
                onUpdate(entityUpdates)
            }

            subject.send(entityUpdates)

            // When the user document changes, we need to check if the friends list has changed
            // If it has, we need to update our subscriptions to friend entities and documents
            if let friendIds = userData["friendIds"] as? [String] {
                self.updateFriendSubscriptions(
                    userId: userId, friendIds: friendIds, onUpdate: onUpdate)
            }
        }

        // Store the user document listener
        listeners[userListenerKey] = userListener

        // Now subscribe to entities collection changes
        let entitiesCollection = db.collection("users").document(userId).collection("entities")
        let entitiesListenerKey = "entities_\(userId)"

        // Remove any existing entities listener
        listeners[entitiesListenerKey]?.remove()

        // Maintain a reference to the last snapshot processed to avoid redundant processing
        var lastProcessedSnapshotTime: Timestamp?

        // Set up a new real-time listener for the entities collection
        let entitiesListener =
            entitiesCollection
            .addSnapshotListener { [weak self] (snapshot, error) in
                guard let self = self else { return }

                if let error = error {
                    self.logger.error(
                        "Error listening for entity updates: \(error.localizedDescription, privacy: .public)"
                    )
                    return
                }

                guard let snapshot = snapshot else { return }

                // Skip updates that are just metadata changes or local writes
                if snapshot.metadata.hasPendingWrites || snapshot.metadata.isFromCache {
                    return
                }

                // Check if this is a redundant update
                let snapshotTime = Timestamp(date: Date())
                if let lastTime = lastProcessedSnapshotTime,
                    snapshotTime.seconds == lastTime.seconds
                        && snapshotTime.nanoseconds == lastTime.nanoseconds
                {
                    return
                }

                lastProcessedSnapshotTime = snapshotTime

                // Group changed documents by entity type
                var entityUpdates: [String: [[String: Any]]] = [:]

                for document in snapshot.documentChanges {
                    // Skip deleted documents - they are handled elsewhere
                    if document.type == .removed {
                        continue
                    }

                    var data = document.document.data()
                    data["uid"] = document.document.documentID

                    // Group by entity type
                    guard let entityType = data["entityType"] as? String else {
                        self.logger.warning(
                            "Entity missing entityType field: \(document.document.documentID)")
                        continue
                    }

                    // Initialize array for this entity type if it doesn't exist
                    if entityUpdates[entityType] == nil {
                        entityUpdates[entityType] = []
                    }

                    // Add to the appropriate array
                    entityUpdates[entityType]?.append(data)
                }

                // Only emit update if there are changes
                if !entityUpdates.isEmpty {
                    self.logger.debug(
                        "Emitting real-time update with \(entityUpdates.values.map { $0.count }.reduce(0, +)) entities"
                    )

                    // Use the main thread for the callback to ensure UI updates work correctly
                    DispatchQueue.main.async {
                        onUpdate(entityUpdates)
                    }

                    subject.send(entityUpdates)
                }
            }

        // Store the entities listener
        listeners[entitiesListenerKey] = entitiesListener

        // Fetch current friends and set up listeners for their shared entities and documents
        userDocRef.getDocument { [weak self] (document, error) in
            guard let self = self, let document = document, document.exists else { return }

            if let friendIds = document.data()?["friendIds"] as? [String] {
                // Set up listeners for friend entities
                self.setupFriendEntityListeners(
                    userId: userId, friendIds: friendIds, onUpdate: onUpdate)
                
                // Set up listeners for friend user documents
                self.setupFriendUserDocumentListeners(
                    userId: userId, friendIds: friendIds, onUpdate: onUpdate)
            }
        }

        // Return a cancellable that removes all listeners when cancelled
        return AnyCancellable { [weak self] in
            guard let self = self else { return }

            self.logger.info("Cancelling real-time subscriptions for user: \(userId)")

            // Remove user and entities listeners
            self.listeners[userListenerKey]?.remove()
            self.listeners[entitiesListenerKey]?.remove()
            self.listeners.removeValue(forKey: userListenerKey)
            self.listeners.removeValue(forKey: entitiesListenerKey)

            // Remove all friend listeners
            for (key, listener) in self.listeners {
                if key.starts(with: "friend_entities_\(userId)_") || key.starts(with: "friend_document_\(userId)_") {
                    listener.remove()
                    self.listeners.removeValue(forKey: key)
                }
            }
        }
    }

    /// Sets up listeners for friend user documents
    private func setupFriendUserDocumentListeners(
        userId: String,
        friendIds: [String],
        onUpdate: @escaping (_ entityData: [String: [[String: Any]]]) -> Void
    ) {
        for friendId in friendIds {
            setupFriendUserDocumentListener(userId: userId, friendId: friendId, onUpdate: onUpdate)
        }
    }
    
    /// Sets up a listener for a specific friend's user document
    private func setupFriendUserDocumentListener(
        userId: String,
        friendId: String,
        onUpdate: @escaping (_ entityData: [String: [[String: Any]]]) -> Void
    ) {
        let listenerKey = "friend_document_\(userId)_\(friendId)"
        
        // Remove any existing listener for this friend's document
        listeners[listenerKey]?.remove()
        
        // Get reference to friend's user document
        let friendDocRef = db.collection("users").document(friendId)
        
        // Set up a new real-time listener for the friend's user document
        let listener = friendDocRef.addSnapshotListener { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error(
                    "Error listening for friend user document \(friendId): \(error.localizedDescription, privacy: .public)"
                )
                return
            }
            
            guard let document = document, document.exists else { return }
            
            // Skip updates that are just metadata changes or local writes
            if document.metadata.hasPendingWrites || document.metadata.isFromCache {
                return
            }
            
            var userData = document.data() ?? [:]
            
            // Add required fields for consistency
            userData["uid"] = document.documentID
            userData["entityType"] = "User"
            userData["ownerId"] = document.documentID
            
            // Create the update payload
            let entityUpdates: [String: [[String: Any]]] = ["User": [userData]]
            
            self.logger.debug("Emitting real-time update for friend user document: \(document.documentID)")
            
            // Use the main thread for the callback to ensure UI updates work correctly
            DispatchQueue.main.async {
                onUpdate(entityUpdates)
            }
        }
        
        // Store the friend document listener
        listeners[listenerKey] = listener
    }

    /// Sets up listeners for shared entities from a user's friends
    private func setupFriendEntityListeners(
        userId: String,
        friendIds: [String],
        onUpdate: @escaping (_ entityData: [String: [[String: Any]]]) -> Void
    ) {
        for friendId in friendIds {
            setupFriendEntityListener(userId: userId, friendId: friendId, onUpdate: onUpdate)
        }
    }

    /// Sets up a listener for shared entities from a specific friend
    private func setupFriendEntityListener(
        userId: String,
        friendId: String,
        onUpdate: @escaping (_ entityData: [String: [[String: Any]]]) -> Void
    ) {
        let listenerKey = "friend_entities_\(userId)_\(friendId)"

        // Remove any existing listener for this friend
        listeners[listenerKey]?.remove()

        // Get reference to friend's entities collection
        let friendEntitiesCollection = db.collection("users").document(friendId).collection(
            "entities")

        // Maintain a reference to the last snapshot processed to avoid redundant processing
        var lastProcessedSnapshotTime: Timestamp?

        // Set up a new real-time listener for the friend's shared entities
        let listener =
            friendEntitiesCollection
            .whereField("isShared", isEqualTo: true)
            .addSnapshotListener { [weak self] (snapshot, error) in
                guard let self = self else { return }

                if let error = error {
                    self.logger.error(
                        "Error listening for friend \(friendId) shared entities: \(error.localizedDescription, privacy: .public)"
                    )
                    return
                }

                guard let snapshot = snapshot else { return }

                // Skip updates that are just metadata changes or local writes
                if snapshot.metadata.hasPendingWrites || snapshot.metadata.isFromCache {
                    return
                }

                // Check if this is a redundant update
                let snapshotTime = Timestamp(date: Date())
                if let lastTime = lastProcessedSnapshotTime,
                    snapshotTime.seconds == lastTime.seconds
                        && snapshotTime.nanoseconds == lastTime.nanoseconds
                {
                    return
                }

                lastProcessedSnapshotTime = snapshotTime

                // Group changed documents by entity type
                var entityUpdates: [String: [[String: Any]]] = [:]

                for document in snapshot.documentChanges {
                    // Skip deleted documents - they are handled elsewhere
                    if document.type == .removed {
                        continue
                    }

                    var data = document.document.data()
                    data["uid"] = document.document.documentID

                    // Only include shared entities
                    guard let isShared = data["isShared"] as? Bool, isShared else {
                        continue
                    }

                    // Group by entity type
                    guard let entityType = data["entityType"] as? String else {
                        self.logger.warning(
                            "Entity missing entityType field: \(document.document.documentID)")
                        continue
                    }

                    // Initialize array for this entity type if it doesn't exist
                    if entityUpdates[entityType] == nil {
                        entityUpdates[entityType] = []
                    }

                    // Add to the appropriate array
                    entityUpdates[entityType]?.append(data)
                }

                // Only emit update if there are changes
                if !entityUpdates.isEmpty {
                    self.logger.debug(
                        "Emitting real-time update with \(entityUpdates.values.map { $0.count }.reduce(0, +)) shared entities from friend \(friendId)"
                    )

                    // Use the main thread for the callback to ensure UI updates work correctly
                    DispatchQueue.main.async {
                        onUpdate(entityUpdates)
                    }
                }
            }

        // Store the friend entities listener
        listeners[listenerKey] = listener
    }

    /// Updates subscriptions when the friends list changes
    private func updateFriendSubscriptions(
        userId: String,
        friendIds: [String],
        onUpdate: @escaping (_ entityData: [String: [[String: Any]]]) -> Void
    ) {
        // Get current friend entity and document listeners
        var currentFriendEntityIds = Set<String>()
        var currentFriendDocumentIds = Set<String>()
        
        // Extract friend IDs from entity listeners
        for key in listeners.keys {
            if key.starts(with: "friend_entities_\(userId)_") {
                let friendId = String(key.dropFirst("friend_entities_\(userId)_".count))
                currentFriendEntityIds.insert(friendId)
            }
        }
        
        // Extract friend IDs from document listeners
        for key in listeners.keys {
            if key.starts(with: "friend_document_\(userId)_") {
                let friendId = String(key.dropFirst("friend_document_\(userId)_".count))
                currentFriendDocumentIds.insert(friendId)
            }
        }

        let newFriendIds = Set(friendIds)

        // Remove entity listeners for friends that are no longer in the list
        for friendId in currentFriendEntityIds {
            if !newFriendIds.contains(friendId) {
                let key = "friend_entities_\(userId)_\(friendId)"
                listeners[key]?.remove()
                listeners.removeValue(forKey: key)
                logger.debug("Removed entity listener for former friend: \(friendId)")
            }
        }
        
        // Remove document listeners for friends that are no longer in the list
        for friendId in currentFriendDocumentIds {
            if !newFriendIds.contains(friendId) {
                let key = "friend_document_\(userId)_\(friendId)"
                listeners[key]?.remove()
                listeners.removeValue(forKey: key)
                logger.debug("Removed document listener for former friend: \(friendId)")
            }
        }

        // Add listeners for new friends
        for friendId in newFriendIds {
            // Add entity listener if needed
            if !currentFriendEntityIds.contains(friendId) {
                setupFriendEntityListener(userId: userId, friendId: friendId, onUpdate: onUpdate)
                logger.debug("Added entity listener for new friend: \(friendId)")
            }
            
            // Add document listener if needed
            if !currentFriendDocumentIds.contains(friendId) {
                setupFriendUserDocumentListener(userId: userId, friendId: friendId, onUpdate: onUpdate)
                logger.debug("Added document listener for new friend: \(friendId)")
            }
        }
    }
}
