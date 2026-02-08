//
//  ContentView.swift
//  Ziggler
//
//  Created by Krashna Chaurasia on 07.02.26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var mouseController: MouseController

    var body: some View {
        VStack(spacing: 0) {
            // Status
            VStack(spacing: 8) {
                HStack {
                    Circle()
                        .fill(mouseController.isMoving ? Color.green : Color.gray)
                        .frame(width: 10, height: 10)
                    Text(mouseController.isMoving ? "Active" : "Inactive")
                        .font(.headline)
                }

                if !mouseController.hasPermission {
                    Label("Permission Required", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Label("Ready", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            .padding()

            Divider()

            // Movement Pattern
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

            // Speed Slider
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

            // Action Button
            VStack(spacing: 6) {
                if mouseController.isMoving {
                    Button(action: { mouseController.stopMovement() }) {
                        Text("Stop Movement")
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .tint(.red)

                    Text("Starts in 3 seconds...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if mouseController.hasPermission {
                    Button(action: { mouseController.startMovement() }) {
                        Text("Start Movement")
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: { mouseController.requestAccessibilityPermission() }) {
                        Label("Grant Permission First", systemImage: "exclamationmark.triangle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }

                Text("Auto-stops on Cmd+Tab or any keypress")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            // Quit
            Button("Quit Ziggler") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)
        }
        .frame(width: 280)
    }
}

#Preview {
    ContentView()
        .environmentObject(MouseController())
}
