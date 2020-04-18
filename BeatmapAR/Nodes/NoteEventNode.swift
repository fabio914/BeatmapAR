import SceneKit
import BeatmapLoader

final class NoteEventNode: SCNNode {
    let noteEvent: BeatmapNoteEvent

    init(noteEvent: BeatmapNoteEvent, distancePerSecond: Double, child: SCNNode?) {
        self.noteEvent = noteEvent
        super.init()

        if let child = child {
            child.position = .init()
            self.addChildNode(child)
        }

        let direction: BeatmapDirection? = {
            switch noteEvent.note {
            case .blueBlock(let direction):
                return direction
            case .redBlock(let direction):
                return direction
            default:
                return nil
            }
        }()

        let coordinates = noteEvent.coordinates
        let noteTime = noteEvent.time

        self.position = .init(
            Double(coordinates.column.rawValue) * 0.25,
            Double(coordinates.row.rawValue) * 0.25,
            -(noteTime * distancePerSecond)
        )

        let rotation = (direction?.angle ?? 0.0) * .pi/180.0
        self.eulerAngles.z = rotation
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
