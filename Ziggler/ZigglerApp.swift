//
//  ZigglerApp.swift
//  Ziggler
//
//  Created by Krashna Chaurasia on 07.02.26.
//

import SwiftUI

@main
struct ZigglerApp: App {
    @StateObject private var mouseController = MouseController()

    var body: some Scene {
        MenuBarExtra("Ziggler", systemImage: "cursorarrow.motionlines") {
            ContentView()
                .environmentObject(mouseController)
        }
        .menuBarExtraStyle(.window)
    }
}
