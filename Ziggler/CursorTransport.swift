import CoreGraphics

enum CursorTransport: Equatable {
    case warpCursorPosition

    static let transportForContinuousMotion: CursorTransport = .warpCursorPosition

    func moveCursor(to point: CGPoint) {
        switch self {
        case .warpCursorPosition:
            let source = CGEventSource(stateID: .hidSystemState)
            if let event = CGEvent(mouseEventSource: source, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left) {
                event.post(tap: .cghidEventTap)
            } else {
                CGAssociateMouseAndMouseCursorPosition(0)
                CGWarpMouseCursorPosition(point)
                CGAssociateMouseAndMouseCursorPosition(1)
            }
        }
    }
}
