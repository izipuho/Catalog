import SwiftUI

extension BookEditorView {
    var title: String {
        get { editorState.title }
        nonmutating set { editorState.title = newValue }
    }

    var subtitle: String {
        get { editorState.subtitle }
        nonmutating set { editorState.subtitle = newValue }
    }

    var notes: String {
        get { editorState.notes }
        nonmutating set { editorState.notes = newValue }
    }

    var selectedAcquiredYearOption: String {
        get { editorState.selectedAcquiredYearOption }
        nonmutating set { editorState.selectedAcquiredYearOption = newValue }
    }

    var condition: ItemCondition {
        get { editorState.condition }
        nonmutating set { editorState.condition = newValue }
    }

    var acquisitionMethod: AcquisitionMethod {
        get { editorState.acquisitionMethod }
        nonmutating set { editorState.acquisitionMethod = newValue }
    }

    var tags: [String] {
        get { editorState.tags }
        nonmutating set { editorState.tags = newValue }
    }

    var mediaAssets: [MediaAsset] {
        get { editorState.mediaAssets }
        nonmutating set { editorState.mediaAssets = newValue }
    }

    var coverImage: MediaAsset? {
        get { editorState.coverImage }
        nonmutating set { editorState.coverImage = newValue }
    }

    var languageCode: String {
        get { editorState.languageCode }
        nonmutating set { editorState.languageCode = newValue }
    }

    var genre: String {
        get { editorState.genre }
        nonmutating set { editorState.genre = newValue }
    }

    var pageCount: String {
        get { editorState.pageCount }
        nonmutating set { editorState.pageCount = newValue }
    }

    var selectedPublicationYearOption: String {
        get { editorState.selectedPublicationYearOption }
        nonmutating set { editorState.selectedPublicationYearOption = newValue }
    }

    var selectedSeries: BookSeries? {
        get { editorState.selectedSeries }
        nonmutating set { editorState.selectedSeries = newValue }
    }

    var volumeNumber: String {
        get { editorState.volumeNumber }
        nonmutating set { editorState.volumeNumber = newValue }
    }

    var selectedPublisher: Publisher? {
        get { editorState.selectedPublisher }
        nonmutating set { editorState.selectedPublisher = newValue }
    }

    var contributors: [BookContributor] {
        get { editorState.contributors }
        nonmutating set { editorState.contributors = newValue }
    }

    var identifiers: [BookIdentifier] {
        get { editorState.identifiers }
        nonmutating set { editorState.identifiers = newValue }
    }

    var titleBinding: Binding<String> { binding(\.title) }
    var subtitleBinding: Binding<String> { binding(\.subtitle) }
    var selectedAcquiredYearOptionBinding: Binding<String> { binding(\.selectedAcquiredYearOption) }
    var conditionBinding: Binding<ItemCondition> { binding(\.condition) }
    var acquisitionMethodBinding: Binding<AcquisitionMethod> { binding(\.acquisitionMethod) }
    var tagsBinding: Binding<[String]> { binding(\.tags) }
    var languageCodeBinding: Binding<String> { binding(\.languageCode) }
    var genreBinding: Binding<String> { binding(\.genre) }
    var pageCountBinding: Binding<String> { binding(\.pageCount) }
    var selectedPublicationYearOptionBinding: Binding<String> { binding(\.selectedPublicationYearOption) }
    var selectedSeriesBinding: Binding<BookSeries?> { binding(\.selectedSeries) }
    var volumeNumberBinding: Binding<String> { binding(\.volumeNumber) }
    var selectedPublisherBinding: Binding<Publisher?> { binding(\.selectedPublisher) }
    var notesBinding: Binding<String> { binding(\.notes) }

    private func binding<Value>(_ keyPath: WritableKeyPath<BookEditorState, Value>) -> Binding<Value> {
        Binding(
            get: { editorState[keyPath: keyPath] },
            set: { editorState[keyPath: keyPath] = $0 }
        )
    }
}
