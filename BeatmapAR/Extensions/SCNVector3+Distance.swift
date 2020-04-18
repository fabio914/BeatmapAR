import SceneKit

extension SCNVector3 {

    var distanceSquared: Float {
        x * x + y * y + z * z
    }

    static func - (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        .init(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }
}
