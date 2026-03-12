import Foundation

enum MotionScheduling {
    static func updateInterval(for speed: Double) -> TimeInterval {
        switch speed {
        case ..<35:
            return 1.0 / 36.0
        case ..<70:
            return 1.0 / 48.0
        default:
            return 1.0 / 60.0
        }
    }
}
