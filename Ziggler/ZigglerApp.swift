//
//  ZigglerApp.swift
//  Ziggler
//
//  Created by Krashna Chaurasia on 07.02.26.
//

import MenuBarExtraAccess
import SwiftUI

@main
struct ZigglerApp: App {
    @StateObject private var mouseController = MouseController()
    @AppStorage("showMenuBarIcon") var showMenuBarIcon = true

    var body: some Scene {
        MenuBarExtra("Ziggler", systemImage: "cursorarrow.motionlines") {
            ContentView()
                .environmentObject(mouseController)
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $showMenuBarIcon)
    }
}
