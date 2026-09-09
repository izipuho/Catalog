import Foundation

/// Owns the mutable OCR text-fragment workflow for the book editor.
struct BookTextAssignmentController {
    struct PreparedAssignment {
        let target: BookTextTarget
        let fragments: [TextFragment]
        let assignment: BookTextAssignment
    }

    enum RemovalAction {
        case apply(BookTextAssignment)
        case deleteAuthor(Int)
    }

    private var fragmentState = TextFragmentState<BookTextTarget>()
    private var authorBaseNames: [Int: String] = [:]

    var assignments: [BookTextTarget: [TextFragment]] {
        fragmentState.assignments
    }

    var fragments: [TextFragment] {
        fragmentState.fragments
    }

    var usedFragmentIDs: Set<UUID> {
        fragmentState.usedFragmentIDs
    }

    var hasUnusedFragments: Bool {
        fragmentState.hasUnusedFragments
    }

    var authorIndices: [Int] {
        assignments.keys.compactMap { target -> Int? in
            guard case let .author(index) = target else { return nil }
            return index
        }
        .sorted()
    }

    mutating func sync(from recognizedText: [RecognizedTextFeature]) {
        let sources = recognizedText.enumerated().map { index, feature in
            TextFragmentSource(
                text: feature.text,
                confidence: feature.confidence,
                boundingBox: feature.boundingBox,
                sourceIndex: index
            )
        }
        fragmentState.sync(from: sources)
    }

    mutating func prepareAssignment(
        _ droppedFragments: [TextFragmentTransfer],
        to target: BookTextTarget
    ) -> PreparedAssignment? {
        var newFragments = fragmentState.matching(droppedFragments)
        guard !newFragments.isEmpty else { return nil }

        switch target {
        case .field(.volume):
            newFragments = prepareFragments(newFragments, using: .volume)
        case .field(.publicationYear):
            newFragments = prepareFragments(newFragments, using: .publicationYear)
        default:
            break
        }

        guard !newFragments.isEmpty else { return nil }

        let assigned = fragmentState.mergedAssignment(adding: newFragments, to: target)
        return PreparedAssignment(
            target: target,
            fragments: assigned,
            assignment: BookTextAssignmentRules.makeAssignment(from: assigned)
        )
    }

    mutating func commit(_ preparedAssignment: PreparedAssignment) {
        fragmentState.setAssignment(
            preparedAssignment.fragments,
            for: preparedAssignment.target
        )
    }

    mutating func remove(
        _ fragment: TextFragment,
        from target: BookTextTarget
    ) -> RemovalAction {
        let assignedFragments = fragmentState.remove(fragment, from: target)

        if assignedFragments.isEmpty,
           case let .author(index) = target,
           authorBaseNames[index] == "" {
            return .deleteAuthor(index)
        }

        return .apply(BookTextAssignmentRules.makeAssignment(from: assignedFragments))
    }

    @discardableResult
    mutating func consumeAssignment(for target: BookTextTarget) -> Bool {
        !fragmentState.consumeAssignment(for: target).isEmpty
    }

    func matching(_ transfers: [TextFragmentTransfer]) -> [TextFragment] {
        fragmentState.matching(transfers)
    }

    func assignment(for target: BookTextTarget) -> [TextFragment]? {
        fragmentState.assignments[target]
    }

    mutating func setAssignment(
        _ fragments: [TextFragment],
        for target: BookTextTarget
    ) {
        fragmentState.setAssignment(fragments, for: target)
    }

    func authorBaseName(for index: Int) -> String? {
        authorBaseNames[index]
    }

    mutating func setAuthorBaseName(_ name: String, for index: Int) {
        authorBaseNames[index] = name
    }

    mutating func remapAuthors(survivingIndices: [Int]) {
        var remappedAssignments: [BookTextTarget: [TextFragment]] = [:]
        for (target, fragments) in fragmentState.assignments {
            if case .field = target {
                remappedAssignments[target] = fragments
            }
        }

        var remappedBaseNames: [Int: String] = [:]
        for (newIndex, oldIndex) in survivingIndices.enumerated() {
            if let fragments = fragmentState.assignments[.author(oldIndex)] {
                remappedAssignments[.author(newIndex)] = fragments
            }
            if let baseName = authorBaseNames[oldIndex] {
                remappedBaseNames[newIndex] = baseName
            }
        }

        fragmentState.assignments = remappedAssignments
        authorBaseNames = remappedBaseNames
    }

    private enum FragmentPreparation {
        case volume
        case publicationYear
    }

    private mutating func prepareFragments(
        _ fragments: [TextFragment],
        using preparation: FragmentPreparation
    ) -> [TextFragment] {
        var preparedFragments: [TextFragment] = []

        for fragment in fragments {
            let preparedFragment: TextFragment?
            switch preparation {
            case .volume:
                preparedFragment = prepareVolumeFragment(fragment)
            case .publicationYear:
                preparedFragment = preparePublicationYearFragment(fragment)
            }

            if let preparedFragment {
                preparedFragments.append(preparedFragment)
            }
        }

        return preparedFragments
    }

    private mutating func prepareVolumeFragment(_ fragment: TextFragment) -> TextFragment? {
        guard let extraction = BookTextAssignmentRules.volumeExtraction(in: fragment.text) else {
            return nil
        }

        return fragmentState.split(
            fragment,
            extracting: extraction.range,
            replacementText: extraction.replacementText
        )
    }

    private mutating func preparePublicationYearFragment(_ fragment: TextFragment) -> TextFragment? {
        guard let extraction = BookTextAssignmentRules.publicationYearExtraction(in: fragment.text) else {
            return nil
        }

        return fragmentState.split(
            fragment,
            extracting: extraction.range,
            replacementText: extraction.replacementText
        )
    }
}
