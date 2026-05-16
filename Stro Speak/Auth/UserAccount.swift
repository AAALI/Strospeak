import Foundation

enum AuthProvider: String, Codable {
    case apple
    case email
}

struct UserAccount: Codable, Equatable {
    let id: String
    let provider: AuthProvider
    var email: String?
    var fullName: String?
    var createdAt: Date

    var displayLabel: String {
        if let email, !email.isEmpty { return email }
        if let fullName, !fullName.isEmpty { return fullName }
        return id
    }
}
