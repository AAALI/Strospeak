import Foundation
import AppKit
import AuthenticationServices
import Combine

enum AuthError: LocalizedError {
    case appleSignInFailed(String)
    case invalidEmail
    case unexpectedCredential
    case canceled

    var errorDescription: String? {
        switch self {
        case .appleSignInFailed(let msg): return "Sign in with Apple failed: \(msg)"
        case .invalidEmail: return "Please enter a valid email address."
        case .unexpectedCredential: return "Apple returned an unexpected credential."
        case .canceled: return "Sign-in was canceled."
        }
    }
}

@MainActor
final class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()

    private static let accountStorageKey = "user_account_v1"

    @Published private(set) var currentAccount: UserAccount?

    var isSignedIn: Bool { currentAccount != nil }

    init() {
        currentAccount = Self.loadAccount()
    }

    // MARK: - Apple
    //
    // Driven by `SignInWithAppleButton`'s native completion handler. The
    // button owns the `ASAuthorizationController`; we just consume the
    // verified credential it produces and persist a `UserAccount`.

    @discardableResult
    func processAppleAuthorization(_ result: Result<ASAuthorization, Error>) throws -> UserAccount {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw AuthError.unexpectedCredential
            }
            let userID = credential.user
            let email = credential.email
            let fullName = credential.fullName.flatMap {
                PersonNameComponentsFormatter().string(from: $0)
            }

            // Apple only returns email/name on the FIRST sign-in. Merge with
            // any previously-stored values for the same Apple user.
            let existing = currentAccount
            let mergedEmail = email?.isEmpty == false ? email : existing?.email
            let mergedName = (fullName?.isEmpty == false ? fullName : nil) ?? existing?.fullName

            let account = UserAccount(
                id: "apple:" + userID,
                provider: .apple,
                email: mergedEmail,
                fullName: mergedName,
                createdAt: existing?.createdAt ?? Date()
            )
            persist(account)
            Analytics.capture("auth_signed_in", properties: ["provider": "apple"])
            return account

        case .failure(let error):
            if let asError = error as? ASAuthorizationError, asError.code == .canceled {
                throw AuthError.canceled
            }
            throw AuthError.appleSignInFailed(error.localizedDescription)
        }
    }

    // MARK: - Email
    //
    // Local email sign-in. Validates format and stores the email as the
    // account identity. When a hosted backend is added, swap the body for a
    // magic-link / OAuth handshake — the rest of the app keys off
    // `UserAccount.id`, so no callers need to change.

    @discardableResult
    func signInWithEmail(_ rawEmail: String) throws -> UserAccount {
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard Self.isValidEmail(email) else { throw AuthError.invalidEmail }

        let account = UserAccount(
            id: "email:" + email,
            provider: .email,
            email: email,
            fullName: nil,
            createdAt: Date()
        )
        persist(account)
        Analytics.capture("auth_signed_in", properties: ["provider": "email"])
        return account
    }

    func signOut() {
        AppSettingsStorage.delete(account: Self.accountStorageKey)
        currentAccount = nil
        Analytics.capture("auth_signed_out")
    }

    // MARK: - Storage

    private func persist(_ account: UserAccount) {
        if let data = try? JSONEncoder().encode(account),
           let str = String(data: data, encoding: .utf8) {
            AppSettingsStorage.save(str, account: Self.accountStorageKey)
        }
        currentAccount = account
    }

    private static func loadAccount() -> UserAccount? {
        guard let str = AppSettingsStorage.load(account: accountStorageKey),
              let data = str.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(UserAccount.self, from: data)
    }

    private static func isValidEmail(_ email: String) -> Bool {
        // Minimal RFC-5322-ish check; production validation happens server-side.
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}
