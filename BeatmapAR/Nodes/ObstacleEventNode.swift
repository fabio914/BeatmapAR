import SceneKit
import BeatmapLoader

final class ObstacleEventNode: SCNNode {
    let obstacleEvent: BeatmapObstacleEvent

    init(obstacleEvent: BeatmapObstacleEvent, distancePerSecond: Double, child: SCNNode?) {
        self.obstacleEvent = obstacleEvent
        super.init()

        let width = Double(obstacleEvent.width) * 0.25

        let row: Double = {
            switch obstacleEvent.direction {
            case .vertical:
                return 0.375
            case .horizontal:
                return 0.5
            }
        }()

        let length: Double = obstacleEvent.duration * distancePerSecond

        let height: Double = {
            switch obstacleEvent.direction {
            case .vertical:
                return 1.0
            case .horizontal:
                return 0.5
            }
        }()

        self.position = .init(
            Double(obstacleEvent.column.rawValue) * 0.25 + (width - 0.25)/2.0,
            row,
            -(obstacleEvent.time * distancePerSecond) - length/2.0
        )

        if let child = child {
            child.position = .init()
            child.scale = .init(width, height, length)
            self.addChildNode(child)
        }

        let frontBottomLeft = SCNVector3(-width/2.0, -height/2.0, length/2.0)
        let frontBottomRight = SCNVector3(width/2.0, -height/2.0, length/2.0)
        let frontTopLeft = SCNVector3(-width/2.0, height/2.0, length/2.0)
        let frontTopRight = SCNVector3(width/2.0, height/2.0, length/2.0)

        let backBottomLeft = SCNVector3(-width/2.0, -height/2.0, -length/2.0)
        let backBottomRight = SCNVector3(width/2.0, -height/2.0, -length/2.0)
        let backTopLeft = SCNVector3(-width/2.0, height/2.0, -length/2.0)
        let backTopRight = SCNVector3(width/2.0, height/2.0, -length/2.0)

        self.addChildNode(makeLine(from: frontBottomLeft, to: frontBottomRight))
        self.addChildNode(makeLine(from: frontBottomRight, to: frontTopRight))
        self.addChildNode(makeLine(from: frontTopRight, to: frontTopLeft))
        self.addChildNode(makeLine(from: frontTopLeft, to: frontBottomLeft))

        self.addChildNode(makeLine(from: backBottomLeft, to: backBottomRight))
        self.addChildNode(makeLine(from: backBottomRight, to: backTopRight))
        self.addChildNode(makeLine(from: backTopRight, to: backTopLeft))
        self.addChildNode(makeLine(from: backTopLeft, to: backBottomLeft))

        self.addChildNode(makeLine(from: frontBottomLeft, to: backBottomLeft))
        self.addChildNode(makeLine(from: frontBottomRight, to: backBottomRight))
        self.addChildNode(makeLine(from: frontTopRight, to: backTopRight))
        self.addChildNode(makeLine(from: frontTopLeft, to: backTopLeft))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeLine(from positionA: SCNVector3, to positionB: SCNVector3) -> SCNNode {

        let radius: Float = 0.005
        let vector = SCNVector3(positionA.x - positionB.x, positionA.y - positionB.y, positionA.z - positionB.z)
        let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)

        let midPosition = SCNVector3(
            (positionA.x + positionB.x)/2.0,
            (positionA.y + positionB.y)/2.0,
            (positionA.z + positionB.z)/2.0
        )

        let lineGeometry = SCNCylinder()
        lineGeometry.radius = CGFloat(radius)
        lineGeometry.height = CGFloat(distance + 2.0 * radius)
        lineGeometry.radialSegmentCount = 5

        lineGeometry.firstMaterial?.lightingModel = .constant
        lineGeometry.firstMaterial?.diffuse.contents = UIColor.white

        let lineNode = SCNNode(geometry: lineGeometry)
        lineNode.position = midPosition
        lineNode.look(at: positionB, up: .init(0, 1, 0), localFront: lineNode.worldUp)
        return lineNode
    }
}
