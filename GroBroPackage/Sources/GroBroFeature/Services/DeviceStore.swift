import Foundation
import SwiftUI
import GroBroDomain

/// Manages AC Infinity devices and their assignments to plants
/// Handles persistence, real-time updates, and device lifecycle
@Observable
@MainActor
public final class DeviceStore {

    // MARK: - Published State

    private(set) var devices: [ACInfinityDevice] = []
    private(set) var isScanning: Bool = false
    private(set) var discoveredDevices: [DiscoveredDevice] = []

    // MARK: - Dependencies

    private let service: ACInfinityService
    private let userDefaults: UserDefaults

    // MARK: - Constants

    private let devicesKey = "com.grobro.devices"

    // MARK: - Initialization

    public init(service: ACInfinityService = ACInfinityService(), userDefaults: UserDefaults = .standard) {
        self.service = service
        self.userDefaults = userDefaults
        loadDevices()
    }

    // MARK: - Device Management

    /// Add a newly connected device
    func add(_ device: ACInfinityDevice) {
        devices.append(device)
        saveDevices()
    }

    /// Remove a device
    func remove(_ device: ACInfinityDevice) {
        devices.removeAll { $0.id == device.id }
        saveDevices()
    }

    /// Update an existing device
    func update(_ device: ACInfinityDevice) {
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index] = device
            saveDevices()
        }
    }

    /// Get device assigned to a specific plant
    func device(for plantId: UUID) -> ACInfinityDevice? {
        devices.first { $0.assignedPlantId == plantId }
    }

    /// Get all connected devices
    var connectedDevices: [ACInfinityDevice] {
        devices.filter { $0.isConnected }
    }

    /// Get all offline devices
    var offlineDevices: [ACInfinityDevice] {
        devices.filter { !$0.isConnected }
    }

    // MARK: - Device Discovery

    /// Start scanning for nearby AC Infinity controllers
    func startScanning() async {
        isScanning = true
        discoveredDevices = []

        do {
            let discovered = try await service.scanForDevices()
            discoveredDevices = discovered.filter { newDevice in
                // Filter out devices we've already added
                !devices.contains { $0.id == newDevice.id }
            }
        } catch {
            print("❌ Scanning failed: \(error)")
        }

        isScanning = false
    }

    /// Stop scanning for devices
    func stopScanning() {
        isScanning = false
    }

    // MARK: - Device Connection

    /// Connect to a discovered device
    /// - Parameters:
    ///   - discoveredDevice: Device from scan results
    ///   - username: AC Infinity account username
    ///   - password: AC Infinity account password
    ///   - plantId: Optional plant to assign to
    /// - Returns: Connected device
    func connect(
        discoveredDevice: DiscoveredDevice,
        username: String,
        password: String,
        plantId: UUID? = nil
    ) async throws -> ACInfinityDevice {
        // Authenticate with AC Infinity
        var device = try await service.authenticate(
            username: username,
            password: password,
            deviceId: discoveredDevice.id
        )

        // Assign to plant if provided
        if let plantId = plantId {
            device.assignedPlantId = plantId
        }

        // Add to store
        add(device)

        // Start real-time monitoring
        try? await service.connectRealtime(deviceId: device.id)

        return device
    }

    /// Disconnect a device
    func disconnect(_ device: ACInfinityDevice) async {
        await service.disconnectRealtime(deviceId: device.id)

        var updatedDevice = device
        updatedDevice.isConnected = false
        update(updatedDevice)
    }

    // MARK: - Device Settings

    /// Update device fan speed
    func updateFanSpeed(_ speed: Int, for device: ACInfinityDevice) async throws {
        try await service.updateSettings(deviceId: device.id, fanSpeed: speed)

        var updatedDevice = device
        updatedDevice.fanSpeed = speed
        updatedDevice.lastSyncDate = Date()
        update(updatedDevice)
    }

    /// Update device temperature targets
    func updateTemperatureTargets(_ range: ACInfinityDevice.TemperatureRange, for device: ACInfinityDevice) async throws {
        try await service.updateSettings(deviceId: device.id, targetTemperature: range)

        var updatedDevice = device
        updatedDevice.targetTemperature = range
        updatedDevice.lastSyncDate = Date()
        update(updatedDevice)
    }

    /// Update device humidity targets
    func updateHumidityTargets(_ range: ACInfinityDevice.HumidityRange, for device: ACInfinityDevice) async throws {
        try await service.updateSettings(deviceId: device.id, targetHumidity: range)

        var updatedDevice = device
        updatedDevice.targetHumidity = range
        updatedDevice.lastSyncDate = Date()
        update(updatedDevice)
    }

    /// Refresh device settings from API
    func refreshSettings(for device: ACInfinityDevice) async throws {
        let updatedDevice = try await service.getSettings(deviceId: device.id)
        update(updatedDevice)
    }

    // MARK: - Plant Assignment

    /// Assign device to a plant
    func assignToPlant(_ device: ACInfinityDevice, plantId: UUID) {
        var updatedDevice = device
        updatedDevice.assignedPlantId = plantId
        update(updatedDevice)
    }

    /// Unassign device from plant
    func unassign(_ device: ACInfinityDevice) {
        var updatedDevice = device
        updatedDevice.assignedPlantId = nil
        update(updatedDevice)
    }

    // MARK: - Persistence

    private func loadDevices() {
        guard let data = userDefaults.data(forKey: devicesKey),
              let decoded = try? JSONDecoder().decode([ACInfinityDevice].self, from: data) else {
            return
        }

        devices = decoded
    }

    private func saveDevices() {
        guard let encoded = try? JSONEncoder().encode(devices) else {
            return
        }

        userDefaults.set(encoded, forKey: devicesKey)
    }

    // MARK: - Testing Helpers

    /// Add mock devices for testing (only in DEBUG)
    #if DEBUG
    func addMockDevices() {
        let mockDevice = ACInfinityDevice(
            id: "MOCK-123456",
            name: "Mock Controller 69 Pro",
            model: .controller69Pro,
            firmwareVersion: "2.1.4",
            isConnected: true,
            lastSyncDate: Date(),
            signalStrength: .excellent,
            fanSpeed: 6
        )

        add(mockDevice)
    }

    /// Clear all devices (only in DEBUG)
    func clearAllDevices() {
        devices = []
        saveDevices()
    }
    #endif
}

// MARK: - Preview Helper

extension DeviceStore {
    static var preview: DeviceStore {
        let store = DeviceStore()
        #if DEBUG
        store.addMockDevices()
        #endif
        return store
    }
}
