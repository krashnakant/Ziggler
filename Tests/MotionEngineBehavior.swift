import CoreGraphics
import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

private func testCircularMotionStaysWithinBounds() {
    let bounds = CGRect(x: 0, y: 0, width: 200, height: 200)
    var state = MotionState()
    var point = CGPoint(x: 100, y: 100)

    for _ in 0..<240 {
        point = MotionEngine.nextPoint(
            from: point,
            pattern: .circular,
            speed: 50,
            bounds: bounds,
            deltaTime: 1.0 / 60.0,
            state: &state
        )
        expect(bounds.contains(point), "Circular pattern escaped bounds at \(point)")
    }
}

private func testRandomAndFigure8StayWithinBounds() {
    let bounds = CGRect(x: -120, y: 20, width: 420, height: 260)

    for pattern in [MovementPattern.random, .figure8] {
        var state = MotionState()
        var point = CGPoint(x: bounds.midX, y: bounds.midY)

        for _ in 0..<300 {
            point = MotionEngine.nextPoint(
                from: point,
                pattern: pattern,
                speed: 60,
                bounds: bounds,
                deltaTime: 1.0 / 60.0,
                state: &state
            )
            expect(bounds.contains(point), "\(pattern.rawValue) escaped bounds at \(point)")
        }
    }
}

@main
struct MotionEngineBehaviorRunner {
    static func main() {
        testCircularMotionStaysWithinBounds()
        testRandomAndFigure8StayWithinBounds()
        print("MotionEngineBehavior passed")
    }
}
