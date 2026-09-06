import SwiftUI

/// Describes how an optional value should be handled by a batch editor.
enum CatalogBatchEditFieldMode: String, CaseIterable, Identifiable {
    case unchanged
    case clear
    case set

    var id: Self { self }

    var displayName: String {
        switch self {
        case .unchanged:
            return String(localized: "catalog.batch_edit.keep_unchanged")
        case .clear:
            return String(localized: "common.clear")
        case .set:
            return String(localized: "catalog.batch_edit.set")
        }
    }
}

/// Hosts fields shared by all catalog batch editors and optional domain-specific sections.
struct CatalogBatchEditView<DomainContent: View>: View {
    let isDomainEditEmpty: Bool
    let isDomainEditValid: Bool
    let onSave: (ItemBatchEdit) -> Void
    private let domainContent: () -> DomainContent

    @Environment(\.dismiss) private var dismiss
    @State private var condition: ItemCondition?
    @State private var acquisitionMethod: AcquisitionMethod?
    @State private var favorite: Bool?
    @State private var acquiredYearMode: CatalogBatchEditFieldMode = .unchanged
    @State private var acquiredYearText = ""
    @State private var tagToAddInput = ""
    @State private var tagsToAdd: [String] = []
    @State private var tagToRemoveInput = ""
    @State private var tagsToRemove: [String] = []

    init(
        isDomainEditEmpty: Bool,
        isDomainEditValid: Bool = true,
        onSave: @escaping (ItemBatchEdit) -> Void,
        @ViewBuilder domainContent: @escaping () -> DomainContent
    ) {
        self.isDomainEditEmpty = isDomainEditEmpty
        self.isDomainEditValid = isDomainEditValid
        self.onSave = onSave
        self.domainContent = domainContent
    }

    var body: some View {
        NavigationStack {
            Form {
                domainContent()

                Section(String(localized: "catalog.batch_edit.fields")) {
                    Picker(String(localized: "common.field.condition"), selection: $condition) {
                        Text(String(localized: "catalog.batch_edit.keep_unchanged"))
                            .tag(nil as ItemCondition?)
                        ForEach(ItemCondition.allCases) { value in
                            Text(value.displayName)
                                .tag(Optional(value))
                        }
                    }

                    Picker(String(localized: "item.detail.acquisition"), selection: $acquisitionMethod) {
                        Text(String(localized: "catalog.batch_edit.keep_unchanged"))
                            .tag(nil as AcquisitionMethod?)
                        ForEach(AcquisitionMethod.allCases) { value in
                            Text(value.displayName)
                                .tag(Optional(value))
                        }
                    }

                    Picker(String(localized: "catalog.batch_edit.favorite"), selection: $favorite) {
                        Text(String(localized: "catalog.batch_edit.keep_unchanged"))
                            .tag(nil as Bool?)
                        Text(String(localized: "catalog.batch_edit.favorite.yes"))
                            .tag(Optional(true))
                        Text(String(localized: "catalog.batch_edit.favorite.no"))
                            .tag(Optional(false))
                    }
                }

                Section(String(localized: "catalog.batch_edit.acquired_year")) {
                    Picker(
                        String(localized: "catalog.batch_edit.acquired_year"),
                        selection: $acquiredYearMode
                    ) {
                        ForEach(CatalogBatchEditFieldMode.allCases) { mode in
                            Text(mode.displayName)
                                .tag(mode)
                        }
                    }

                    if acquiredYearMode == .set {
                        TextField(
                            String(localized: "catalog.batch_edit.acquired_year.placeholder"),
                            text: $acquiredYearText
                        )
                        .keyboardType(.numberPad)
                    }
                }

                Section(String(localized: "catalog.batch_edit.tags.add")) {
                    TagEditorSection(
                        tagInput: $tagToAddInput,
                        tags: $tagsToAdd
                    )
                }

                Section(String(localized: "catalog.batch_edit.tags.remove")) {
                    TagEditorSection(
                        tagInput: $tagToRemoveInput,
                        tags: $tagsToRemove
                    )
                }
            }
            .navigationTitle(String(localized: "catalog.batch_edit.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(String(localized: "common.cancel"))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onSave(batchEdit)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(!canSave)
                    .accessibilityLabel(String(localized: "common.save"))
                }
            }
        }
    }

    private var canSave: Bool {
        (isDomainEditEmpty == false || batchEdit.isEmpty == false)
            && isDomainEditValid
            && isAcquiredYearValid
    }

    private var batchEdit: ItemBatchEdit {
        ItemBatchEdit(
            acquiredYear: acquiredYearChange,
            condition: condition,
            acquisitionMethod: acquisitionMethod,
            isFavorite: favorite,
            tagsToAdd: tagsToAdd,
            tagsToRemove: tagsToRemove
        )
    }

    private var acquiredYearChange: BatchEditValue<Int> {
        switch acquiredYearMode {
        case .unchanged:
            return .unchanged
        case .clear:
            return .set(nil)
        case .set:
            let trimmed = acquiredYearText.trimmingCharacters(in: .whitespacesAndNewlines)
            return .set(Int(trimmed))
        }
    }

    private var isAcquiredYearValid: Bool {
        guard acquiredYearMode == .set else { return true }

        let trimmed = acquiredYearText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let year = Int(trimmed) else { return false }

        let maximumYear = Calendar.current.component(.year, from: Date()) + 1
        return (1...maximumYear).contains(year)
    }
}
