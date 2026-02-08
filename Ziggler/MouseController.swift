//
//  MouseController.swift
//  Ziggler
//
//  Created by Krashna Chaurasia on 07.02.26.
//

import SwiftUI
import Combine
import CoreGraphics
import Carbon
import AppKit

// Movement pattern types
enum MovementPattern: String, CaseIterable {
    case random = "Random"
    case circular = "Circular"
    case figure8 = "Figure 8"
    case natural = "Natural (Human-like)"
}

class MouseController: ObservableObject {
    @Published var isMoving = false
    @Published var selectedPattern: MovementPattern = .natural
    @Published var speed: Double = 50.0
    @Published var hasPermission = AXIsProcessTrusted()

    private var timer: Timer?
    private var delayTimer: Timer?
    private var eventMonitor: Any?
    private var workspaceObserver: Any?
    private var angle: Double = 0.0
    private var step: Int = 0
    private var moveCount: Int = 0
    private var permissionTimer: Timer?

    init() {
        setupKeyboardMonitor()
        startPermissionPolling()
        // Auto-prompt on launch if not yet granted
        if !hasPermission {
            requestAccessibilityPermission()
        }
    }

    // Poll permission status silently (no prompt)
    private func startPermissionPolling() {
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let current = AXIsProcessTrusted()
            if current != self.hasPermission {
                self.hasPermission = current
            }
        }
    }

    // Only prompt when user explicitly requests it
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let granted = AXIsProcessTrustedWithOptions(options)
        hasPermission = granted
    }

    deinit {
        stopMovement()
        permissionTimer?.invalidate()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let observer = workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    private func setupKeyboardMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self, self.isMoving else { return }
            self.stopMovement()
        }

        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self, self.isMoving else { return }
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
               app.bundleIdentifier != Bundle.main.bundleIdentifier {
                self.stopMovement()
            }
        }
    }

    func startMovement() {
        guard !isMoving else { return }

        angle = 0.0
        step = 0
        moveCount = 0
        isMoving = true

        delayTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.beginMovement()
        }
        if let t = delayTimer {
            RunLoop.main.add(t, forMode: .common)
        }
    }

    private func beginMovement() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.performMovement()
        }
        if let t = timer {
            RunLoop.main.add(t, forMode: .common)
        }
    }

    func stopMovement() {
        isMoving = false
        timer?.invalidate()
        timer = nil
        delayTimer?.invalidate()
        delayTimer = nil
        angle = 0.0
        step = 0
        moveCount = 0
    }

    private func performMovement() {
        moveCount += 1

        let cocoaLocation = NSEvent.mouseLocation
        guard let screenHeight = NSScreen.main?.frame.height else { return }
        let currentLocation = CGPoint(x: cocoaLocation.x, y: screenHeight - cocoaLocation.y)

        var newX = currentLocation.x
        var newY = currentLocation.y

        let moveDistance = CGFloat(speed / 100.0 * 10.0)

        switch selectedPattern {
        case .natural, .random:
            let randomAngle = CGFloat.random(in: 0...(2 * .pi))
            newX += cos(randomAngle) * moveDistance
            newY += sin(randomAngle) * moveDistance

        case .circular:
            angle += 0.1
            let radius = moveDistance * 3
            newX += cos(angle) * radius
            newY += sin(angle) * radius

        case .figure8:
            angle += 0.1
            newX += cos(angle) * moveDistance * 3
            newY += sin(2 * angle) * moveDistance * 3
        }

        if let screen = NSScreen.main {
            newX = max(10, min(newX, screen.frame.width - 10))
            newY = max(10, min(newY, screenHeight - 10))
        }

        moveMouse(to: CGPoint(x: newX, y: newY))
    }

    private func moveMouse(to point: CGPoint) {
        guard let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left) else {
            return
        }
        moveEvent.post(tap: .cghidEventTap)
    }
}
