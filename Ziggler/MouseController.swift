//
//  MouseController.swift
//  Ziggler
//
//  Created by Krashna Chaurasia on 07.02.26.
//

import AppKit
import Combine
import KeyboardShortcuts
import ServiceManagement

extension KeyboardShortcuts.Name {
    static let toggleMovement = Self("toggleMovement")
}

class MouseController: ObservableObject {
    @Published var isMoving = false
    @Published var selectedPattern: MovementPattern = .random
    @Published var speed: Double = 50.0
    @Published var hasPermission = AXIsProcessTrusted()
    @Published var launchAtLogin = false

    private var movementTimer: DispatchSourceTimer?
    private var delayedStartWorkItem: DispatchWorkItem?
    private var eventMonitor: Any?
    private var permissionTimer: DispatchSourceTimer?
    private var motionState = MotionState()
    private var lastMovementTimestamp: CFTimeInterval?
    private var lastResolvedScreen: NSScreen?

    init() {
        setupKeyboardMonitor()
        setupGlobalShortcut()
        refreshLoginItemStatus()
        if !hasPermission {
            requestAccessibilityPermission()
            startPermissionPolling()
        }
    }

    deinit {
        stopMovement()
        permissionTimer?.cancel()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Launch at Login

    func refreshLoginItemStatus() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = enabled
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
            refreshLoginItemStatus()
        }
    }

    // MARK: - Global Shortcut

    private func setupGlobalShortcut() {
        KeyboardShortcuts.onKeyUp(for: .toggleMovement) { [weak self] in
            self?.toggleMovement()
        }
    }

    func toggleMovement() {
        if isMoving {
            stopMovement()
        } else {
            startMovement()
        }
    }

    // MARK: - Permissions

    private func startPermissionPolling() {
        guard permissionTimer == nil else { return }

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 5.0, repeating: 5.0, leeway: .seconds(1))
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            self.handlePermissionStatusChange(AXIsProcessTrusted())
        }
        permissionTimer = timer
        timer.resume()
    }

    private func stopPermissionPolling() {
        permissionTimer?.cancel()
        permissionTimer = nil
    }

    private func handlePermissionStatusChange(_ granted: Bool) {
        if granted && !hasPermission {
            setupKeyboardMonitor()
        }

        hasPermission = granted

        if granted {
            stopPermissionPolling()
        } else if permissionTimer == nil {
            startPermissionPolling()
        }
    }

    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        handlePermissionStatusChange(AXIsProcessTrustedWithOptions(options))
    }

    // MARK: - Keyboard Monitor

    private func setupKeyboardMonitor() {
        if let existing = eventMonitor {
            NSEvent.removeMonitor(existing)
            eventMonitor = nil
        }
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] _ in
            guard let self, self.isMoving else { return }
            self.stopMovement()
        }
    }

    // MARK: - Movement

    func startMovement() {
        guard !isMoving else { return }

        motionState = MotionState()
        lastMovementTimestamp = nil
        lastResolvedScreen = nil
        isMoving = true

        let workItem = DispatchWorkItem { [weak self] in
            self?.beginMovement()
        }
        delayedStartWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: workItem)
    }

    private func beginMovement() {
        movementTimer?.cancel()
        lastMovementTimestamp = CACurrentMediaTime()
        let interval = MotionScheduling.updateInterval(for: speed)

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(2))
        timer.setEventHandler { [weak self] in
            self?.performMovement()
        }
        movementTimer = timer
        timer.resume()
    }

    func stopMovement() {
        isMoving = false
        movementTimer?.cancel()
        movementTimer = nil
        delayedStartWorkItem?.cancel()
        delayedStartWorkItem = nil
        motionState = MotionState()
        lastMovementTimestamp = nil
        lastResolvedScreen = nil
    }

    private func performMovement() {
        let currentLocation = NSEvent.mouseLocation
        guard let screen = activeScreen(containing: currentLocation) else { return }

        let now = CACurrentMediaTime()
        let previousTimestamp = lastMovementTimestamp ?? now
        let deltaTime = max(1.0 / 240.0, min(now - previousTimestamp, 1.0 / 20.0))
        lastMovementTimestamp = now

        let nextLocation = MotionEngine.nextPoint(
            from: currentLocation,
            pattern: selectedPattern,
            speed: speed,
            bounds: screen.frame,
            deltaTime: deltaTime,
            state: &motionState
        )

        guard let moveEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: nextLocation,
            mouseButton: .left
        ) else { return }
        moveEvent.post(tap: .cghidEventTap)
    }

    private func activeScreen(containing point: CGPoint) -> NSScreen? {
        if let lastResolvedScreen, lastResolvedScreen.frame.contains(point) {
            return lastResolvedScreen
        }

        if let exactMatch = NSScreen.screens.first(where: { $0.frame.contains(point) }) {
            lastResolvedScreen = exactMatch
            return exactMatch
        }

        let nearestScreen = NSScreen.screens.min { lhs, rhs in
            distanceSquared(from: point, to: lhs.frame) < distanceSquared(from: point, to: rhs.frame)
        }
        lastResolvedScreen = nearestScreen
        return nearestScreen
    }

    private func distanceSquared(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let dx: CGFloat
        if point.x < rect.minX {
            dx = rect.minX - point.x
        } else if point.x > rect.maxX {
            dx = point.x - rect.maxX
        } else {
            dx = 0
        }

        let dy: CGFloat
        if point.y < rect.minY {
            dy = rect.minY - point.y
        } else if point.y > rect.maxY {
            dy = point.y - rect.maxY
        } else {
            dy = 0
        }

        return dx * dx + dy * dy
    }
}
