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

    public func isContainedBy(_ range: ClosedRange<TimeInterval>) -> Bool {
        range.contains(time)
    }
}

public struct BeatmapObstacleEvent {
    public let time: TimeInterval
    public let duration: TimeInterval
    // TODO: Add other properties

    public func isContainedBy(_ range: ClosedRange<TimeInterval>) -> Bool {
        range.overlaps(time ... (time + max(0, duration)))
    }
}

public struct BeatmapSongDifficulty {
    public let name: String
    public let difficulty: BeatmapDifficulty
    public let notes: [BeatmapNoteEvent]
    public let obstacles: [BeatmapObstacleEvent]

    public let noteCount: Int
    public let bombCount: Int
    public let wallCount: Int

    init(
        name: String,
        difficulty: BeatmapDifficulty,
        notes: [BeatmapNoteEvent],
        obstacles: [BeatmapObstacleEvent]
    ) {
        self.name = name
        self.difficulty = difficulty
        self.notes = notes
        self.obstacles = obstacles

        self.bombCount = notes.filter({ $0.note.isBomb }).count
        self.noteCount = notes.count - bombCount
        self.wallCount = obstacles.count
    }

    public struct Slice {
        public let notes: [BeatmapNoteEvent]
        public let obstacles: [BeatmapObstacleEvent]
    }

    public func slice(for range: ClosedRange<TimeInterval>) -> Slice {
        // TODO: Replace this with a Range Search Tree
        .init(notes: notes.filter({ $0.isContainedBy(range) }), obstacles: obstacles.filter({ $0.isContainedBy(range) }))
    }
}

public struct BeatmapSong {
    public let preview: BeatmapPreview
    public let song: Data
    public let standardDifficulties: [BeatmapSongDifficulty]
}
