import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @ObservedObject var auth: AuthenticationService

    @State private var email: String = ""
    @State private var errorMessage: String?
    @State private var isWorking: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Sign in to Stro Speak")
                    .font(.headline)
                Text("Your account unlocks dictation quota, subscription, and (later) sync across devices.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                do {
                    _ = try auth.processAppleAuthorization(result)
                    errorMessage = nil
                } catch AuthError.canceled {
                    // Silent
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 36)
            .disabled(isWorking)

            HStack {
                Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                Text("OR").font(.caption).foregroundStyle(.secondary)
                Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Email")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField("you@example.com", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .disableAutocorrection(true)

                Button {
                    runEmailSignIn()
                } label: {
                    if isWorking {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Continue with email").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isWorking || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func runEmailSignIn() {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            _ = try auth.signInWithEmail(email)
            email = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
