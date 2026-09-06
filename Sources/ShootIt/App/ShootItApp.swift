import AppKit
import SwiftUI

@main
struct ShootItApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel.shared

    var body: some Scene {
        MenuBarExtra("Shoot It", systemImage: "camera.viewfinder") {
            Group {
                Button("Bereich aufnehmen") {
                    model.takeScreenshot()
                }
                .keyboardShortcut("1")

                Button("Ideen öffnen") {
                    model.openIdeasGallery()
                }

                Divider()
                SettingsLink { Text("Einstellungen …") }
                Divider()
                Button("Shoot It beenden") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            }
            .onAppear { model.start() }
        }
        .menuBarExtraStyle(.menu)

        Settings {
            PreferencesView(preferences: model.preferences)
        }
        .defaultSize(width: 520, height: 360)
    }

}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AppModel.shared.start()
    }
}
