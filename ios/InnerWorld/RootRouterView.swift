import SwiftUI

struct RootRouterView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        switch session.state {
        case .loading:
            ProgressView().progressViewStyle(.circular)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Theme.backgroundImage
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                )
        case .signedOut:
            OnboardingView()
        case .signedIn:
            ContentView()
                .edgesIgnoringSafeArea(.all)
        }
    }
}