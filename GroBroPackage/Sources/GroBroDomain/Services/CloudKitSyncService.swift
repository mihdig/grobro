import Foundation
import CoreData
import CloudKit

/// High-level sync state for iCloud/CloudKit
@available(iOS 17.0, macOS 14.0, *)
public enum CloudSyncState: String, Sendable {
    case disabled
    case idle
    case syncing
    case error
}

/// Simple value type representing sync status for UI
@available(iOS 17.0, macOS 14.0, *)
public struct CloudSyncStatus: Sendable {
    public let state: CloudSyncState
    public let lastSyncDate: Date?
    public let lastError: String?

    public init(state: CloudSyncState, lastSyncDate: Date?, lastError: String?) {
        self.state = state
        self.lastSyncDate = lastSyncDate
        self.lastError = lastError
    }
}

/// Recorded sync conflict for debugging and QA
@available(iOS 17.0, macOS 14.0, *)
public struct CloudSyncConflict: Identifiable, Codable, Sendable {
    public let id: UUID
    public let date: Date
    public let entityName: String
    public let entityId: UUID?
    public let description: String
    public let isCritical: Bool

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        entityName: String,
        entityId: UUID?,
        description: String,
        isCritical: Bool
    ) {
        self.id = id
        self.date = date
        self.entityName = entityName
        self.entityId = entityId
        self.description = description
        self.isCritical = isCritical
    }
}

/// Service responsible for coordinating Core Data <-> CloudKit sync using NSPersistentCloudKitContainer.
/// This is intentionally conservative: automatic sync is handled by Core Data; this service exposes
/// status, user opt-in, and a manual "kick" for sync to support Settings UI and future refinements.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
@Observable
public final class CloudKitSyncService {

    private enum Keys {
        static let syncEnabled = "com.grobro.sync.icloud.enabled"
        static let lastSyncDate = "com.grobro.sync.icloud.lastSyncDate"
        static let lastError = "com.grobro.sync.icloud.lastError"
        static let conflictLog = "com.grobro.sync.icloud.conflictLog"
    }

    // MARK: - Dependencies

    private let persistentContainer: NSPersistentContainer
    private let userDefaults: UserDefaults

    // MARK: - Published state

    public private(set) var isSyncEnabled: Bool
    public private(set) var status: CloudSyncStatus
    public private(set) var conflicts: [CloudSyncConflict]

    // MARK: - Initialization

    public init(
        container: NSPersistentContainer,
        userDefaults: UserDefaults = .standard
    ) {
        self.persistentContainer = container
        self.userDefaults = userDefaults

        let enabled = userDefaults.bool(forKey: Keys.syncEnabled)
        self.isSyncEnabled = enabled

        let lastDate = userDefaults.object(forKey: Keys.lastSyncDate) as? Date
        let lastError = userDefaults.string(forKey: Keys.lastError)

        let decodedConflicts: [CloudSyncConflict]
        if let data = userDefaults.data(forKey: Keys.conflictLog),
           let loaded = try? JSONDecoder().decode([CloudSyncConflict].self, from: data) {
            decodedConflicts = loaded
        } else {
            decodedConflicts = []
        }
        self.conflicts = decodedConflicts

        let initialState: CloudSyncState = enabled ? .idle : .disabled
        self.status = CloudSyncStatus(
            state: initialState,
            lastSyncDate: lastDate,
            lastError: lastError
        )
    }

    // MARK: - Public API

    /// Enable iCloud sync (user opt-in).
    public func enableSync() {
        guard !isSyncEnabled else { return }
        isSyncEnabled = true
        userDefaults.set(true, forKey: Keys.syncEnabled)

        status = CloudSyncStatus(
            state: .idle,
            lastSyncDate: status.lastSyncDate,
            lastError: nil
        )
    }

    /// Disable iCloud sync (user opt-out).
    public func disableSync() {
        guard isSyncEnabled else { return }
        isSyncEnabled = false
        userDefaults.set(false, forKey: Keys.syncEnabled)

        status = CloudSyncStatus(
            state: .disabled,
            lastSyncDate: status.lastSyncDate,
            lastError: nil
        )
    }

