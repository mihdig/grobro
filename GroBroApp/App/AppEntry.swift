import SwiftUI
import CoreData

@main
struct GroBroApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            GardenView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

