import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStorageStore
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            headline: "Protect From Frost",
            body: "Stay informed about potential frost events to safeguard your property.",
            symbol: "shield.fill",
            imageName: "FrostProtectAssets",
            pill: "Property care"
        ),
        OnboardingPage(
            headline: "Track Temperature",
            body: "Monitor real-time temperatures to predict freezing conditions effectively.",
            symbol: "thermometer.medium",
            imageName: "FrostThermometer",
            pill: "Live outlook"
        ),
        OnboardingPage(
            headline: "Get Started Now",
            body: "Begin by allowing the app access to display local temperature trends.",
            symbol: "chart.line.uptrend.xyaxis",
            imageName: "FrostHeroNight",
            pill: "City forecast"
        )
    ]

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(
                            page: pages[index],
                            index: index,
                            isActive: page == index
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: page)

                bottomControls
            }
        }
        .preferredColorScheme(.dark)
    }

    private var bottomControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(
                            index == page
                            ? DepthStyle.primaryButtonGradient
                            : LinearGradient(
                                colors: [
                                    Color("AppTextSecondary").opacity(0.35),
                                    Color("AppTextSecondary").opacity(0.2)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: index == page ? 26 : 8, height: 8)
                        .shadow(
                            color: index == page ? DepthStyle.softShadowColor : .clear,
                            radius: 3,
                            y: 1
                        )
                        .animation(.easeInOut(duration: 0.2), value: page)
                }
            }

            HStack(spacing: 10) {
                if page > 0 {
                    SecondaryButton(title: "Back") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            page -= 1
                        }
                    }
                    .frame(maxWidth: 120)
                }

                PrimaryButton(title: page == pages.count - 1 ? "Get Started" : "Next") {
                    if page < pages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            page += 1
                        }
                    } else {
                        HapticFeedback.success()
                        store.completeOnboarding()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 8)
        .padding(.bottom, 28)
        .background(
            LinearGradient(
                colors: [
                    Color("AppBackground").opacity(0.0),
                    Color("AppBackground").opacity(0.85),
                    Color("AppBackground")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
        )
    }
}

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let headline: String
    let body: String
    let symbol: String
    let imageName: String
    let pill: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let index: Int
    let isActive: Bool
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroCard
                    .padding(.top, 12)

                textCard

                featureHints
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .clearScrollBackground()
        .onAppear { playAppear() }
        .onChange(of: isActive) { active in
            if active { playAppear() }
        }
    }

    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            Image(page.imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .clipped()

            LinearGradient(
                colors: [
                    Color("AppBackground").opacity(0.05),
                    Color("AppBackground").opacity(0.45),
                    Color("AppBackground").opacity(0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    IconBadge(systemName: page.symbol, tint: Color("AppAccent"), size: 44)
                    StatusPill(text: page.pill, isWarning: index == 0)
                }

                Text("Step \(index + 1) of 3")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color("AppTextPrimary").opacity(0.24),
                            Color("AppAccent").opacity(0.25),
                            Color("AppTextPrimary").opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .shadow(color: DepthStyle.shadowColor, radius: 14, y: 8)
        .scaleEffect(appeared ? 1 : 0.94)
        .opacity(appeared ? 1 : 0)
    }

    private var textCard: some View {
        AppCard(accentBorder: true) {
            VStack(alignment: .leading, spacing: 12) {
                Text(page.headline)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .fixedSize(horizontal: false, vertical: true)

                Text(page.body)
                    .font(.body)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    MetricChip(title: "Mode", value: "Offline-ready")
                    MetricChip(title: "Focus", value: "Frost prep", emphasize: true)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    private var featureHints: some View {
        HStack(spacing: 10) {
            hintTile(symbol: "mappin.and.ellipse", title: "City pick")
            hintTile(symbol: "moon.stars.fill", title: "Night risk")
            hintTile(symbol: "checklist", title: "Tonight plan")
        }
        .opacity(appeared ? 1 : 0)
    }

    private func hintTile(symbol: String, title: String) -> some View {
        VStack(spacing: 8) {
            IconBadge(systemName: symbol, tint: Color("AppPrimary"), size: 36)
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(ElevatedSurface(accent: false, elevated: false))
    }

    private func playAppear() {
        appeared = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
            appeared = true
        }
    }
}
