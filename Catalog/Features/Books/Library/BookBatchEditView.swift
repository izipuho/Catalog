import SwiftUI

/// Edits shared and book-specific fields for multiple selected books.
struct BookBatchEditView: View {
    let onSave: (ItemBatchEdit, BookBatchEdit) -> Void

    @State private var languageCode: String?
    @State private var languageShouldClear = false
    @State private var genre = ""
    @State private var genreShouldClear = false
    @State private var publicationYearText = ""
    @State private var publicationYearShouldClear = false

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
                HStack(spacing: 8) {
                    Picker(String(localized: "book.field.language"), selection: languageBinding) {
                        Text(String(localized: "catalog.batch_edit.keep_unchanged"))
                            .tag(nil as String?)
                        ForEach(languageOptions) { option in
                            Text("\(option.name) (\(option.code.uppercased()))")
                                .tag(Optional(option.code))
                        }
                    }

                    clearButton(isActive: languageShouldClear) {
                        languageCode = nil
                        languageShouldClear = true
                    }
                }

                LabeledContent(String(localized: "book.field.genre")) {
                    HStack(spacing: 8) {
                        TextField("", text: genreBinding)
                            .multilineTextAlignment(.trailing)

                        clearButton(isActive: genreShouldClear) {
                            genre = ""
                            genreShouldClear = true
                        }
                    }
                }

                LabeledContent(String(localized: "book.field.publication_year")) {
                    HStack(spacing: 8) {
                        TextField("", text: publicationYearBinding)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)

                        clearButton(isActive: publicationYearShouldClear) {
                            publicationYearText = ""
                            publicationYearShouldClear = true
                        }
                    }
                }
            }
        }
    }

    private var bookEdit: BookBatchEdit {
        BookBatchEdit(
            languageCode: languageChange,
            genre: stringChange(value: genre, shouldClear: genreShouldClear),
            pageCount: .unchanged,
            publicationYear: integerChange(
                value: publicationYearText,
                shouldClear: publicationYearShouldClear
            )
        )
    }

    private var isDomainEditValid: Bool {
        isPublicationYearValid
    }

    private var languageBinding: Binding<String?> {
        Binding(
            get: { languageCode },
            set: { value in
                languageCode = value
                languageShouldClear = false
            }
        )
    }

    private var genreBinding: Binding<String> {
        Binding(
            get: { genre },
            set: { value in
                genre = value
                genreShouldClear = false
            }
        )
    }

    private var publicationYearBinding: Binding<String> {
        Binding(
            get: { publicationYearText },
            set: { value in
                publicationYearText = value
                publicationYearShouldClear = false
            }
        )
    }

    private var languageChange: BatchEditValue<String> {
        if languageShouldClear {
            return .set(nil)
        }
        guard let languageCode else { return .unchanged }
        return .set(languageCode)
    }

    private var isPublicationYearValid: Bool {
        guard !publicationYearShouldClear else { return true }

        let trimmed = publicationYearText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        guard let year = Int(trimmed) else { return false }

        let maximumYear = Calendar.current.component(.year, from: Date()) + 1
        return (1...maximumYear).contains(year)
    }

    private func stringChange(
        value: String,
        shouldClear: Bool
    ) -> BatchEditValue<String> {
        if shouldClear {
            return .set(nil)
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .unchanged }
        return .set(trimmed)
    }

    private func integerChange(
        value: String,
        shouldClear: Bool
    ) -> BatchEditValue<Int> {
        if shouldClear {
            return .set(nil)
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .unchanged }
        return .set(Int(trimmed))
    }

    private func clearButton(
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.red)
        .opacity(isActive ? 1 : 0.35)
        .accessibilityLabel(String(localized: "common.clear"))
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
