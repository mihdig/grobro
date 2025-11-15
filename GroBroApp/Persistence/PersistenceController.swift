import CoreData

/// Core Data stack for GroBro.
///
/// This follows the standard NSPersistentContainer pattern and expects
/// a `GroBroModel` Core Data model to be configured in Xcode.
final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    /// Main initializer.
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "GroBroModel")

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error {
                // In development builds we log errors; production apps should
                // handle this more gracefully but never crash at launch.
                NSLog("Unresolved Core Data error: \(error.localizedDescription)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    /// In-memory controller for tests and previews.
    static var preview: PersistenceController = {
        PersistenceController(inMemory: true)
    }()
}

