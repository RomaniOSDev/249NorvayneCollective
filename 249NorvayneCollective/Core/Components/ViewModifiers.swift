import SwiftUI

struct ShakeEffect: GeometryEffect {
    var travelDistance: CGFloat = 8
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: travelDistance * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
                y: 0
            )
        )
    }
}

extension View {
    func clearScrollBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.clear)
    }

    func transparentScreenChrome() -> some View {
        background(Color.clear)
    }
}

struct SuccessCheckBadge: View {
    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 44, weight: .semibold))
            .foregroundStyle(Color("AppAccent"))
            .shadow(color: DepthStyle.shadowColor, radius: 8, y: 3)
    }
}

struct AchievementBannerView: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(systemName: "star.fill", tint: Color("AppAccent"), size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(ElevatedSurface(accent: true, elevated: true))
        .padding(.horizontal, 16)
    }
}
