import SwiftUI

/// Renders the resolved visual cover of a book.
struct BookCoverView: View {
    let cover: BookCoverContent
    let size: CGSize

    var body: some View {
        Group {
            switch cover {
            case let .image(asset, _):
                MediaPreviewImage(
                    identifier: asset.localIdentifier.isEmpty ? nil : asset.localIdentifier,
                    originalData: asset.originalData,
                    size: size
                )

            case let .generated(generatedCover):
                generatedCoverView(generatedCover)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func generatedCoverView(_ generatedCover: BookGeneratedCover) -> some View {
        ZStack {
            LinearGradient(
                colors: palette(for: generatedCover.bookID),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: generatedSpacing) {
                Spacer(minLength: 0)

                if !generatedCover.authorNames.isEmpty {
                    Text(generatedCover.authorNames.joined(separator: ", "))
                        .font(.system(size: authorFontSize, weight: .medium))
                        .foregroundStyle(.white.opacity(0.84))
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                }

                Text(generatedCover.title)
                    .font(.system(size: titleFontSize, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(4)
                    .minimumScaleFactor(0.68)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(generatedPadding)
        }
    }

    private var generatedPadding: CGFloat {
        min(max(size.width * 0.09, 10), 22)
    }

    private var generatedSpacing: CGFloat {
        min(max(size.width * 0.04, 6), 12)
    }

    private var titleFontSize: CGFloat {
        min(max(size.width * 0.105, 13), 30)
    }

    private var authorFontSize: CGFloat {
        min(max(size.width * 0.06, 10), 16)
    }

    private func palette(for bookID: UUID) -> [Color] {
        let palettes: [[Color]] = [
            [
                Color(red: 0.30, green: 0.18, blue: 0.13),
                Color(red: 0.63, green: 0.39, blue: 0.24)
            ],
            [
                Color(red: 0.17, green: 0.29, blue: 0.25),
                Color(red: 0.31, green: 0.52, blue: 0.43)
            ],
            [
                Color(red: 0.35, green: 0.16, blue: 0.19),
                Color(red: 0.62, green: 0.31, blue: 0.35)
            ],
            [
                Color(red: 0.19, green: 0.23, blue: 0.34),
                Color(red: 0.37, green: 0.45, blue: 0.62)
            ],
            [
                Color(red: 0.28, green: 0.28, blue: 0.16),
                Color(red: 0.53, green: 0.50, blue: 0.28)
            ],
            [
                Color(red: 0.16, green: 0.27, blue: 0.31),
                Color(red: 0.30, green: 0.49, blue: 0.55)
            ]
        ]

        let index = bookID.uuidString.utf8.reduce(0) { partialResult, byte in
            (partialResult * 31 + Int(byte)) % palettes.count
        }
        return palettes[index]
    }
}
