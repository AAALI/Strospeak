import AppKit
import SwiftUI

@main
struct StroSpeakApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("show_menu_bar_icon") private var showMenuBarIcon = true

    init() {
        Analytics.configurePostHog()
    }

    var body: some Scene {
        MenuBarExtra(isInserted: $showMenuBarIcon) {
            MenuBarView()
                .environmentObject(appDelegate.appState)
        } label: {
            MenuBarLabel()
                .environmentObject(appDelegate.appState)
        }
    }
}

private struct MenuBarLabel: View {
    @EnvironmentObject var appState: AppState

    private var iconName: String {
        if appState.isRecording { return "record.circle" }
        if appState.isTranscribing { return "ellipsis.circle" }
        return "waveform"
    }

    var body: some View {
        Image(systemName: iconName)
    }
}
