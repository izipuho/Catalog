import SwiftUI

/// Renders the shared contributors section while leaving contributor state semantics to the caller.
struct BookContributorsEditorSubview<RowContent: View, AddContent: View>: View {
    let rowCount: Int
    let onDelete: (IndexSet) -> Void

    private let rowContent: (Int) -> RowContent
    private let addContent: () -> AddContent

    init(
        rowCount: Int,
        onDelete: @escaping (IndexSet) -> Void,
        @ViewBuilder rowContent: @escaping (Int) -> RowContent,
        @ViewBuilder addContent: @escaping () -> AddContent
    ) {
        self.rowCount = rowCount
        self.onDelete = onDelete
        self.rowContent = rowContent
        self.addContent = addContent
    }

    var body: some View {
        Section("book.section.contributors") {
            ForEach(0..<rowCount, id: \.self) { index in
                rowContent(index)
            }
            .onDelete(perform: onDelete)

            addContent()
        }
    }
}

/// Displays a contributor or a pending batch clear using the same row layout.
struct BookContributorEditorRow: View {
    let role: BookContributorRole
    let person: Person?
    let statusSystemImage: String?
    let onTap: () -> Void

    init(
        role: BookContributorRole,
        person: Person?,
        statusSystemImage: String? = nil,
        onTap: @escaping () -> Void
    ) {
        self.role = role
        self.person = person
        self.statusSystemImage = statusSystemImage
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(role.displayName)
                    .foregroundStyle(.secondary)

                Spacer()

                if let person {
                    Text(person.displayName)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.trailing)
                } else {
                    Text(String(localized: "common.clear"))
                        .foregroundStyle(.red)
                }

                if let statusSystemImage {
                    Image(systemName: statusSystemImage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(CatalogTypography.chipLabel)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Edits one contributor selection. Callers define validation, clear semantics, and persistence.
struct BookContributorEditorView: View {
    let title: String
    let people: [Person]
    let availableRoles: [BookContributorRole]
    let onCreatePerson: ((Person) -> Void)?
    let onClear: ((BookContributorRole) -> Void)?
    let validationMessage: (BookContributorRole, Person?) -> String?
    let onSave: (BookContributorRole, Person) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var role: BookContributorRole
    @State private var selectedPerson: Person?
    @State private var isPresentingPersonPicker = false

    init(
        title: String,
        role: BookContributorRole,
        person: Person?,
        people: [Person],
        availableRoles: [BookContributorRole] = BookContributorRole.allCases,
        onCreatePerson: ((Person) -> Void)? = nil,
        onClear: ((BookContributorRole) -> Void)? = nil,
        validationMessage: @escaping (BookContributorRole, Person?) -> String? = { _, _ in nil },
        onSave: @escaping (BookContributorRole, Person) -> Void
    ) {
        self.title = title
        self.people = people
        self.availableRoles = availableRoles.isEmpty ? [role] : availableRoles
        self.onCreatePerson = onCreatePerson
        self.onClear = onClear
        self.validationMessage = validationMessage
        self.onSave = onSave
        _role = State(initialValue: role)
        _selectedPerson = State(initialValue: person)
    }

    private var currentValidationMessage: String? {
        validationMessage(role, selectedPerson)
    }

    private var canSave: Bool {
        selectedPerson != nil && currentValidationMessage == nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("book_contributor.section.contribution") {
                    Picker("book_contributor.field.role", selection: $role) {
                        ForEach(availableRoles) { role in
                            Text(role.displayName)
                                .tag(role)
                        }
                    }

                    Button {
                        isPresentingPersonPicker = true
                    } label: {
                        HStack {
                            Text("person.title")
                                .foregroundStyle(.primary)

                            Spacer()

                            Text(selectedPerson?.displayName ?? String(localized: "common.none"))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)

                            Image(systemName: "chevron.right")
                                .font(CatalogTypography.chipLabel)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)

                    if let currentValidationMessage {
                        Label(
                            currentValidationMessage,
                            systemImage: "exclamationmark.circle.fill"
                        )
                        .font(.footnote)
                        .foregroundStyle(CatalogSemanticColors.destructive)
                    }
                }

                if let onClear {
                    Section {
                        Button(role: .destructive) {
                            onClear(role)
                            dismiss()
                        } label: {
                            Label("common.clear", systemImage: "xmark.circle.fill")
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(String(localized: "common.cancel"))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        guard let selectedPerson else { return }
                        onSave(role, selectedPerson)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(!canSave)
                    .accessibilityLabel(String(localized: "common.save"))
                }
            }
            .sheet(isPresented: $isPresentingPersonPicker) {
                BookPersonSelectionView(
                    selection: $selectedPerson,
                    people: people,
                    onCreate: onCreatePerson
                )
            }
        }
    }
}

struct BookPersonSelectionView: View {
    @Binding var selection: Person?
    let people: [Person]
    let onCreate: ((Person) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredPeople: [Person] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return people }
        return people.filter { $0.displayName.localizedCaseInsensitiveContains(query) }
    }

    private var newPersonName: String? {
        guard onCreate != nil else { return nil }
        let candidate = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidate.isEmpty else { return nil }
        guard !people.contains(where: { $0.displayName.caseInsensitiveCompare(candidate) == .orderedSame }) else {
            return nil
        }
        return candidate
    }

    var body: some View {
        NavigationStack {
            List {
                if let newPersonName, let onCreate {
                    Button {
                        let newPerson = Person(
                            id: UUID(),
                            givenName: newPersonName,
                            birthYear: nil,
                            deathYear: nil,
                            biography: nil,
                            birthPlace: nil,
                            deathPlace: nil,
                            photos: []
                        )
                        onCreate(newPerson)
                        selection = newPerson
                        dismiss()
                    } label: {
                        Label(
                            String.localizedStringWithFormat(String(localized: "common.action.add_value"), newPersonName),
                            systemImage: "plus.circle.fill"
                        )
                    }
                }

                Button {
                    selection = nil
                    dismiss()
                } label: {
                    HStack {
                        Text(String(localized: "common.none"))
                            .foregroundStyle(.primary)

                        Spacer()

                        if selection == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }

                ForEach(filteredPeople) { person in
                    Button {
                        selection = person
                        dismiss()
                    } label: {
                        HStack {
                            Text(person.displayName)
                                .foregroundStyle(.primary)

                            Spacer()

                            if selection?.id == person.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
            }
            .navigationTitle("person.title")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                prompt: Text(
                    onCreate == nil
                        ? String(localized: "person.title")
                        : String(localized: "picker.search_or_add")
                )
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(String(localized: "common.cancel"))
                }
            }
        }
    }
}
