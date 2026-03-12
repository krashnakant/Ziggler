import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

@main
struct MotionSchedulingBehaviorRunner {
    static func main() {
        let slow = MotionScheduling.updateInterval(for: 10)
        let medium = MotionScheduling.updateInterval(for: 50)
        let fast = MotionScheduling.updateInterval(for: 100)

        expect(slow > medium, "Slow speed should use a lower update frequency")
        expect(medium > fast, "Medium speed should use a lower update frequency than fast speed")
        expect(fast == 1.0 / 60.0, "Fast speed should stay at 60 Hz")

        print("MotionSchedulingBehavior passed")
    }
}
