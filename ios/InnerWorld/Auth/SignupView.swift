import SwiftUI
import Combine
import AuthenticationServices

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionStore

    @State private var email = ""
    @State private var password = ""
    @State private var birthdate = Date(timeIntervalSinceNow: -60*60*24*365*16)
    @State private var accepted = false
    @State private var showTerms = false
    @State private var error: String?
    @State private var bag = Set<AnyCancellable>()

    var body: some View {
        VStack(spacing: 16) {
            Text("Sign Up")
                .font(.system(size: 32, weight: .bold, design: .rounded))
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding().background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
            SecureField("Password", text: $password)
                .textContentType(.newPassword)
                .padding().background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 12))

            DatePicker("Birthday", selection: $birthdate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .tint(.white)
                .padding().background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 12))

            Toggle(isOn: $accepted) {
                HStack {
                    Text("I accept the")
                    Button("Terms & Conditions") { showTerms = true }
                        .underline()
                }
            }
            .tint(Theme.secondaryButtonColor)
            .padding(.horizontal, 4)

            if let error { Text(error).foregroundColor(.red).font(.footnote) }

            Button("Create Account") { signup() }
                .buttonStyle(Theme.CapsuleButtonStyle(background: Theme.secondaryButtonColor, foreground: Theme.primaryButtonColor))

            SignInWithAppleButton(.signUp) { request in
                request.requestedScopes = [.email]
            } onCompletion: { result in
                handleAppleSignUp(result: result)
            }
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(height: 50)
            .clipShape(Capsule())

            Spacer(minLength: 0)
        }
        .padding()
        .sheet(isPresented: $showTerms) { TermsView() }
        .background(
            Theme.backgroundImage
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        )
    }

    private func signup() {
        error = nil
        session.client
            .signUp(email: email.trimmingCharacters(in: .whitespaces), password: password, birthdate: birthdate, acceptedTerms: accepted)
            .flatMap { [session] _ in
                session.client.signIn(email: email, password: password)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let e) = completion { error = e.localizedDescription }
            }, receiveValue: { _ in
                dismiss()
            })
            .store(in: &bag)
    }
    
    private func handleAppleSignUp(result: Result<ASAuthorization, Error>) {
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
                error = "Apple sign up failed."
            }
        case .failure(let err):
            error = err.localizedDescription
        }
    }
}
