import Foundation

internal struct BeatmapDifficultyModel: Decodable {

    struct BeatmapNote: Decodable {
        // TODO: Add definition
    }

    let version: SupportedSchemaVersion
    let notes: [BeatmapNote]

    private enum CodingKeys: String, CodingKey {
        case version = "_version"
//        case events = "_events"
        case notes = "_notes"
//        case obstacles = "_obstacles"
    }
}
