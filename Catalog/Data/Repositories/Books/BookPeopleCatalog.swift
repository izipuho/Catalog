import CoreData
import Foundation

extension CoreDataCatalogRepository {
    func savePerson(_ person: Person) {
        _ = upsertCatalogPerson(person)
        saveContext()
    }

    func deletePerson(personID: UUID) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "PersonEntity")
        request.predicate = NSPredicate(format: "id == %@", personID as NSUUID)
        let people = (try? context.fetch(request)) ?? []
        guard !people.isEmpty else { return }

        for person in people {
            personRelatedObjects(person, "bookContributions").forEach(context.delete)
            personRelatedObjects(person, "photos").forEach(context.delete)
            context.delete(person)
        }

        saveContext()
    }

    @discardableResult
    func upsertCatalogPerson(_ person: Person) -> NSManagedObject {
        let collectionRequest = NSFetchRequest<NSManagedObject>(entityName: "CollectionEntity")
        collectionRequest.predicate = NSPredicate(format: "id == %@", person.collectionID as NSUUID)
        collectionRequest.fetchLimit = 1

        guard let collection = (try? context.fetch(collectionRequest))?.first else {
            preconditionFailure("Person collection does not exist.")
        }

        let request = NSFetchRequest<NSManagedObject>(entityName: "PersonEntity")
        request.predicate = NSPredicate(format: "id == %@", person.id as NSUUID)
        request.fetchLimit = 1

        let existingEntity = (try? context.fetch(request))?.first
        if let existingCollection = existingEntity?.value(forKey: "collection") as? NSManagedObject,
           existingCollection != collection {
            preconditionFailure("PersonEntity cannot be shared across collections.")
        }

        let entity = existingEntity ?? makeEntity(named: "PersonEntity")
        if existingEntity == nil,
           let store = collection.objectID.persistentStore {
            context.assign(entity, to: store)
        }

        entity.setValue(person.id, forKey: "id")
        entity.setValue(person.canonicalID, forKey: "canonicalID")
        entity.setValue(person.givenName, forKey: "givenName")
        entity.setValue(person.familyName, forKey: "familyName")
        entity.setValue(person.middleName, forKey: "middleName")
        entity.setValue(person.birthYear, forKey: "birthYear")
        entity.setValue(person.deathYear, forKey: "deathYear")
        entity.setValue(person.biography, forKey: "biography")
        entity.setValue(person.birthPlace, forKey: "birthPlace")
        entity.setValue(person.deathPlace, forKey: "deathPlace")
        entity.setValue(collection, forKey: "collection")
        replacePersonPhotos(person.photos, for: entity)
        return entity
    }

    private func replacePersonPhotos(_ photos: [MediaAsset], for person: NSManagedObject) {
        let existingPhotos = Set(personRelatedObjects(person, "photos"))
        let incomingIDs = Set(photos.map(\.id))
        var existingByID: [UUID: NSManagedObject] = [:]

        for entity in existingPhotos {
            guard let id = entity.value(forKey: "id") as? UUID else { continue }
            existingByID[id] = entity
        }

        let updatedPhotos = photos.enumerated().map { index, photo -> NSManagedObject in
            let entity = existingByID[photo.id] ?? makeEntity(named: "MediaAssetEntity")
            if entity.objectID.persistentStore == nil,
               let store = person.objectID.persistentStore {
                context.assign(entity, to: store)
            }
            applyReferencePhoto(photo.with(sortOrder: index), to: entity)
            entity.setValue(person, forKey: "person")
            return entity
        }

        for entity in existingPhotos {
            guard
                let id = entity.value(forKey: "id") as? UUID,
                !incomingIDs.contains(id)
            else {
                continue
            }
            context.delete(entity)
        }

        person.setValue(Set(updatedPhotos), forKey: "photos")
    }

    private func applyReferencePhoto(_ asset: MediaAsset, to entity: NSManagedObject) {
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

    private func personRelatedObjects(_ entity: NSManagedObject, _ key: String) -> [NSManagedObject] {
        if let objects = entity.value(forKey: key) as? Set<NSManagedObject> {
            return Array(objects)
        }

        return (entity.value(forKey: key) as? NSSet)?.allObjects.compactMap { $0 as? NSManagedObject } ?? []
    }
}
