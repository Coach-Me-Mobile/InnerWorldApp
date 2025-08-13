import Foundation
import Combine
import CryptoKit

final class MockAuthClient: AuthClient {
    private let keychain = KeychainStore()
    private var users: [String: (password: String, birthdate: Date, confirmed: Bool)] = [:]
    private let subject = CurrentValueSubject<AuthSession, Never>(AuthSession(isSignedIn: false, user: nil, tokens: nil))

    private let jwtSecret = "dev_secret_change_me"

    init() {
        if let data = keychain.load(), let session = try? JSONDecoder().decode(AuthSession.self, from: data), session.isSignedIn {
            subject.send(session)
        }
    }

    func signUp(email: String, password: String, birthdate: Date, acceptedTerms: Bool) -> AnyPublisher<Void, AuthError> {
        guard acceptedTerms else { return Fail(error: .termsNotAccepted).eraseToAnyPublisher() }
        guard Self.is13OrOlder(birthdate) else { return Fail(error: .underAge).eraseToAnyPublisher() }
        guard users[email.lowercased()] == nil else { return Fail(error: .userAlreadyExists).eraseToAnyPublisher() }

        users[email.lowercased()] = (password: password, birthdate: birthdate, confirmed: true)
        return Just(()).setFailureType(to: AuthError.self).eraseToAnyPublisher()
    }

    func confirmSignUp(email: String, code: String) -> AnyPublisher<Void, AuthError> {
        return Just(()).setFailureType(to: AuthError.self).eraseToAnyPublisher()
    }

    func signIn(email: String, password: String) -> AnyPublisher<AuthSession, AuthError> {
        let key = email.lowercased()
        guard let u = users[key] else { return Fail(error: .userNotFound).eraseToAnyPublisher() }
        guard u.password == password else { return Fail(error: .invalidCredentials).eraseToAnyPublisher() }

        return succeedSession(email: key)
    }

    func signInWithApple(idToken: String) -> AnyPublisher<AuthSession, AuthError> {
        let email = "apple_user_\(UUID().uuidString.prefix(8))@example.com"
        if users[email] == nil {
            users[email] = (password: UUID().uuidString, birthdate: Date(timeIntervalSince1970: 0), confirmed: true)
        }
        return succeedSession(email: email)
    }

    func fetchAuthSession() -> AnyPublisher<AuthSession, Never> {
        subject.eraseToAnyPublisher()
    }

    func signOut() -> AnyPublisher<Void, Never> {
        keychain.clear()
        let empty = AuthSession(isSignedIn: false, user: nil, tokens: nil)
        subject.send(empty)
        return Just(()).eraseToAnyPublisher()
    }

    private func succeedSession(email: String) -> AnyPublisher<AuthSession, AuthError> {
        let user = AuthUser(userId: UUID().uuidString, username: email, email: email)
        let tokens = createTokens(for: user)
        let session = AuthSession(isSignedIn: true, user: user, tokens: tokens)
        if let data = try? JSONEncoder().encode(session) {
            keychain.save(data)
        }
        subject.send(session)
        return Just(session).setFailureType(to: AuthError.self).eraseToAnyPublisher()
    }

    private func createTokens(for user: AuthUser) -> AuthTokens {
        let expiry = Date().addingTimeInterval(3600)
        let header = #"{"alg":"HS256","typ":"JWT"}"#
        let payload = #"{"sub":"\#(user.userId)","email":"\#(user.email)","exp":\#(Int(expiry.timeIntervalSince1970))}"#
        func b64(_ s: String) -> String { Data(s.utf8).base64EncodedString().replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_") }
        let signingInput = b64(header) + "." + b64(payload)
        let key = SymmetricKey(data: Data(jwtSecret.utf8))
        let sig = HMAC<SHA256>.authenticationCode(for: Data(signingInput.utf8), using: key)
        let signature = Data(sig).base64EncodedString().replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
        let jwt = signingInput + "." + signature
        return AuthTokens(accessToken: jwt, refreshToken: nil, idToken: jwt, expiresAt: expiry)
    }

    private static func is13OrOlder(_ birthdate: Date) -> Bool {
        let cal = Calendar(identifier: .gregorian)
        if let thirteen = cal.date(byAdding: .year, value: 13, to: birthdate) {
            return thirteen <= Date()
        }
        return false
    }
}