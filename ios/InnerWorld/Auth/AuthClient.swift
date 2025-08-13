import Foundation
import Combine

protocol AuthClient {
    func signUp(email: String, password: String, birthdate: Date, acceptedTerms: Bool) -> AnyPublisher<Void, AuthError>
    func confirmSignUp(email: String, code: String) -> AnyPublisher<Void, AuthError>
    
    func signIn(email: String, password: String) -> AnyPublisher<AuthSession, AuthError>
    func signInWithApple(idToken: String) -> AnyPublisher<AuthSession, AuthError>
    
    func fetchAuthSession() -> AnyPublisher<AuthSession, Never>
    func signOut() -> AnyPublisher<Void, Never>
}