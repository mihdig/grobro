import Foundation
import GroBroDomain
#if canImport(WidgetKit)
import WidgetKit
#endif
#if canImport(ActivityKit) && os(iOS)
import ActivityKit
#endif

/// Publishes lightweight garden snapshots to the shared app group so WidgetKit
/// timelines and AppIntents can stay in sync without touching Core Data.
@available(iOS 17.0, *)
@MainActor
@Observable
public final class WidgetSyncService {
    private let snapshotStore: WidgetSnapshotStore
    private let deviceStore: DeviceStore
    private let environmentalDataStore: EnvironmentalDataStore
    #if canImport(ActivityKit) && os(iOS)
    private let liveActivityManager = WateringLiveActivityManager()
    #endif
    private var lastPublishedHash: Int?

    public init(
        snapshotStore: WidgetSnapshotStore = .shared,
        deviceStore: DeviceStore,
        environmentalDataStore: EnvironmentalDataStore
    ) {
        self.snapshotStore = snapshotStore
        self.deviceStore = deviceStore
        self.environmentalDataStore = environmentalDataStore
    }

    /// Serializes the current garden state for WidgetKit.
    public func publish(
        plants: [Plant],
        wateringStatuses: [UUID: WateringStatus],
        isProUser: Bool
    ) {
        let snapshots = plants.map { plant in
            let wateringStatus = wateringStatuses[plant.id]
            let device = deviceStore.device(for: plant.id)
            let environmentSummary = environmentSummaryIfAvailable(
                plantID: plant.id,
                plantStage: plant.stage,
                device: device,
                isProUser: isProUser
            )
            return makeSnapshot(
                for: plant,
                wateringStatus: wateringStatus,
                environment: environmentSummary,
                device: device,
                isProUser: isProUser
            )
        }

        let hasDevices = !deviceStore.connectedDevices.isEmpty
        let snapshot = WidgetGardenSnapshot(
            generatedAt: Date(),
            plants: snapshots,
            emptyStateMessage: plants.isEmpty ? "Add your first plant to power Smart Greenhouse widgets" : "All good to grow",
            hasConnectedDevices: hasDevices
        )

        // Avoid re-writing identical payloads
        let payloadHash = snapshot.hashValue
        guard payloadHash != lastPublishedHash else { return }
        lastPublishedHash = payloadHash

        snapshotStore.save(snapshot: snapshot)
        #if canImport(ActivityKit) && os(iOS)
        liveActivityManager.synchronize(with: snapshots)
        #endif

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    private func makeSnapshot(
        for plant: Plant,
        wateringStatus: WateringStatus?,
        environment: WidgetPlantSnapshot.EnvironmentalSummary?,
        device: ACInfinityDevice?,
        isProUser: Bool
    ) -> WidgetPlantSnapshot {
        let countdown = countdownText(for: wateringStatus?.nextWateringDate)
        let statusMessage = wateringStatus?.statusMessage ?? "No watering events yet"
        var badges: [WidgetPlantSnapshot.StatusBadge] = []

        if let status = wateringStatus {
            if status.isOverdue {
                badges.append(.overdue)
            } else if status.daysUntilWatering <= 1 {
                badges.append(.dueSoon)
            }
        } else {
            badges.append(.empty)
        }

        if let device, !device.isConnected {
            badges.append(.offline)
        }

        if isProUser {
            badges.append(.pro)
        }

        return WidgetPlantSnapshot(
            id: plant.id,
            name: plant.name,
            stage: plant.stage,
            countdownText: countdown,
            statusMessage: statusMessage,
            nextWateringDate: wateringStatus?.nextWateringDate,
            isOverdue: wateringStatus?.isOverdue ?? false,
            badges: badges,
            environment: environment,
            isProOnlyFeature: isProUser
        )
    }

    private func countdownText(for nextWateringDate: Date?) -> String {
        guard let date = nextWateringDate else {
            return "Schedule TBD"
        }

        let interval = date.timeIntervalSinceNow
        if interval <= 0 {
            let hours = abs(Int(interval / 3600))
            return hours <= 1 ? "Overdue" : "Overdue \(hours)h"
        }

        if interval < 3600 {
            let minutes = max(1, Int(interval / 60))
            return "Water in \(minutes)m"
        } else if interval < 86_400 {
            let hours = Int(interval / 3600)
            return "Water in \(hours)h"
        } else {
            let days = Int(interval / 86_400)
            return "Water in \(days)d"
        }
    }

    private func environmentSummaryIfAvailable(
        plantID: UUID,
        plantStage: PlantStage,
        device: ACInfinityDevice?,
        isProUser: Bool
    ) -> WidgetPlantSnapshot.EnvironmentalSummary? {
        guard isProUser,
              let device,
              device.isConnected,
              let data = environmentalDataStore.data(for: plantID) else {
            return nil
        }

        let status: WidgetPlantSnapshot.EnvironmentalSummary.Status
        switch data.status {
        case .optimal:
            status = .optimal
        case .caution:
            status = .caution
        case .critical:
            status = .critical
        case .offline:
            status = .offline
        }

        return WidgetPlantSnapshot.EnvironmentalSummary(
            temperature: data.temperature,
            humidity: data.humidity,
            vpd: data.vpd,
            status: status,
            lastReadingDate: data.timestamp
        )
    }
}
