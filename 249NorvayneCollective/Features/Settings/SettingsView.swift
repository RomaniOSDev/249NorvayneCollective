import SwiftUI
import StoreKit
import UIKit

struct SettingsView: View {
    let bottomInset: CGFloat
    @EnvironmentObject private var store: AppStorageStore
    @State private var showResetAlert = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 18) {
                        SectionHeaderView(
                            title: "Settings",
                            subtitle: "Activity, privacy, and data controls"
                        )

                        statsCard

                        NavigationLink {
                            StatsAchievementsView(bottomInset: 40, usesOwnNavigation: false)
                        } label: {
                            SettingsRowCell(
                                title: "Achievements",
                                systemImage: "star.circle.fill",
                                value: "\(store.achievementsUnlocked.count)/\(AchievementCatalog.all.count)"
                            )
                            .background(ElevatedSurface(accent: false, elevated: false))
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            HapticFeedback.lightTap()
                        })

                        AppCard(padding: 0) {
                            VStack(spacing: 0) {
                                Button {
                                    HapticFeedback.lightTap()
                                    rateApp()
                                } label: {
                                    SettingsRowCell(title: "Rate Us", systemImage: "star.fill")
                                }
                                .buttonStyle(.plain)

                                Divider().overlay(Color("AppTextSecondary").opacity(0.2))

                                Button {
                                    HapticFeedback.lightTap()
                                    openLink(.privacyPolicy)
                                } label: {
                                    SettingsRowCell(title: "Privacy", systemImage: "hand.raised.fill")
                                }
                                .buttonStyle(.plain)

                                Divider().overlay(Color("AppTextSecondary").opacity(0.2))

                                Button {
                                    HapticFeedback.lightTap()
                                    openLink(.termsOfUse)
                                } label: {
                                    SettingsRowCell(title: "Terms", systemImage: "doc.text.fill")
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if let city = store.selectedCity {
                            AppCard {
                                HStack(spacing: 12) {
                                    IconBadge(systemName: "mappin.and.ellipse", tint: Color("AppAccent"))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Active city")
                                            .font(.caption)
                                            .foregroundStyle(Color("AppTextSecondary"))
                                        Text(city.displayName)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color("AppTextPrimary"))
                                            .lineLimit(2)
                                    }
                                }
                            }
                        }

                        PrimaryButton(title: "Reset All Data", isDestructive: true) {
                            showResetAlert = true
                        }

                        Text("Version \(appVersion)")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, bottomInset)
                }
                .clearScrollBackground()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {
                    HapticFeedback.lightTap()
                }
                Button("Reset", role: .destructive) {
                    HapticFeedback.warning()
                    store.resetAllData()
                }
            } message: {
                Text("This clears onboarding, forecasts, alerts, history, and achievements stored on this device.")
            }
        }
        .transparentScreenChrome()
    }

    private var statsCard: some View {
        AppCard(accentBorder: store.streakDays >= 3) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Activity")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 10
                ) {
                    MetricChip(title: "Entries", value: "\(store.itemsCreated)")
                    MetricChip(title: "Minutes", value: "\(store.totalMinutesUsed)")
                    MetricChip(title: "Streak", value: "\(store.streakDays)d", emphasize: store.streakDays >= 3)
                    MetricChip(title: "Sessions", value: "\(store.totalSessionsCompleted)")
                }
            }
        }
    }

    private func openLink(_ link: AppLink) {
        if let url = link.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
