import CoreGraphics
import Foundation

enum MovementPattern: String, CaseIterable {
    case random = "Random"
    case circular = "Circular"
    case figure8 = "Figure 8"
}

struct MotionState {
    var anchor: CGPoint?
    var angle: CGFloat = 0
    var velocity: CGVector = .zero
    var heading: CGFloat = 0
    var targetHeading: CGFloat = 0
    var currentSpeed: CGFloat = 0
    var targetSpeed: CGFloat = 0
    var retargetFramesRemaining: Int = 0
}

enum MotionEngine {
    static func nextPoint(
        from currentPoint: CGPoint,
        pattern: MovementPattern,
        speed: Double,
        bounds: CGRect,
        deltaTime: Double,
        state: inout MotionState
    ) -> CGPoint {
        let padding = max(8.0, CGFloat(speed) * 0.08)
        let safeBounds = bounds.insetBy(dx: padding, dy: padding)
        guard safeBounds.width > 0, safeBounds.height > 0 else {
            return clamp(currentPoint, to: bounds)
        }

        let effectiveDelta = max(CGFloat(deltaTime), 1.0 / 120.0)
        let baseSpeed = max(16.0, CGFloat(speed) * 0.9)

        let unclampedPoint: CGPoint
        switch pattern {
        case .random:
            unclampedPoint = nextRandomPoint(
                from: currentPoint,
                baseSpeed: baseSpeed,
                bounds: safeBounds,
                deltaTime: effectiveDelta,
                state: &state
            )
        case .circular:
            unclampedPoint = nextCircularPoint(
                from: currentPoint,
                baseSpeed: baseSpeed,
                bounds: safeBounds,
                deltaTime: effectiveDelta,
                state: &state
            )
        case .figure8:
            unclampedPoint = nextFigure8Point(
                from: currentPoint,
                baseSpeed: baseSpeed,
                bounds: safeBounds,
                deltaTime: effectiveDelta,
                state: &state
            )
        }

        let clampedPoint = clamp(unclampedPoint, to: safeBounds)
        if clampedPoint != unclampedPoint {
            if unclampedPoint.x != clampedPoint.x {
                state.velocity.dx *= -0.8
            }
            if unclampedPoint.y != clampedPoint.y {
                state.velocity.dy *= -0.8
            }
            state.anchor = clamp(state.anchor ?? currentPoint, to: safeBounds)
            state.heading = atan2(state.velocity.dy, state.velocity.dx)
            state.targetHeading = state.heading
            state.retargetFramesRemaining = 0
        }

        return clampedPoint
    }

    private static func nextRandomPoint(
        from currentPoint: CGPoint,
        baseSpeed: CGFloat,
        bounds: CGRect,
        deltaTime: CGFloat,
        state: inout MotionState
    ) -> CGPoint {
        if state.retargetFramesRemaining <= 0 {
            let randomHeading = CGFloat.random(in: 0...(2 * .pi))
            let randomSpeed = baseSpeed * CGFloat.random(in: 0.5...1.15)
            state.targetHeading = randomHeading
            state.targetSpeed = randomSpeed
            state.retargetFramesRemaining = Int.random(in: 10...28)
        } else {
            state.retargetFramesRemaining -= 1
        }

        state.heading = interpolateAngle(from: state.heading, to: state.targetHeading, factor: 0.18)
        state.currentSpeed += (state.targetSpeed - state.currentSpeed) * 0.16

        let desiredVelocity = CGVector(
            dx: cos(state.heading) * state.currentSpeed,
            dy: sin(state.heading) * state.currentSpeed
        )

        state.velocity.dx += (desiredVelocity.dx - state.velocity.dx) * 0.25
        state.velocity.dy += (desiredVelocity.dy - state.velocity.dy) * 0.25

        return CGPoint(
            x: currentPoint.x + state.velocity.dx * deltaTime,
            y: currentPoint.y + state.velocity.dy * deltaTime
        )
    }

    private static func nextCircularPoint(
        from currentPoint: CGPoint,
        baseSpeed: CGFloat,
        bounds: CGRect,
        deltaTime: CGFloat,
        state: inout MotionState
    ) -> CGPoint {
        let radius = min(bounds.width, bounds.height) * 0.16
        let constrainedAnchorBounds = bounds.insetBy(dx: radius, dy: radius)
        if state.anchor == nil {
            state.anchor = clamp(currentPoint, to: constrainedAnchorBounds)
        } else {
            state.anchor = clamp(state.anchor ?? currentPoint, to: constrainedAnchorBounds)
        }

        state.angle += deltaTime * max(0.9, baseSpeed / 20.0)
        let anchor = state.anchor ?? currentPoint
        return CGPoint(
            x: anchor.x + cos(state.angle) * radius,
            y: anchor.y + sin(state.angle) * radius
        )
    }

    private static func nextFigure8Point(
        from currentPoint: CGPoint,
        baseSpeed: CGFloat,
        bounds: CGRect,
        deltaTime: CGFloat,
        state: inout MotionState
    ) -> CGPoint {
        let horizontalRadius = bounds.width * 0.14
        let verticalRadius = bounds.height * 0.1
        let constrainedAnchorBounds = bounds.insetBy(dx: horizontalRadius, dy: verticalRadius)
        if state.anchor == nil {
            state.anchor = clamp(currentPoint, to: constrainedAnchorBounds)
        } else {
            state.anchor = clamp(state.anchor ?? currentPoint, to: constrainedAnchorBounds)
        }

        state.angle += deltaTime * max(1.0, baseSpeed / 18.0)
        let anchor = state.anchor ?? currentPoint
        return CGPoint(
            x: anchor.x + cos(state.angle) * horizontalRadius,
            y: anchor.y + sin(state.angle * 2.0) * verticalRadius
        )
    }

    private static func clamp(_ point: CGPoint, to rect: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(point.x, rect.minX), rect.maxX),
            y: min(max(point.y, rect.minY), rect.maxY)
        )
    }

    private static func normalizeAngle(_ angle: CGFloat) -> CGFloat {
        var normalized = angle
        while normalized > .pi {
            normalized -= 2 * .pi
        }
        while normalized < -.pi {
            normalized += 2 * .pi
        }
        return normalized
    }

    private static func interpolateAngle(from current: CGFloat, to target: CGFloat, factor: CGFloat) -> CGFloat {
        let delta = normalizeAngle(target - current)
        return normalizeAngle(current + delta * factor)
    }
}
