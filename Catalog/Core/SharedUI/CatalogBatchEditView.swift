import SwiftUI

/// Edits fields shared by multiple selected catalog items.
struct CatalogBatchEditView: View {
    let onSave: (ItemBatchEdit) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var condition: ItemCondition?
    @State private var acquisitionMethod: AcquisitionMethod?
    @State private var favorite: Bool?
    @State private var isEditingAcquiredYear = false
    @State private var acquiredYearText = ""
    @State private var tagToAddInput = ""
    @State private var tagsToAdd: [String] = []
    @State private var tagToRemoveInput = ""
    @State private var tagsToRemove: [String] = []

    var body: some View {
        NavigationStack {
            Form {
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

                Section {
                    Toggle(
                        String(localized: "catalog.batch_edit.acquired_year.change"),
                        isOn: $isEditingAcquiredYear
                    )

                    if isEditingAcquiredYear {
                        TextField(
                            String(localized: "catalog.batch_edit.acquired_year.placeholder"),
                            text: $acquiredYearText
                        )
                        .keyboardType(.numberPad)

                        Text(String(localized: "catalog.batch_edit.acquired_year.clear_hint"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(String(localized: "catalog.batch_edit.acquired_year"))
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
                    .disabled(batchEdit.isEmpty || !isAcquiredYearValid)
                    .accessibilityLabel(String(localized: "common.save"))
                }
            }
        }
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

    private var acquiredYearChange: ItemBatchEdit.AcquiredYearChange {
        guard isEditingAcquiredYear else { return .unchanged }

        let trimmed = acquiredYearText.trimmingCharacters(in: .whitespacesAndNewlines)
        return .set(trimmed.isEmpty ? nil : Int(trimmed))
    }

    private var isAcquiredYearValid: Bool {
        guard isEditingAcquiredYear else { return true }

        let trimmed = acquiredYearText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        guard let year = Int(trimmed) else { return false }

        let maximumYear = Calendar.current.component(.year, from: Date()) + 1
        return (1...maximumYear).contains(year)
    }
}
