import Testing
import Foundation
@testable import GroBroDomain
import GroBroPersistence

@MainActor
@Suite("Vivosun Sync Service Tests")
struct VivosunSyncServiceTests {

    @Test("Sync creates environment events with Vivosun source")
    func syncCreatesEvents() async throws {
        let persistence = PersistenceController(inMemory: true)
        let eventStore = EventStore(persistenceController: persistence)
        let mockAPI = MockVivosunAPI()
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let keychain = InMemoryKeychain()

        let service = VivosunSyncService(
            apiClient: mockAPI,
            eventStore: eventStore,
            keychain: keychain,
            userDefaults: userDefaults
        )

        let plantStore = PlantStore(persistenceController: persistence)
        let plant = try plantStore.createPlant(
            Plant(
                name: "Sync Test",
                stage: .vegetative,
                potSizeLiters: 10,
                substrateType: .soil
            )
        )

        await service.linkAccount(email: "grower@example.com", password: "secret")
        service.updateMapping(for: mockAPI.devices.first!.id, plantIds: [plant.id])

        await service.syncNow()

        let events = try eventStore.fetchEvents(for: plant.id)
        #expect(events.count == 1)
        #expect(events.first?.source == .vivosun)
        #expect(events.first?.environmentalData?.temperatureFahrenheit == 75)
    }

    @Test("Disabled plants do not receive synced events")
    func disabledPlantsSkipSync() async throws {
        let persistence = PersistenceController(inMemory: true)
        let eventStore = EventStore(persistenceController: persistence)
        let mockAPI = MockVivosunAPI()
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let keychain = InMemoryKeychain()

        let service = VivosunSyncService(
            apiClient: mockAPI,
            eventStore: eventStore,
            keychain: keychain,
            userDefaults: userDefaults
        )

        let plantStore = PlantStore(persistenceController: persistence)
        let plant = try plantStore.createPlant(
            Plant(
                name: "Disabled",
                stage: .flowering,
                potSizeLiters: 12,
                substrateType: .coco
            )
        )

        await service.linkAccount(email: "grower@example.com", password: "secret")
        service.updateMapping(for: mockAPI.devices.first!.id, plantIds: [plant.id])
        service.setSyncEnabled(false, for: plant.id)

        await service.syncNow()

        let events = try eventStore.fetchEvents(for: plant.id)
        #expect(events.isEmpty)
    }

    // MARK: - Test Doubles

    final class MockVivosunAPI: VivosunAPIProviding {
        let devices: [VivosunDevice]
        private let reading: VivosunSensorReading

        init() {
            self.devices = [
                VivosunDevice(id: "device-1", name: "Grow Hub", deviceType: .controller, location: "Tent", isOnline: true)
            ]
            self.reading = VivosunSensorReading(
                temperatureFahrenheit: 75,
                humidityPercent: 55,
                vpdKilopascal: 1.1
            )
        }

        func authenticate(email: String, password: String) async throws -> String {
            "mock-token"
        }

        func fetchDevices(token: String) async throws -> [VivosunDevice] {
            devices
        }

        func fetchSensorReading(token: String, deviceId: String) async throws -> VivosunSensorReading {
            reading
        }
    }

    final class InMemoryKeychain: KeychainManaging {
        private var storage: [String: String] = [:]

        func store(password: String, account: String) throws {
            storage[account] = password
        }

        func retrievePassword(account: String) throws -> String? {
            storage[account]
        }

        func deletePassword(account: String) throws {
            storage.removeValue(forKey: account)
        }
    }
}
