import Foundation
import SwiftUI
import GroBroDomain

/// Manages environmental data for all plants
/// Handles real-time updates, historical data, and alert monitoring
@Observable
@MainActor
public final class EnvironmentalDataStore {

    // MARK: - Published State

    private(set) var dataByPlant: [UUID: RealtimeEnvironmentalData] = [:]
    private(set) var historicalDataByPlant: [UUID: [EnvironmentalDataPoint]] = [:]
    private(set) var activeAlerts: [UUID: [EnvironmentalAlert]] = [:]
    private(set) var thresholdsByPlant: [UUID: EnvironmentalThresholds] = [:]

    // MARK: - Dependencies

    private let service: ACInfinityService
    private let deviceStore: DeviceStore

    // MARK: - Real-time Update Tasks

    private var updateTasks: [UUID: Task<Void, Never>] = [:]

    // MARK: - Initialization

    public init(service: ACInfinityService = ACInfinityService(), deviceStore: DeviceStore) {
        self.service = service
        self.deviceStore = deviceStore
    }

    // MARK: - Data Access

    /// Get current environmental data for a plant
    func data(for plantId: UUID) -> RealtimeEnvironmentalData? {
        dataByPlant[plantId]
    }

    /// Get historical data for a plant
    func historicalData(for plantId: UUID) -> [EnvironmentalDataPoint] {
        historicalDataByPlant[plantId] ?? []
    }

    /// Get active alerts for a plant
    func alerts(for plantId: UUID) -> [EnvironmentalAlert] {
        activeAlerts[plantId] ?? []
    }

    /// Get alert thresholds for a plant
    func thresholds(for plantId: UUID) -> EnvironmentalThresholds {
        thresholdsByPlant[plantId] ?? EnvironmentalThresholds()
    }

    // MARK: - Real-time Monitoring

    /// Start monitoring environmental data for a plant
    func startMonitoring(plantId: UUID) {
        // Cancel existing task if any
        stopMonitoring(plantId: plantId)

        // Get device for this plant
        guard let device = deviceStore.device(for: plantId), device.isConnected else {
            print("⚠️ No connected device for plant \(plantId)")
            return
        }

        // Create monitoring task
        let task = Task { [weak self] in
            guard let self else { return }
            await self.monitorLoop(plantId: plantId, deviceId: device.id)
        }

        updateTasks[plantId] = task
    }

    /// Stop monitoring environmental data for a plant
    func stopMonitoring(plantId: UUID) {
        updateTasks[plantId]?.cancel()
        updateTasks[plantId] = nil
    }

