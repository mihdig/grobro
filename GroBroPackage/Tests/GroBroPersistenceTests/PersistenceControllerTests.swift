import XCTest
import CoreData
@testable import GroBroPersistence

@MainActor
final class PersistenceControllerTests: XCTestCase {

    /// Test that PersistenceController can be initialized without errors
    func testPersistenceControllerInitialization() throws {
        let controller = PersistenceController(inMemory: true)

        XCTAssertNotNil(controller.container, "Persistent container should be initialized")
        XCTAssertNotNil(controller.viewContext, "View context should be accessible")
    }

    /// Test that the container loads successfully
    func testPersistentStoreLoads() throws {
        let controller = PersistenceController(inMemory: true)

        XCTAssertEqual(controller.container.persistentStoreDescriptions.count, 1,
                       "Should have exactly one persistent store description")

        // Verify store loaded without errors by checking coordinator
        XCTAssertNotNil(controller.container.persistentStoreCoordinator,
                       "Persistent store coordinator should be initialized")
        XCTAssertGreaterThan(controller.container.persistentStoreCoordinator.persistentStores.count, 0,
                            "At least one persistent store should be loaded")
    }

    /// Test that view context is properly configured
    func testViewContextConfiguration() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.viewContext

        XCTAssertTrue(context.automaticallyMergesChangesFromParent,
                     "View context should automatically merge changes from parent")

        XCTAssertEqual(context.mergePolicy as? NSMergePolicy, NSMergePolicy.mergeByPropertyObjectTrump,
                     "Merge policy should be mergeByPropertyObjectTrump")
    }

    /// Test saving an empty context (no changes)
    func testSaveWithNoChanges() throws {
        let controller = PersistenceController(inMemory: true)

        // Saving with no changes should not throw
        XCTAssertNoThrow(try controller.save(), "Saving with no changes should not throw an error")
    }

    /// Test that in-memory store is truly in-memory
    func testInMemoryStoreConfiguration() throws {
        let controller = PersistenceController(inMemory: true)

        guard let storeURL = controller.container.persistentStoreDescriptions.first?.url else {
            XCTFail("Store URL should exist")
            return
        }

        XCTAssertEqual(storeURL.path, "/dev/null",
                      "In-memory store should use /dev/null URL")
    }

    /// Test preview instance is configured correctly
    func testPreviewInstance() throws {
        let previewController = PersistenceController.preview

        XCTAssertNotNil(previewController.container)
        XCTAssertNotNil(previewController.viewContext)

        // Verify it's using in-memory store
        guard let storeURL = previewController.container.persistentStoreDescriptions.first?.url else {
            XCTFail("Preview store URL should exist")
            return
        }

        XCTAssertEqual(storeURL.path, "/dev/null",
                      "Preview instance should use in-memory store")
    }

    /// Test that shared instance is a singleton
    func testSharedInstanceSingleton() throws {
        let instance1 = PersistenceController.shared
        let instance2 = PersistenceController.shared

        XCTAssertTrue(instance1 === instance2,
                     "Shared instance should be a singleton")
    }
}
