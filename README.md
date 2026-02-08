# Ziggler

A lightweight macOS menu bar app that keeps your mouse cursor moving to prevent idle/sleep detection.

## Features

- **Menu bar app** — lives in your menu bar, no dock icon clutter
- **Multiple movement patterns** — Random, Circular, Figure 8, Natural (Human-like)
- **Adjustable speed** — slider from 10% to 100%
- **Smart auto-stop** — stops on Cmd+Tab (app switch) or any keypress
- **3-second delay** — gives you time to switch windows before movement starts
- **Accessibility permission handling** — auto-prompts on launch, auto-resets on dev rebuilds

## Requirements

- macOS 15.0+
- Xcode 26+
- Accessibility permission (prompted on first launch)

## Getting Started

1. Open `Ziggler.xcodeproj` in Xcode
2. Build and Run (Cmd+R)
3. Grant Accessibility permission when prompted
4. Click the cursor icon in the menu bar to control movement

## Development Notes

- App Sandbox is disabled (required for `CGEvent` and `AXIsProcessTrusted`)
- A pre-build script auto-resets TCC permissions in Debug builds so you don't need to manually re-grant after each rebuild
