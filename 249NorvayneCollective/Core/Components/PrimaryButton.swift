import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isDestructive: Bool = false
    var isLoading: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            guard !isLoading else { return }
            HapticFeedback.lightTap()
            action()
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(Color("AppTextPrimary"))
                }
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        isDestructive
                        ? DepthStyle.destructiveButtonGradient
                        : DepthStyle.primaryButtonGradient
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color("AppTextPrimary").opacity(0.28),
                                        Color("AppTextPrimary").opacity(0.05)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: DepthStyle.shadowColor, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .appPressScale(isPressed)
        .opacity(isLoading ? 0.85 : 1)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct EmptyStateView: View {
    let symbolName: String
    let title: String
    var message: String? = nil

    var body: some View {
        AppCard(accentBorder: true) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color("AppAccent").opacity(0.25),
                                    Color("AppBackground").opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                        .shadow(color: DepthStyle.softShadowColor, radius: 6, y: 3)

                    Circle()
                        .stroke(Color("AppAccent").opacity(0.45), lineWidth: 2)
                        .frame(width: 88, height: 88)

                    Image(systemName: symbolName)
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(Color("AppAccent"))
                }
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .multilineTextAlignment(.center)
                if let message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }
}
