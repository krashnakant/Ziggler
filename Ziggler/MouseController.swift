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

enum MovementPattern: String, CaseIterable {
    case random = "Random"
    case circular = "Circular"
    case figure8 = "Figure 8"
}

class MouseController: ObservableObject {
    @Published var isMoving = false
    @Published var selectedPattern: MovementPattern = .random
    @Published var speed: Double = 50.0
    @Published var hasPermission = AXIsProcessTrusted()
    @Published var launchAtLogin = false

    private var timer: Timer?
    private var delayTimer: Timer?
    private var eventMonitor: Any?
    private var permissionTimer: Timer?
    private var angle: Double = 0.0

    init() {
        setupKeyboardMonitor()
        setupGlobalShortcut()
        startPermissionPolling()
        refreshLoginItemStatus()
        if !hasPermission {
            requestAccessibilityPermission()
        }
    }

    deinit {
        stopMovement()
        permissionTimer?.invalidate()
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
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.hasPermission = AXIsProcessTrusted()
        }
    }

    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        hasPermission = AXIsProcessTrustedWithOptions(options)
    }

    // MARK: - Keyboard Monitor

    private func setupKeyboardMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] _ in
            guard let self, self.isMoving else { return }
            self.stopMovement()
        }
    }

    // MARK: - Movement

    func startMovement() {
        guard !isMoving else { return }

        angle = 0.0
        isMoving = true

        delayTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.beginMovement()
        }
    }

    private func beginMovement() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.performMovement()
        }
    }

    func stopMovement() {
        isMoving = false
        timer?.invalidate()
        timer = nil
        delayTimer?.invalidate()
        delayTimer = nil
        angle = 0.0
    }

    private func performMovement() {
        let cocoaLocation = NSEvent.mouseLocation
        guard let screen = NSScreen.main else { return }
        let screenHeight = screen.frame.height
        let currentX = cocoaLocation.x
        let currentY = screenHeight - cocoaLocation.y

        let moveDistance = CGFloat(speed / 10.0)
        var newX = currentX
        var newY = currentY

        switch selectedPattern {
        case .random:
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

        newX = max(10, min(newX, screen.frame.width - 10))
        newY = max(10, min(newY, screenHeight - 10))

        guard let moveEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: CGPoint(x: newX, y: newY),
            mouseButton: .left
        ) else { return }
        moveEvent.post(tap: .cghidEventTap)
    }
}
