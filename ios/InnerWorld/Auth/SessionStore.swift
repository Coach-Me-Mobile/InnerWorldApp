import Foundation
import Combine

final class SessionStore: ObservableObject {
    enum State {
        case loading
        case signedOut
        case signedIn(AuthUser)
    }

    @Published private(set) var state: State = .loading

    private let auth: AuthClient
    private var bag = Set<AnyCancellable>()

    init(auth: AuthClient) {
        self.auth = auth

        auth.fetchAuthSession()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                if session.isSignedIn, let user = session.user {
                    self?.state = .signedIn(user)
                } else {
                    self?.state = .signedOut
                }
            }
            .store(in: &bag)
    }

    func signOut() {
        auth.signOut().sink { _ in }.store(in: &bag)
    }

    var client: AuthClient { auth }
}