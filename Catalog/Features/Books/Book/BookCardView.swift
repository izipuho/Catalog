import SwiftUI

#if DEBUG
import CoreData
#endif

/// Displays a book card using the shared catalog card system.
struct BookCardView: View {
    let book: BookRecord
    let cardSize: CGSize

    private let style: CatalogCardContentStyle
    private let cardMetrics: CatalogCardLayoutMode.CardMetrics
    private let accessories: [CatalogCardAccessory]

    init(
        book: BookRecord,
        style: CatalogCardContentStyle,
        cardSize: CGSize,
        cardMetrics: CatalogCardLayoutMode.CardMetrics,
        accessories: [CatalogCardAccessory] = []
    ) {
        self.book = book
        self.cardSize = cardSize
        self.style = style
        self.cardMetrics = cardMetrics
        self.accessories = accessories
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            BookCoverView(
                cover: book.cover,
                size: contentSize
            )

            mediaContent
        }
        .frame(width: contentSize.width, height: contentSize.height)
        .catalogSurfaceCard(cardMetrics: cardMetrics)
        .frame(width: cardSize.width, height: cardSize.height)
    }

    @ViewBuilder
    private var mediaContent: some View {
        if let accessoryRowStyle = style.accessoryRow, !accessories.isEmpty {
            CatalogCardAccessoryRow(
                accessories: accessories,
                style: accessoryRowStyle,
                bright: true
            )
            .frame(
                width: contentSize.width,
                height: contentSize.height,
                alignment: .bottomLeading
            )
        } else {
            Color.clear
                .frame(width: contentSize.width, height: contentSize.height)
        }
    }

    private var contentSize: CGSize {
        CGSize(
            width: max(cardSize.width - (cardMetrics.cardPadding * 2), 0),
            height: max(cardSize.height - (cardMetrics.cardPadding * 2), 0)
        )
    }
}

#if DEBUG
#Preview {
    let container = PreviewContainer.makeBooksMinimal()
    let snapshot = CatalogSnapshot.load(from: container.viewContext)

    if let book = snapshot.bookRecords.first {
        BookCardView(
            book: book,
            style: .compact,
            cardSize: CGSize(width: 220, height: 220),
            cardMetrics: CatalogCardLayoutMode.compact.cardMetrics
        )
        .padding()
    }
}
#endif
