import SwiftUI

/// Edits shared and book-specific fields for multiple selected books.
struct BookBatchEditView: View {
    let onSave: (ItemBatchEdit, BookBatchEdit) -> Void

    @State private var languageMode: CatalogBatchEditFieldMode = .unchanged
    @State private var languageCode = ""
    @State private var genreMode: CatalogBatchEditFieldMode = .unchanged
    @State private var genre = ""
    @State private var publicationYearMode: CatalogBatchEditFieldMode = .unchanged
    @State private var publicationYearText = ""
    @State private var pageCountMode: CatalogBatchEditFieldMode = .unchanged
    @State private var pageCountText = ""

    private struct LanguageOption: Identifiable {
        let code: String
        let name: String

        var id: String { code }
    }

    private var languageOptions: [LanguageOption] {
        Locale.LanguageCode.isoLanguageCodes
            .map(\.identifier)
            .map { code in
                LanguageOption(
                    code: code,
                    name: BookLanguageFormatter.displayName(for: code)
                )
            }
            .sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    var body: some View {
        CatalogBatchEditView(
            isDomainEditEmpty: bookEdit.isEmpty,
            isDomainEditValid: isDomainEditValid,
            onSave: { itemEdit in
                onSave(itemEdit, bookEdit)
            }
        ) {
            Section(String(localized: "common.book")) {
                fieldModePicker(
                    title: String(localized: "book.field.language"),
                    selection: $languageMode
                )

                if languageMode == .set {
                    Picker(String(localized: "book.field.language"), selection: $languageCode) {
                        Text("—")
                            .tag("")
                        ForEach(languageOptions) { option in
                            Text("\(option.name) (\(option.code.uppercased()))")
                                .tag(option.code)
                        }
                    }
                }

                fieldModePicker(
                    title: String(localized: "book.field.genre"),
                    selection: $genreMode
                )

                if genreMode == .set {
                    TextField(String(localized: "book.field.genre"), text: $genre)
                }

                fieldModePicker(
                    title: String(localized: "book.field.publication_year"),
                    selection: $publicationYearMode
                )

                if publicationYearMode == .set {
                    TextField(
                        String(localized: "book.field.publication_year"),
                        text: $publicationYearText
                    )
                    .keyboardType(.numberPad)
                }

                fieldModePicker(
                    title: String(localized: "book.field.pages"),
                    selection: $pageCountMode
                )

                if pageCountMode == .set {
                    TextField(
                        String(localized: "book.field.pages"),
                        text: $pageCountText
                    )
                    .keyboardType(.numberPad)
                }
            }
        }
    }

    private var bookEdit: BookBatchEdit {
        BookBatchEdit(
            languageCode: stringChange(mode: languageMode, value: languageCode),
            genre: stringChange(mode: genreMode, value: genre),
            pageCount: integerChange(mode: pageCountMode, value: pageCountText),
            publicationYear: integerChange(mode: publicationYearMode, value: publicationYearText)
        )
    }

    private var isDomainEditValid: Bool {
        isLanguageValid
            && isGenreValid
            && isPageCountValid
            && isPublicationYearValid
    }

    private var isLanguageValid: Bool {
        languageMode != .set || !languageCode.isEmpty
    }

    private var isGenreValid: Bool {
        guard genreMode == .set else { return true }
        return !genre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isPageCountValid: Bool {
        guard pageCountMode == .set else { return true }

        let trimmed = pageCountText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let number = Int(trimmed) else { return false }
        return number > 0
    }

    private var isPublicationYearValid: Bool {
        guard publicationYearMode == .set else { return true }

        let trimmed = publicationYearText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let year = Int(trimmed) else { return false }

        let maximumYear = Calendar.current.component(.year, from: Date()) + 1
        return (1...maximumYear).contains(year)
    }

    private func stringChange(
        mode: CatalogBatchEditFieldMode,
        value: String
    ) -> BatchEditValue<String> {
        switch mode {
        case .unchanged:
            return .unchanged
        case .clear:
            return .set(nil)
        case .set:
            return .set(value.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private func integerChange(
        mode: CatalogBatchEditFieldMode,
        value: String
    ) -> BatchEditValue<Int> {
        switch mode {
        case .unchanged:
            return .unchanged
        case .clear:
            return .set(nil)
        case .set:
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return .set(Int(trimmed))
        }
    }

    @ViewBuilder
    private func fieldModePicker(
        title: String,
        selection: Binding<CatalogBatchEditFieldMode>
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(CatalogBatchEditFieldMode.allCases) { mode in
                Text(mode.displayName)
                    .tag(mode)
            }
        }
    }
}

#if DEBUG
#Preview {
    BookBatchEditView { _, _ in }
}
#endif

extension CatalogCardManagementModifier where Item == BookRecord {
    init(
        state: Binding<CatalogCardManagementState<BookRecord>>,
        visibleItems: [BookRecord],
        snapshot: CatalogSnapshot?,
        collection: CollectionSummary?,
        currentLocationID: @escaping (BookRecord) -> UUID?,
        moveTitle: String,
        deleteTitle: String,
        deleteMessage: String,
        selectedTitle: @escaping (Int) -> String,
        canEdit: Bool,
        tint: Color,
        onSaveHome: @escaping (Home, [Location]) -> Void,
        onMove: @escaping ([BookRecord], UUID?) -> Void,
        onDelete: @escaping ([BookRecord]) -> Void,
        onBatchEdit: @escaping ([BookRecord], ItemBatchEdit, BookBatchEdit) -> Void
    ) {
        self.init(
            state: state,
            visibleItems: visibleItems,
            snapshot: snapshot,
            collection: collection,
            currentLocationID: currentLocationID,
            moveTitle: moveTitle,
            deleteTitle: deleteTitle,
            deleteMessage: deleteMessage,
            selectedTitle: selectedTitle,
            canEdit: canEdit,
            tint: tint,
            onSaveHome: onSaveHome,
            onMove: onMove,
            onDelete: onDelete,
            batchEditContent: {
                AnyView(
                    BookBatchEditView { itemEdit, bookEdit in
                        onBatchEdit(
                            state.wrappedValue.selectedItems(in: visibleItems),
                            itemEdit,
                            bookEdit
                        )
                        state.wrappedValue.completeAction()
                    }
                )
            }
        )
    }
}

extension LibraryView {
    func batchEditBooks(
        _ books: [BookRecord],
        itemEdit: ItemBatchEdit,
        bookEdit: BookBatchEdit
    ) {
        let updatedBooks = books.map { book in
            BookRecord(
                item: itemEdit.applying(to: book.item),
                details: bookEdit.applying(to: book.details)
            )
        }
        (repository as! any BookCatalogRepository).saveBookRecords(updatedBooks)
    }
}