    private func monitorLoop(plantId: UUID, deviceId: String) async {
        while !Task.isCancelled {
            do {
                // Fetch latest environmental data
                let envData = try await service.fetchEnvironmentalData(deviceId: deviceId)

                // Update state
                await MainActor.run {
                    withAnimation(.spring(response: 0.3)) {
                        dataByPlant[plantId] = envData
                    }

                    // Check for alerts
                    checkAlerts(for: plantId, data: envData)

                    // Add to historical data
                    addHistoricalDataPoint(plantId: plantId, data: envData)
                }

                // Wait before next update (5 seconds)
                try await Task.sleep(for: .seconds(5))

            } catch {
                print("❌ Error fetching environmental data: \(error)")

                // Mark as offline
                await MainActor.run {
                    if let currentData = dataByPlant[plantId] {
                        currentData.isConnected = false
                    }
                }

                // Wait longer before retry (30 seconds)
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    // MARK: - Historical Data

    /// Load historical data for a date range
    func loadHistoricalData(
        plantId: UUID,
        startDate: Date,
        endDate: Date
    ) async throws {
        guard let device = deviceStore.device(for: plantId) else {
            throw EnvironmentalDataError.noDeviceAssigned
        }

        let historical = try await service.fetchHistoricalData(
            deviceId: device.id,
            startDate: startDate,
            endDate: endDate
        )

        historicalDataByPlant[plantId] = historical
    }

    private func addHistoricalDataPoint(plantId: UUID, data: RealtimeEnvironmentalData) {
        let point = EnvironmentalDataPoint(from: data)

        if historicalDataByPlant[plantId] == nil {
            historicalDataByPlant[plantId] = []
        }

        historicalDataByPlant[plantId]?.append(point)

        // Keep only last 720 data points (24 hours at 2-minute intervals)
        if let count = historicalDataByPlant[plantId]?.count, count > 720 {
            historicalDataByPlant[plantId]?.removeFirst(count - 720)
        }
    }

    /// Clear historical data for a plant
    func clearHistoricalData(plantId: UUID) {
        historicalDataByPlant[plantId] = []
    }

    // MARK: - Alert Management

    /// Update alert thresholds for a plant
    func updateThresholds(_ thresholds: EnvironmentalThresholds, for plantId: UUID) {
        thresholdsByPlant[plantId] = thresholds

        // Re-check alerts with new thresholds
        if let currentData = dataByPlant[plantId] {
            checkAlerts(for: plantId, data: currentData)
        }
    }

    private func checkAlerts(for plantId: UUID, data: RealtimeEnvironmentalData) {
        let thresholds = self.thresholds(for: plantId)
        let alerts = thresholds.checkAlerts(for: data)

        // Only update if alerts changed
        if activeAlerts[plantId] != alerts {
            activeAlerts[plantId] = alerts

            // Send local notifications for new alerts
            sendAlertNotifications(plantId: plantId, alerts: alerts)
        }
    }

    /// Acknowledge an alert (removes it from active alerts)
    func acknowledgeAlert(_ alert: EnvironmentalAlert, for plantId: UUID) {
        activeAlerts[plantId]?.removeAll { $0.id == alert.id }
    }

    /// Clear all alerts for a plant
    func clearAlerts(for plantId: UUID) {
        activeAlerts[plantId] = []
    }

    // MARK: - Notifications

    private func sendAlertNotifications(plantId: UUID, alerts: [EnvironmentalAlert]) {
        // TODO: Implement local notifications
        // - Create UNNotificationRequest
        // - Set category for plant environmental alerts
        // - Include plantId in userInfo for navigation
        // - Group by plant to avoid spam

        for alert in alerts {
            print("🔔 Alert for plant \(plantId): \(alert.title) - \(alert.message)")
        }
    }

    // MARK: - Manual Data Entry

    /// Manually update environmental data (for testing or when offline)
    func updateData(_ data: RealtimeEnvironmentalData, for plantId: UUID) {
        withAnimation(.spring(response: 0.3)) {
            dataByPlant[plantId] = data
        }

        checkAlerts(for: plantId, data: data)
        addHistoricalDataPoint(plantId: plantId, data: data)
    }

    // MARK: - Cleanup

    /// Remove all data for a plant (when plant is deleted)
    func removeData(for plantId: UUID) {
        stopMonitoring(plantId: plantId)
        dataByPlant[plantId] = nil
        historicalDataByPlant[plantId] = nil
        activeAlerts[plantId] = nil
        thresholdsByPlant[plantId] = nil
    }

    // MARK: - Testing Helpers

    #if DEBUG
    /// Generate mock data for testing
    func generateMockData(for plantId: UUID) {
        let mockData = RealtimeEnvironmentalData(
            temperature: Double.random(in: 72...82),
            humidity: Double.random(in: 50...70),
            vpd: 0,
            timestamp: Date(),
            deviceId: "MOCK-123456",
            isConnected: true
        )
        mockData.vpd = RealtimeEnvironmentalData.calculateVPD(
            temperature: mockData.temperature,
            humidity: mockData.humidity
        )

        updateData(mockData, for: plantId)

        // Generate historical data
        let now = Date()
        let historical = (0..<24).map { hour in
            let timestamp = now.addingTimeInterval(TimeInterval(-hour * 3600))
            let temp = 75 + Double.random(in: -5...5)
            let humidity = 60 + Double.random(in: -10...10)
            let vpd = RealtimeEnvironmentalData.calculateVPD(temperature: temp, humidity: humidity)

            return EnvironmentalDataPoint(
                timestamp: timestamp,
                temperature: temp,
                humidity: humidity,
                vpd: vpd
            )
        }.reversed()

        historicalDataByPlant[plantId] = Array(historical)
    }

    /// Start mock real-time updates for testing
    func startMockMonitoring(plantId: UUID) {
        stopMonitoring(plantId: plantId)

        let task = Task { [weak self] in
            while !Task.isCancelled {
                await MainActor.run {
                    self?.generateMockData(for: plantId)
                }

                try? await Task.sleep(for: .seconds(3))
            }
        }

        updateTasks[plantId] = task
    }
    #endif
}

// MARK: - Errors

enum EnvironmentalDataError: LocalizedError {
    case noDeviceAssigned
    case deviceOffline
    case dataUnavailable

    var errorDescription: String? {
        switch self {
        case .noDeviceAssigned:
            return "No AC Infinity controller assigned to this plant"
        case .deviceOffline:
            return "Device is currently offline"
        case .dataUnavailable:
            return "Environmental data is not available"
        }
    }
}

// MARK: - Preview Helper

extension EnvironmentalDataStore {
    static var preview: EnvironmentalDataStore {
        let deviceStore = DeviceStore.preview
        let store = EnvironmentalDataStore(deviceStore: deviceStore)

        #if DEBUG
        // Generate mock data for preview
        let mockPlantId = UUID()
        store.generateMockData(for: mockPlantId)
        #endif

        return store
    }
}

// MARK: - Alert Equality

extension EnvironmentalAlert: Equatable {
    public static func == (lhs: EnvironmentalAlert, rhs: EnvironmentalAlert) -> Bool {
        lhs.id == rhs.id
    }
}
