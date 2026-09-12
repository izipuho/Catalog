import CoreData
import Foundation

extension CoreDataCatalogRepository {
    func requireCollectionEntity(id: UUID) -> NSManagedObject {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CollectionEntity")
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        request.fetchLimit = 1

        guard let collection = (try? context.fetch(request))?.first else {
            preconditionFailure("CollectionEntity does not exist: \(id)")
        }

        return collection
    }

    func collectionOwnedEntity(
        named entityName: String,
        id: UUID,
        in collection: NSManagedObject
    ) -> NSManagedObject {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        request.fetchLimit = 1

        let existingEntity = (try? context.fetch(request))?.first
        if let existingCollection = existingEntity?.value(forKey: "collection") as? NSManagedObject,
           existingCollection != collection {
            preconditionFailure("\(entityName) cannot be shared across collections.")
        }

        let entity = existingEntity ?? makeEntity(named: entityName)
        if existingEntity == nil,
           let store = collection.objectID.persistentStore {
            context.assign(entity, to: store)
        }

        entity.setValue(id, forKey: "id")
        entity.setValue(collection, forKey: "collection")
        return entity
    }

    func canonicalCopies(
        named entityName: String,
        canonicalID: UUID,
        excluding physicalID: UUID
    ) -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = NSPredicate(
            format: "canonicalID == %@ AND id != %@",
            canonicalID as NSUUID,
            physicalID as NSUUID
        )
        return (try? context.fetch(request)) ?? []
    }

    func applyReferenceMediaAsset(_ asset: MediaAsset, to entity: NSManagedObject) {
        let isNewEntity = entity.value(forKey: "id") == nil
        let existingChecksum = entity.value(forKey: "checksum") as? String
        let shouldUpdateOriginalData = isNewEntity || existingChecksum != asset.checksum

        entity.setValue(asset.id, forKey: "id")
        entity.setValue(asset.kind.rawValue, forKey: "kind")
        entity.setValue(asset.localIdentifier, forKey: "localIdentifier")
        entity.setValue(asset.displayName, forKey: "displayName")
        entity.setValue(asset.sortOrder, forKey: "sortOrder")
        entity.setValue(asset.fileName, forKey: "fileName")
        entity.setValue(asset.mimeType, forKey: "mimeType")
        entity.setValue(asset.byteSize, forKey: "byteSize")
        entity.setValue(asset.checksum, forKey: "checksum")
        entity.setValue(asset.width, forKey: "width")
        entity.setValue(asset.height, forKey: "height")
        entity.setValue(asset.duration, forKey: "duration")
        entity.setValue(asset.metadataJSON, forKey: "metadataJSON")
        if shouldUpdateOriginalData {
            entity.setValue(asset.originalData, forKey: "originalData")
        }
    }
}
