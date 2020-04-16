import Foundation

extension TimeInterval {

    var formatted: String {
        let totalSeconds = Int(floor(self))
        let seconds = totalSeconds % 60
        let minutes = (totalSeconds/60) % 60
        return .init(format: "%d:%2d", minutes, seconds)
    }
}
