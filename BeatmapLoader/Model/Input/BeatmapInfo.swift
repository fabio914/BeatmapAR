import Foundation

internal typealias Filename = String

internal struct BeatmapInfoModel: Decodable {
    let version: SupportedSchemaVersion
    let songName: String

    private enum CodingKeys: String, CodingKey {
        case version = "_version"
        case songName = "_songName"
    }
}
