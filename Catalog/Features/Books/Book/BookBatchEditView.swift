import SwiftUI

/// Edits shared and book-specific fields for multiple selected books.
struct BookBatchEditView: View {
    let onSave: (ItemBatchEdit, BookBatchEdit) -> Void

    @State private var isEditingLanguage = false
    @State private var languageCode = ""
    @State private var isEditingGenre = false
    @State private var genre = ""
    @State private var isEditingPublicationYear = false
    @State private var publicationYearText = ""
    @State private var isEditingPageCount = false
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
                    name: bookLanguageDisplayName(for: code)
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
            Section {
                Toggle(String(localized: "book.field.language"), isOn: $isEditingLanguage)
                if isEditingLanguage {
                    Picker(String(localized: "book.field.language"), selection: $languageCode) {
                        Text(String(localized: "common.none"))
                            .tag("")
                        ForEach(languageOptions) { option in
                            Text("\(option.name) (\(option.code.uppercased()))")
                                .tag(option.code)
                        }
                    }
                }

                Toggle(String(localized: "book.field.genre"), isOn: $isEditingGenre)
                if isEditingGenre {
                    TextField(String(localized: "book.field.genre"), text: $genre)
                }

                Toggle(String(localized: "book.field.publication_year"), isOn: $isEditingPublicationYear)
                if isEditingPublicationYear {
                    TextField(String(localized: "book.field.publication_year"), text: $publicationYearText)
                        .keyboardType(.numberPad)
                }

                Toggle(String(localized: "book.field.pages"), isOn: $isEditingPageCount)
                if isEditingPageCount {
                    TextField(String(localized: "book.field.pages"), text: $pageCountText)
                        .keyboardType(.numberPad)
                }
            } header: {
                Text(String(localized: "common.book"))
            } footer: {
                Text(String(localized: "catalog.batch_edit.empty_clears"))
            }
        }
    }

    private var bookEdit: BookBatchEdit {
        BookBatchEdit(
            languageCode: stringChange(isEditing: isEditingLanguage, value: languageCode),
            genre: stringChange(isEditing: isEditingGenre, value: genre),
            pageCount: integerChange(isEditing: isEditingPageCount, value: pageCountText),
            publicationYear: integerChange(isEditing: isEditingPublicationYear, value: publicationYearText)
        )
    }

    private var isDomainEditValid: Bool {
        isPositiveIntegerValid(isEditing: isEditingPageCount, value: pageCountText)
            && isPublicationYearValid
    }

    private var isPublicationYearValid: Bool {
        guard isEditingPublicationYear else { return true }

        let trimmed = publicationYearText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        guard let year = Int(trimmed) else { return false }

        let maximumYear = Calendar.current.component(.year, from: Date()) + 1
        return (1...maximumYear).contains(year)
    }

    private func isPositiveIntegerValid(isEditing: Bool, value: String) -> Bool {
        guard isEditing else { return true }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        guard let number = Int(trimmed) else { return false }
        return number > 0
    }

    private func stringChange(isEditing: Bool, value: String) -> BatchEditValue<String> {
        guard isEditing else { return .unchanged }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .set(nil) }
        return .set(trimmed)
    }

    private func integerChange(isEditing: Bool, value: String) -> BatchEditValue<Int> {
        guard isEditing else { return .unchanged }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return .set(trimmed.isEmpty ? nil : Int(trimmed))
    }
}

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
