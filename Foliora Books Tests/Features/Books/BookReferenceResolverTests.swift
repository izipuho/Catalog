import Foundation
import Testing
@testable import Foliora_Books

struct BookReferenceResolverTests {
    private let testCollectionID = UUID()

    @Test
    func reusesExistingPublisherAndSeriesIgnoringWhitespaceCaseAndDiacritics() {
        let collectionID = UUID()
        let publisher = Publisher(
            id: UUID(),
            collectionID: collectionID,
            name: "Éditions Test"
        )
        let series = BookSeries(
            id: UUID(),
            collectionID: collectionID,
            name: "Saga Test",
            totalBookCount: nil
        )
        let resolver = BookReferenceResolver(
            collectionID: collectionID,
            catalogSeries: [series],
            catalogPublishers: [publisher],
            catalogPeople: [],
            contributors: [],
            selectedSeries: nil,
            selectedPublisher: nil
        )

        #expect(resolver.resolvePublisher(named: "  editions   TEST ")?.id == publisher.id)
        #expect(resolver.resolveSeries(named: "  SAGA   test ")?.id == series.id)
    }

    @Test
    func matchesPersonByInitialsWhenTheBestMatchIsUnique() {
        let person = makePerson(givenName: "Ivan", middleName: "Ivanovich", familyName: "Petrov")
        let resolver = makeResolver(people: [person])

        #expect(resolver.existingCatalogPerson(named: "I. Petrov")?.id == person.id)
        #expect(resolver.resolvePerson(named: "I. Petrov")?.id == person.id)
    }

    @Test
    func doesNotChooseBetweenAmbiguousPersonMatches() {
        let ivan = makePerson(givenName: "Ivan", familyName: "Petrov")
        let igor = makePerson(givenName: "Igor", familyName: "Petrov")
        let resolver = makeResolver(people: [ivan, igor])

        #expect(resolver.existingCatalogPerson(named: "I. Petrov") == nil)
    }

    @Test
    func availablePeopleIncludeTransientContributorWithoutDuplicatingCatalogPerson() {
        let catalogPerson = makePerson(givenName: "Anna", familyName: "Smith")
        let transientPerson = makePerson(givenName: "John", familyName: "Doe")
        let resolver = BookReferenceResolver(
            collectionID: testCollectionID,
            catalogSeries: [],
            catalogPublishers: [],
            catalogPeople: [catalogPerson],
            contributors: [
                BookContributor(role: .author, order: 0, person: catalogPerson),
                BookContributor(role: .editor, order: 1, person: transientPerson)
            ],
            selectedSeries: nil,
            selectedPublisher: nil
        )

        #expect(Set(resolver.availablePeople.map(\.id)) == Set([catalogPerson.id, transientPerson.id]))
    }

    @Test
    func ignoresPeopleAndPublishersFromOtherCollections() {
        let localPerson = makePerson(givenName: "Local")
        let foreignPerson = Person(
            id: UUID(),
            collectionID: UUID(),
            givenName: "Foreign",
            birthYear: nil,
            deathYear: nil,
            biography: nil,
            birthPlace: nil,
            deathPlace: nil
        )
        let localPublisher = Publisher(
            id: UUID(),
            collectionID: testCollectionID,
            name: "Local Publisher"
        )
        let foreignPublisher = Publisher(
            id: UUID(),
            collectionID: UUID(),
            name: "Foreign Publisher"
        )
        let resolver = BookReferenceResolver(
            collectionID: testCollectionID,
            catalogSeries: [],
            catalogPublishers: [localPublisher, foreignPublisher],
            catalogPeople: [localPerson, foreignPerson],
            contributors: [],
            selectedSeries: nil,
            selectedPublisher: nil
        )

        #expect(resolver.availablePeople.map(\.id) == [localPerson.id])
        #expect(resolver.availablePublishers.map(\.id) == [localPublisher.id])
    }

    private func makeResolver(people: [Person]) -> BookReferenceResolver {
        BookReferenceResolver(
            collectionID: testCollectionID,
            catalogSeries: [],
            catalogPublishers: [],
            catalogPeople: people,
            contributors: [],
            selectedSeries: nil,
            selectedPublisher: nil
        )
    }

    private func makePerson(
        givenName: String,
        middleName: String? = nil,
        familyName: String? = nil
    ) -> Person {
        Person(
            id: UUID(),
            collectionID: testCollectionID,
            givenName: givenName,
            familyName: familyName,
            middleName: middleName,
            birthYear: nil,
            deathYear: nil,
            biography: nil,
            birthPlace: nil,
            deathPlace: nil
        )
    }
}
