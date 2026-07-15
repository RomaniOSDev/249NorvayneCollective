import SwiftUI

/// Lightweight depth tokens — one shadow max, 2-stop gradients, no blur.
enum DepthStyle {
    static let cardRadius: CGFloat = 18
    static let chipRadius: CGFloat = 14
    static let shadowColor = Color.black.opacity(0.28)
    static let softShadowColor = Color.black.opacity(0.18)

    static var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppSurface"),
                Color("AppBackground").opacity(0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var elevatedGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppSurface").opacity(0.98),
                Color("AppBackground").opacity(0.88)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var accentGlowGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppAccent").opacity(0.22),
                Color("AppPrimary").opacity(0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var primaryButtonGradient: LinearGradient {
        LinearGradient(
            colors: [Color("AppPrimary"), Color("AppAccent").opacity(0.88)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var destructiveButtonGradient: LinearGradient {
        LinearGradient(
            colors: [Color.red.opacity(0.92), Color.red.opacity(0.72)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppBackground"),
                Color("AppSurface").opacity(0.85),
                Color("AppBackground")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct ElevatedSurface: View {
    var cornerRadius: CGFloat = DepthStyle.cardRadius
    var accent: Bool = false
    var elevated: Bool = true

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(accent ? DepthStyle.accentGlowGradient : DepthStyle.elevatedGradient)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color("AppTextPrimary").opacity(accent ? 0.22 : 0.14),
                                Color("AppTextPrimary").opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: accent ? 1.4 : 1
                    )
            )
            .shadow(
                color: elevated ? DepthStyle.softShadowColor : .clear,
                radius: elevated ? 8 : 0,
                x: 0,
                y: elevated ? 4 : 0
            )
    }
}

extension View {
    /// Single soft drop shadow — safe for lists (no blur, no stacked shadows).
    func appDepth(elevated: Bool = true) -> some View {
        shadow(
            color: elevated ? DepthStyle.softShadowColor : .clear,
            radius: elevated ? 8 : 0,
            x: 0,
            y: elevated ? 4 : 0
        )
    }

    func appPressScale(_ pressed: Bool) -> some View {
        scaleEffect(pressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: pressed)
    }
}
