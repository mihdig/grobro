import CoreData
import Foundation

/// Manages the Core Data persistence stack for GroBro.
/// Provides a singleton instance for production use and a preview/in-memory instance for testing.
@MainActor
public final class PersistenceController {

    /// Shared singleton instance for production use
    public static let shared = PersistenceController()

    /// Preview instance with in-memory store for SwiftUI previews and testing
    public static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        // Can add sample data here for previews in future stories
        return controller
    }()

    /// The managed object context for interacting with Core Data
    public let container: NSPersistentContainer

    /// Main view context for UI operations
    public var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    /// Initialize the persistence controller
    /// - Parameter inMemory: If true, uses an in-memory store (for testing/previews)
    public init(inMemory: Bool = false) {
        // Load the Core Data model from the GroBroPersistence module
        guard let modelURL = Bundle.module.url(forResource: "GroBroModel", withExtension: "momd"),
              let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load Core Data model from GroBroPersistence module")
        }

        container = NSPersistentContainer(name: "GroBroModel", managedObjectModel: managedObjectModel)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                // In development, log the error clearly
                #if DEBUG
                print("❌ Core Data failed to load: \(error), \(error.userInfo)")
                #endif

                // In production, we could attempt recovery or provide a fallback
                // For now, we'll fatal error in development and log in production
                #if DEBUG
                fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
                #else
                // TODO: Implement graceful fallback for production builds
                print("Core Data store failed to load. App will run with limited functionality.")
                #endif
            } else {
                #if DEBUG
                print("✅ Core Data store loaded successfully: \(description)")
                #endif
            }
        }

        // Configure view context for UI updates
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    /// Saves changes in the view context if there are any
    /// - Throws: Core Data errors if save fails
    public func save() throws {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
                #if DEBUG
                print("✅ Core Data context saved successfully")
                #endif
            } catch {
                #if DEBUG
                print("❌ Core Data save failed: \(error)")
                #endif
                throw error
            }
        }
    }
}
