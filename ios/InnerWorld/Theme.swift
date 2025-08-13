import SwiftUI

enum Theme {
    static let backgroundGradient = LinearGradient(
        colors: [Color(red:0.28, green:0.11, blue:0.44), Color(red:0.88, green:0.44, blue:0.55)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let backgroundImage = Image("Background")

    static let primaryButtonColor = Color(red:0.22, green:0.12, blue:0.36)
    static let secondaryButtonColor = Color(red:0.98, green:0.90, blue:0.82)
    static let titleColor = Color(red:0.99, green:0.93, blue:0.85)

    struct CapsuleButtonStyle: ButtonStyle {
        let background: Color
        let foreground: Color

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(foreground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(background)
                .clipShape(Capsule())
                .opacity(configuration.isPressed ? 0.9 : 1.0)
        }
    }
}