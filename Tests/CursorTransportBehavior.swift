import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

@main
struct CursorTransportBehaviorRunner {
    static func main() {
        expect(
            CursorTransport.transportForContinuousMotion == .warpCursorPosition,
            "Continuous cursor motion should avoid posting synthetic mouse move events"
        )

        print("CursorTransportBehavior passed")
    }
}
