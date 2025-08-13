import Foundation

struct AuthUser: Codable, Equatable {
    let userId: String
    let username: String
    let email: String
}

struct AuthTokens: Codable, Equatable {
    let accessToken: String
    let refreshToken: String?
    let idToken: String?
    let expiresAt: Date
}

struct AuthSession: Codable, Equatable {
    let isSignedIn: Bool
    let user: AuthUser?
    let tokens: AuthTokens?
}

enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case userNotFound
    case userAlreadyExists
    case underAge
    case termsNotAccepted
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid email or password."
        case .userNotFound: return "No account found for that email."
        case .userAlreadyExists: return "An account already exists for that email."
        case .underAge: return "You must be 13 years or older to use Inner World."
        case .termsNotAccepted: return "Please accept the Terms & Conditions to continue."
        case .unknown(let msg): return msg
        }
    }
}