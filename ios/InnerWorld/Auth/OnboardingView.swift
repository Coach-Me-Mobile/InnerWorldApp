import SwiftUI

struct OnboardingView: View {
    @State private var showLogin = false
    @State private var showSignup = false

    var body: some View {
        ZStack {
            Theme.backgroundImage
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                Text("Inner\nWorld")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.titleColor)
                    .padding(.horizontal, 24)
                Spacer()
                VStack(spacing: 16) {
                    Button("Log In") { showLogin = true }
                        .buttonStyle(Theme.CapsuleButtonStyle(background: Theme.primaryButtonColor, foreground: Theme.titleColor))

                    Button("Sign Up") { showSignup = true }
                        .buttonStyle(Theme.CapsuleButtonStyle(background: Theme.secondaryButtonColor, foreground: Theme.primaryButtonColor))
                }
                .padding(.horizontal, 80)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showLogin) { LoginView() }
        .sheet(isPresented: $showSignup) { SignupView() }
    }
}
