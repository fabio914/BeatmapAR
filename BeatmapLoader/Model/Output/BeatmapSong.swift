import UIKit

public enum BeatmapDifficulty {
    case easy
    case normal
    case hard
    case expert
    case expertPlus
}

public enum BeatmapColumn {
    case leftmost
    case left
    case right
    case rightmost
}

public enum BeatmapRow {
    case bottom
    case middle
    case top
}

public struct BeatmapCoordinates {
    let row: BeatmapRow
    let column: BeatmapColumn
}

public enum BeatmapDirection {
    case bottomToTop
    case topToBottom
    case rightToLeft
    case leftToRight
    case bottomRightToTopLeft
    case bottomLeftToTopRight
    case topRightToBottomLeft
    case topLeftToBottomRight
    case anyDirection
}

public enum BeatmapNote {
    case bomb
    case redBlock(BeatmapDirection)
    case blueBlock(BeatmapDirection)

    public var isBomb: Bool {
        if case .bomb = self { return true } else { return false }
    }
}

public struct BeatmapNoteEvent {
    public let time: TimeInterval
    public let note: BeatmapNote
}

public struct BeatmapSongDifficulty {
    public let difficulty: BeatmapDifficulty
    public let notes: [BeatmapNoteEvent]

    public let noteCount: Int
    public let bombCount: Int
    public let wallCount = 0 // We're still not loading obstacles
    public let duration: TimeInterval
    public let notesPerSecond: Double

    init(difficulty: BeatmapDifficulty, notes: [BeatmapNoteEvent]) {
        self.difficulty = difficulty
        self.notes = notes

        self.bombCount = notes.filter({ $0.note.isBomb }).count
        self.noteCount = notes.count - bombCount

        // TODO: Update this once we're loading obstacles and other events as well
        // This should be the max(...) between all the different times (or use the song duration)
        self.duration = notes.map({ $0.time }).max() ?? 0.0
        self.notesPerSecond = (duration > 0.0) ? (Double(noteCount)/duration):0.0
    }
}

public struct BeatmapSong {
    public let preview: BeatmapPreview
    public let standardDifficulties: [BeatmapSongDifficulty]
}
