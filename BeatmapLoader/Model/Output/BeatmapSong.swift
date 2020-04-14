import UIKit

public enum BeatmapDifficulty {
    case easy
    case normal
    case hard
    case expert
    case expertPlus
}

public struct BeatmapSongDifficulty {
    public let difficulty: BeatmapDifficulty
    // TODO: Add events, notes, etc...
}

public struct BeatmapSong {
    public let songName: String
    public let songSubName: String
    public let songAuthorName: String
    public let levelAuthorName: String
    public let beatsPerMinute: UInt
    public let songTimeOffset: TimeInterval
    public let coverImage: UIImage
    public let difficulties: [BeatmapSongDifficulty]
}
