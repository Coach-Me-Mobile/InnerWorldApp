import SwiftUI
import Combine
import AuthenticationServices

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionStore

    @State private var email = ""
    @State private var password = ""
    @State private var error: String?
    @State private var bag = Set<AnyCancellable>()

    var body: some View {
        VStack(spacing: 16) {
            Text("Log In")
                .font(.system(size: 32, weight: .bold, design: .rounded))
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding().background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
            SecureField("Password", text: $password)
                .textContentType(.password)
                .padding().background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 12))

            if let error { Text(error).foregroundColor(.red).font(.footnote) }

            Button("Log In") { login() }
                .buttonStyle(Theme.CapsuleButtonStyle(background: Theme.primaryButtonColor, foreground: Theme.titleColor))

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = []
            } onCompletion: { result in
                handleApple(result: result)
            }
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(height: 50)
            .clipShape(Capsule())

            Spacer()
        }
        .padding()
        .background(
            Theme.backgroundImage
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        )
    }

    private func login() {
        error = nil
        session.client
            .signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let e) = completion { error = e.localizedDescription }
            }, receiveValue: { _ in
                dismiss()
            })
            .store(in: &bag)
    }

    private func handleApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential,
               let tokenData = credential.identityToken,
               let idToken = String(data: tokenData, encoding: .utf8) {
                session.client.signInWithApple(idToken: idToken)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { completion in
                        if case .failure(let e) = completion { error = e.localizedDescription }
                    }, receiveValue: { _ in
                        dismiss()
                    })
                    .store(in: &bag)
            } else {
                error = "Apple sign in failed."
            }
        case .failure(let err):
            error = err.localizedDescription
        }
    }
}