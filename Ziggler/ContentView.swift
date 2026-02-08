//
//  ContentView.swift
//  Ziggler
//
//  Created by Krashna Chaurasia on 07.02.26.
//

import KeyboardShortcuts
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var mouseController: MouseController
    @AppStorage("showMenuBarIcon") var showMenuBarIcon = true

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                HStack {
                    Circle()
                        .fill(mouseController.isMoving ? Color.green : Color.gray)
                        .frame(width: 10, height: 10)
                    Text(mouseController.isMoving ? "Active" : "Inactive")
                        .font(.headline)
                }

                if mouseController.hasPermission {
                    Label("Ready", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Label("Permission Required", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Movement Pattern")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("Pattern", selection: $mouseController.selectedPattern) {
                    ForEach(MovementPattern.allCases, id: \.self) { pattern in
                        Text(pattern.rawValue).tag(pattern)
                    }
                }
                .disabled(mouseController.isMoving)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Speed")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(mouseController.speed))%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Slider(value: $mouseController.speed, in: 10...100, step: 5)
                    .disabled(mouseController.isMoving)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            Divider()

            VStack(spacing: 6) {
                actionButton
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)

                Text("Auto-stops on any keypress")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            // MARK: - Settings

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Shortcut")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .toggleMovement)
                }

                Toggle("Launch at Login", isOn: Binding(
                    get: { mouseController.launchAtLogin },
                    set: { mouseController.setLaunchAtLogin($0) }
                ))
                .font(.subheadline)

                Toggle("Show Menu Bar Icon", isOn: $showMenuBarIcon)
                    .font(.subheadline)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            Divider()

            Button("Quit Ziggler") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)
        }
        .frame(width: 280)
    }

    @ViewBuilder
    private var actionButton: some View {
        if mouseController.isMoving {
            Button(action: { mouseController.stopMovement() }) {
                Text("Stop Movement")
                    .frame(maxWidth: .infinity)
            }
            .tint(.red)
        } else if mouseController.hasPermission {
            Button(action: { mouseController.startMovement() }) {
                Text("Start Movement")
                    .frame(maxWidth: .infinity)
            }
        } else {
            Button(action: { mouseController.requestAccessibilityPermission() }) {
                Label("Grant Permission First", systemImage: "exclamationmark.triangle.fill")
                    .frame(maxWidth: .infinity)
            }
            .tint(.orange)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MouseController())
}
