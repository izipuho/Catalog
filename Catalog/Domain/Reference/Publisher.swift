import Foundation

/// Represents a book publisher.
struct Publisher: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var logo: MediaAsset?

    init(
        id: UUID,
        name: String,
        logo: MediaAsset? = nil
    ) {
        self.id = id
        self.name = name
        self.logo = logo
    }
}
