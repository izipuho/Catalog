import Foundation
import CoreData

/// Represents app container data and behavior.
@MainActor
struct AppContainer {
    let repository: any AppRepository

    init(repository: any AppRepository) {
        self.repository = repository
    }

    init(coreDataContainer: NSPersistentCloudKitContainer) {
        self.repository = CoreDataCatalogRepository(context: coreDataContainer.viewContext)
    }
}
