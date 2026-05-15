import SwiftUI
import AVFoundation
import Foundation
import ServiceManagement

struct SetupView: View {
    var onComplete: () -> Void
    @EnvironmentObject var appState: AppState
    private enum SetupStep: Int, CaseIterable {
        case welcome = 0
        case account
        case micPermission
        case accessibility
        case screenRecording
        case holdShortcut
        case toggleShortcut
        case commandMode
        case vocabulary
        case launchAtLogin
        case ready
    }

    @State private var currentStep = SetupStep.welcome
    @State private var micPermissionGranted = false
    @State private var accessibilityGranted = false
    @State private var accessibilityTimer: Timer?
    @State private var screenRecordingTimer: Timer?
    @State private var customVocabularyInput: String = ""
    @State private var holdShortcutValidationMessage: String?
    @State private var toggleShortcutValidationMessage: String?
    @State private var isCapturingHoldShortcut = false
    @State private var isCapturingToggleShortcut = false

    private let totalSteps: [SetupStep] = SetupStep.allCases
    private var isCapturingShortcut: Bool {
        isCapturingHoldShortcut || isCapturingToggleShortcut
    }

    var body: some View {
        VStack(spacing: 0) {
            currentStepView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 40)
                .padding(.vertical, 32)

            Divider()

            ZStack {
                stepIndicator

                HStack(alignment: .center) {
                    Group {
                        if currentStep != .welcome {
                            Button("Back") {
                                withAnimation {
                                    currentStep = previousStep(currentStep)
                                }
                            }
                        }
                    }

                    Spacer()

                    Group {
                        if currentStep != .ready {
                            if currentStep == .vocabulary {
                                Button("Continue") {
                                    saveCustomVocabularyAndContinue()
                                }
                                .keyboardShortcut(.defaultAction)
                            } else {
                                Button("Continue") {
                                    withAnimation {
                                        currentStep = nextStep(currentStep)
                                    }
                                }
                                .keyboardShortcut(.defaultAction)
                                .disabled(!canContinueFromCurrentStep)
                            }
                        } else {
                            Button("Get Started") {
                                onComplete()
                            }
                            .keyboardShortcut(.defaultAction)
                        }
                    }
                }
            }
            .padding(20)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 520, height: 680)
        .onAppear {
            customVocabularyInput = appState.customVocabulary
            checkMicPermission()
            checkAccessibility()
        }
        .onDisappear {
            accessibilityTimer?.invalidate()
            screenRecordingTimer?.invalidate()
            appState.resumeHotkeyMonitoringAfterShortcutCapture()
        }
        .onChange(of: isCapturingShortcut) { isCapturing in
            if isCapturing {
                appState.suspendHotkeyMonitoringForShortcutCapture()
            } else {
                appState.resumeHotkeyMonitoringAfterShortcutCapture()
            }
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case .welcome:
            welcomeStep
        case .account:
            accountStep
        case .micPermission:
            micPermissionStep
        case .accessibility:
            accessibilityStep
        case .screenRecording:
            screenRecordingStep
        case .holdShortcut:
            holdShortcutStep
        case .toggleShortcut:
            toggleShortcutStep
        case .commandMode:
            commandModeStep
        case .vocabulary:
            vocabularyStep
        case .launchAtLogin:
            launchAtLoginStep
        case .ready:
            readyStep
        }
    }

    // MARK: - Steps

    var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 128, height: 128)

            VStack(spacing: 6) {
                Text("Welcome to \(AppName.displayName)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                Text("Dictate text anywhere on your Mac.\nHold to talk or tap to toggle dictation.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                Label("Works anywhere you type", systemImage: "keyboard")
                Label("Adapts text to the app you're using", systemImage: "sparkles")
                Label("Keeps your shortcuts and vocabulary under your control", systemImage: "slider.horizontal.3")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.top, 4)

        }
    }

    var accountStep: some View {
        VStack {
            Spacer(minLength: 0)

            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Account")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Your subscription and usage will be managed through your \(AppName.displayName) account.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: appState.isSignedIn ? "checkmark.circle.fill" : "person.crop.circle.badge.exclamationmark")
                            .foregroundStyle(appState.isSignedIn ? .green : .secondary)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(appState.isSignedIn ? "Signed in" : "Sign-in unavailable in this build")
                                .font(.headline)
                            Text(appState.isSignedIn && !appState.accountEmail.isEmpty
                                 ? appState.accountEmail
                                 : "Continue setup now. Connect the hosted account flow before public launch.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(10)
            }
            .frame(maxWidth: 440)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var micPermissionStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Microphone Access")
                .font(.title)
                .fontWeight(.bold)

            Text("\(AppName.displayName) needs access to your microphone to record audio for transcription.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Image(systemName: "mic.fill")
                    .frame(width: 24)
                    .foregroundStyle(.blue)
                Text("Microphone")
                Spacer()
                if micPermissionGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Granted")
                        .foregroundStyle(.green)
                } else {
                    Button("Grant Access") {
                        requestMicPermission()
                    }
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

        }
    }

    var accessibilityStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Accessibility Access")
                .font(.title)
                .fontWeight(.bold)

            Text("\(AppName.displayName) needs Accessibility access to paste transcribed text into your apps.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Image(systemName: "hand.raised.fill")
                    .frame(width: 24)
                    .foregroundStyle(.blue)
                Text("Accessibility")
                Spacer()
                if accessibilityGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Granted")
                        .foregroundStyle(.green)
                } else {
                    Button("Open Settings") {
                        requestAccessibility()
                    }
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

        }
        .onAppear {
            startAccessibilityPolling()
        }
        .onDisappear {
            accessibilityTimer?.invalidate()
        }
    }

    var screenRecordingStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Screen Recording")
                .font(.title)
                .fontWeight(.bold)

            Text("\(AppName.displayName) intelligently adapts the transcription to the current app you're working in (ex. spelling names in an email correctly).")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("It needs this permission to see which app you're working in and adapt wording, names, and formatting. Commercial builds should process usage through the hosted \(AppName.displayName) service.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Image(systemName: "camera.viewfinder")
                    .frame(width: 24)
                    .foregroundStyle(.blue)
                Text("Screen Recording")
                Spacer()
                if appState.hasScreenRecordingPermission {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Granted")
                        .foregroundStyle(.green)
                } else {
                    Button("Grant Access") {
                        appState.requestScreenCapturePermission()
                    }
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

        }
        .onAppear {
            startScreenRecordingPolling()
        }
        .onDisappear {
            screenRecordingTimer?.invalidate()
        }
    }

    var holdShortcutStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "keyboard.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Hold to Talk Shortcut")
                .font(.title)
                .fontWeight(.bold)

            Text("Choose the shortcut you want to hold while speaking.\nRelease it to stop unless you latch into tap mode later, or disable hold-to-talk entirely.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ShortcutRoleSection(
                role: .hold,
                selection: appState.holdShortcut,
                validationMessage: holdShortcutValidationMessage,
                isCapturing: $isCapturingHoldShortcut,
                onSelect: { binding in
                    holdShortcutValidationMessage = appState.setShortcut(binding, for: .hold)
                }
            )
                .padding(.top, 10)

            if appState.holdShortcut.usesFnKey {
                Text("Tip: If Fn opens Emoji picker, go to System Settings > Keyboard and change \"Press fn key to\" to \"Do Nothing\".")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }

        }
    }

    var toggleShortcutStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "switch.2")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Tap to Toggle Shortcut")
                .font(.title)
                .fontWeight(.bold)

            Text("Choose the shortcut you want to tap once to start dictating and tap again to stop.\nIf this shortcut becomes active while you are holding the hold shortcut, \(AppName.displayName) latches into tap mode. You can also disable tap-to-toggle entirely.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ShortcutRoleSection(
                role: .toggle,
                selection: appState.toggleShortcut,
                validationMessage: toggleShortcutValidationMessage,
                isCapturing: $isCapturingToggleShortcut,
                onSelect: { binding in
                    toggleShortcutValidationMessage = appState.setShortcut(binding, for: .toggle)
                }
            )
                .padding(.top, 10)

            if appState.toggleShortcut.usesFnKey {
                Text("Tip: If Fn opens Emoji picker, go to System Settings > Keyboard and change \"Press fn key to\" to \"Do Nothing\".")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }

        }
    }

    var vocabularyStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.book.closed.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Custom Vocabulary")
                .font(.title)
                .fontWeight(.bold)

            Text("Add names, product terms, and phrases \(AppName.displayName) should spell correctly.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Text("Vocabulary")
                    .font(.headline)

                TextEditor(text: $customVocabularyInput)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 130)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )

                Text("Separate entries with commas, new lines, or semicolons.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        }
    }

    var commandModeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "pencil")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Edit Mode")
                .font(.title)
                .fontWeight(.bold)

            Text("Transform selected text with a spoken instruction instead of dictating over it.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 14) {
                Toggle("Enable Edit Mode", isOn: Binding(
                    get: { appState.isCommandModeEnabled },
                    set: { newValue in
                        _ = appState.setCommandModeEnabled(newValue)
                    }
                ))

                Picker("Invocation Style", selection: Binding(
                    get: { appState.commandModeStyle },
                    set: { newValue in
                        _ = appState.setCommandModeStyle(newValue)
                    }
                )) {
                    ForEach(CommandModeStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!appState.isCommandModeEnabled)

                Group {
                    switch appState.commandModeStyle {
                    case .automatic:
                        Text("Automatic mode uses your normal dictation shortcut. If text is selected, \(AppName.displayName) transforms that selection instead of dictating new text.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    case .manual:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Manual mode only triggers when you hold an extra modifier together with your normal dictation shortcut.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            Picker("Extra Modifier", selection: Binding(
                                get: { appState.commandModeManualModifier },
                                set: { newValue in
                                    _ = appState.setCommandModeManualModifier(newValue)
                                }
                            )) {
                                ForEach(CommandModeManualModifier.allCases) { modifier in
                                    Text(modifier.title).tag(modifier)
                                }
                            }
                            .disabled(!appState.isCommandModeEnabled || appState.commandModeStyle != .manual)
                        }
                    }
                }
                .opacity(appState.isCommandModeEnabled ? 1 : 0.5)

                if let validationMessage = appState.commandModeManualModifierValidationMessage {
                    Label(validationMessage, systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)
        }
    }

    var launchAtLoginStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "sunrise.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Launch at Login")
                .font(.title)
                .fontWeight(.bold)

            Text("Start \(AppName.displayName) automatically when you log in so it's always ready.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Image(systemName: "sunrise.fill")
                    .frame(width: 24)
                    .foregroundStyle(.blue)
                Toggle("Launch \(AppName.displayName) at login", isOn: $appState.launchAtLogin)
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

        }
    }

    var readyStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("You're All Set!")
                .font(.title)
                .fontWeight(.bold)

            Text("\(AppName.displayName) lives in your menu bar.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                if appState.hasEnabledHoldShortcut {
                    HowToRow(icon: "keyboard", text: "Hold \(appState.holdShortcut.displayName) to record")
                }
                if appState.hasEnabledToggleShortcut {
                    HowToRow(icon: "switch.2", text: "Tap \(appState.toggleShortcut.displayName) to start and stop")
                }
                if appState.hasEnabledHoldShortcut && appState.hasEnabledToggleShortcut {
                    HowToRow(icon: "arrow.triangle.branch", text: "While holding, press the toggle shortcut to latch on")
                }
                if appState.isCommandModeEnabled {
                    switch appState.commandModeStyle {
                    case .automatic:
                        HowToRow(icon: "wand.and.stars", text: "With text selected, your normal shortcut transforms the selection")
                    case .manual:
                        HowToRow(
                            icon: "wand.and.stars",
                            text: "Hold \(appState.commandModeManualModifier.title) with your normal shortcut to transform selected text"
                        )
                    }
                }
                HowToRow(icon: "doc.on.clipboard", text: "Text is typed at your cursor & copied")
            }
            .padding(.top, 10)

        }
    }

    var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(totalSteps, id: \.rawValue) { step in
                Circle()
                    .fill(step == currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var canContinueFromCurrentStep: Bool {
        switch currentStep {
        case .micPermission:
            return micPermissionGranted
        case .accessibility:
            return accessibilityGranted
        case .screenRecording:
            return appState.hasScreenRecordingPermission
        default:
            return true
        }
    }

    // MARK: - Helpers

    private func instructionRow(number: String, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(number + ".")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 16, alignment: .trailing)
            Text(text)
                .font(.subheadline)
                .tint(.blue)
        }
    }

    // MARK: - Actions

    func saveCustomVocabularyAndContinue() {
        let vocabulary = customVocabularyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        appState.customVocabulary = vocabulary
        // PostHog: Track vocabulary saved during setup
        if !vocabulary.isEmpty {
            let termCount = vocabulary.split(whereSeparator: { $0 == "\n" || $0 == "," || $0 == ";" }).count
            Analytics.capture("vocabulary_saved", properties: [
                "term_count": termCount,
            ])
        }
        withAnimation {
            currentStep = nextStep(currentStep)
        }
    }

    private func previousStep(_ step: SetupStep) -> SetupStep {
        let previous = SetupStep(rawValue: step.rawValue - 1)
        return previous ?? .welcome
    }

    private func nextStep(_ step: SetupStep) -> SetupStep {
        let next = SetupStep(rawValue: step.rawValue + 1)
        return next ?? .ready
    }

    func checkMicPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            micPermissionGranted = true
        default:
            break
        }
    }

    func requestMicPermission() {
        appState.requestMicrophoneAccess { granted in
            micPermissionGranted = granted
        }
    }

    func checkAccessibility() {
        accessibilityGranted = AXIsProcessTrusted()
    }

    func startAccessibilityPolling() {
        accessibilityTimer?.invalidate()
        accessibilityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                checkAccessibility()
            }
        }
    }

    func requestAccessibility() {
        appState.openAccessibilitySettings()
    }

    func startScreenRecordingPolling() {
        screenRecordingTimer?.invalidate()
        screenRecordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                appState.hasScreenRecordingPermission = CGPreflightScreenCaptureAccess()
            }
        }
    }

}

struct HowToRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.blue)
            Text(text)
                .foregroundStyle(.secondary)
        }
    }
}