    /// Manual refresh requested from Settings.
    /// In a real app this could trigger a more advanced sync pipeline; for NSPersistentCloudKitContainer
    /// we simply ask the container to fetch history and push/pull changes.
    public func performManualSync() async {
        guard isSyncEnabled else { return }

        status = CloudSyncStatus(
            state: .syncing,
            lastSyncDate: status.lastSyncDate,
            lastError: nil
        )

        do {
            try await refreshStores()

            let now = Date()
            userDefaults.set(now, forKey: Keys.lastSyncDate)

            status = CloudSyncStatus(
                state: .idle,
                lastSyncDate: now,
                lastError: nil
            )
        } catch {
            let message: String
            if let ckError = error as? CKError {
                message = "CloudKit error \(ckError.errorCode): \(ckError.localizedDescription)"
            } else {
                message = error.localizedDescription
            }
            userDefaults.set(message, forKey: Keys.lastError)

            status = CloudSyncStatus(
                state: .error,
                lastSyncDate: status.lastSyncDate,
                lastError: message
            )
        }
    }

    /// Records a sync conflict for later inspection in Settings.
    public func logConflict(
        entityName: String,
        entityId: UUID?,
        description: String,
        isCritical: Bool
    ) {
        let record = CloudSyncConflict(
            entityName: entityName,
            entityId: entityId,
            description: description,
            isCritical: isCritical
        )
        conflicts.insert(record, at: 0)
        if conflicts.count > 100 {
            conflicts.removeLast(conflicts.count - 100)
        }
        persistConflicts()
    }

    /// Clears the stored conflict log.
    public func clearConflicts() {
        conflicts.removeAll()
        persistConflicts()
    }

    /// Runs a lightweight data integrity check to ensure all events reference valid plants.
    /// Any issues are recorded as conflicts with `entityName == "IntegrityCheck"`.
    public func runIntegrityCheck() {
        let context = persistentContainer.viewContext
        let eventRequest = NSFetchRequest<NSManagedObject>(entityName: "EventEntity")
        let plantRequest = NSFetchRequest<NSManagedObject>(entityName: "PlantEntity")

        do {
            let plants = try context.fetch(plantRequest)
            let plantIds = Set(plants.compactMap { $0.value(forKey: "id") as? UUID })

            let events = try context.fetch(eventRequest)
            let orphanedEvents = events.filter {
                guard let plantId = $0.value(forKey: "plantId") as? UUID else { return true }
                return !plantIds.contains(plantId)
            }

            if orphanedEvents.isEmpty {
                logConflict(
                    entityName: "IntegrityCheck",
                    entityId: nil,
                    description: "Integrity check passed: no orphaned events.",
                    isCritical: false
                )
            } else {
                for event in orphanedEvents {
                    let eventId = event.value(forKey: "id") as? UUID
                    logConflict(
                        entityName: "IntegrityCheck",
                        entityId: eventId,
                        description: "Orphaned event detected with id \(eventId?.uuidString ?? "unknown").",
                        isCritical: true
                    )
                }
            }
        } catch {
            logConflict(
                entityName: "IntegrityCheck",
                entityId: nil,
                description: "Failed to run integrity check: \(error.localizedDescription)",
                isCritical: true
            )
        }
    }

    // MARK: - Internal helpers

    private func refreshStores() async throws {
        // For NSPersistentCloudKitContainer, the primary lever we have in-process is
        // to trigger a viewContext save and rely on CloudKit daemon to push changes,
        // plus fetchDatabaseChanges via persistent stores. To keep this package
        // environment-friendly, we simply save and wait briefly.

        let context = persistentContainer.viewContext
        if context.hasChanges {
            try context.save()
        }

        // Give CloudKit some time; on a real device you'd hook into
        // NSPersistentCloudKitContainer event handling.
        try await Task.sleep(for: .milliseconds(200))
    }

    private func persistConflicts() {
        if let data = try? JSONEncoder().encode(conflicts) {
            userDefaults.set(data, forKey: Keys.conflictLog)
        }
    }
}
