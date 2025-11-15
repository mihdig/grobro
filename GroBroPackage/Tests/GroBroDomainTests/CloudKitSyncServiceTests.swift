import Testing
import Foundation
import CoreData
@testable import GroBroDomain

@Suite("CloudKitSyncService Tests")
struct CloudKitSyncServiceTests {

    private func makeInMemoryContainer() -> NSPersistentContainer {
        let model = NSManagedObjectModel()
        let container = NSPersistentContainer(name: "Test", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }
        return container
    }

    @Test("Enable and disable sync update status")
    func testEnableDisable() async throws {
        let container = makeInMemoryContainer()
        let suiteName = "CloudKitSyncServiceTests-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)

        let service = await MainActor.run {
            CloudKitSyncService(container: container, userDefaults: userDefaults)
        }

        await MainActor.run {
            #expect(service.isSyncEnabled == false)
            #expect(service.status.state == .disabled)

            service.enableSync()
            #expect(service.isSyncEnabled == true)
            #expect(service.status.state == .idle)

            service.disableSync()
            #expect(service.isSyncEnabled == false)
            #expect(service.status.state == .disabled)
        }
    }
}
