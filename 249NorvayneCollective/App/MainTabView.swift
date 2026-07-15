import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: AppStorageStore
    @State private var selection: AppTab = .tracker
    @State private var bannerQueue: [String] = []
    @State private var currentBanner: String?
    @State private var showBanner = false

    private let tabBarClearance: CGFloat = 110

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case .tracker:
                    Feature1View(bottomInset: tabBarClearance)
                case .prepare:
                    PrepareHubView(bottomInset: tabBarClearance)
                case .journal:
                    FrostJournalView(bottomInset: tabBarClearance)
                case .settings:
                    SettingsView(bottomInset: tabBarClearance)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            CustomTabBar(selection: $selection)

            if showBanner, let currentBanner {
                VStack {
                    AchievementBannerView(title: currentBanner)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .padding(.top, 8)
                .zIndex(10)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .achievementUnlocked)) { note in
            if let title = note.userInfo?["title"] as? String {
                enqueueBanner(title)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .dataReset)) { _ in
            selection = .tracker
            bannerQueue.removeAll()
            currentBanner = nil
            showBanner = false
        }
    }

    private func enqueueBanner(_ title: String) {
        bannerQueue.append(title)
        presentNextBannerIfNeeded()
    }

    private func presentNextBannerIfNeeded() {
        guard currentBanner == nil, let next = bannerQueue.first else { return }
        bannerQueue.removeFirst()
        currentBanner = next
        HapticFeedback.success()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showBanner = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                currentBanner = nil
                presentNextBannerIfNeeded()
            }
        }
    }
}
