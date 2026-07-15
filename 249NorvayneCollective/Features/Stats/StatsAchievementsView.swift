import SwiftUI

struct StatsAchievementsView: View {
    let bottomInset: CGFloat
    var usesOwnNavigation: Bool = true
    @EnvironmentObject private var store: AppStorageStore

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Group {
            if usesOwnNavigation {
                NavigationStack { coreContent }
                    .transparentScreenChrome()
            } else {
                coreContent
            }
        }
    }

    private var coreContent: some View {
        ZStack {
            if usesOwnNavigation { AppBackgroundView() }

            ScrollView {
                VStack(spacing: 18) {
                    SectionHeaderView(
                        title: "Your Progress",
                        subtitle: "Counters and decorative achievements",
                        trailing: "\(store.achievementsUnlocked.count)/\(AchievementCatalog.all.count)"
                    )

                    summaryCard

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(AchievementCatalog.all) { achievement in
                            let unlocked = store.achievementsUnlocked[achievement.id] != nil
                                || achievement.isUnlocked(store)
                            AchievementCell(
                                title: achievement.title,
                                detail: achievement.detail,
                                symbolName: achievement.symbolName,
                                unlocked: unlocked
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, bottomInset)
            }
            .clearScrollBackground()
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppBackground"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var summaryCard: some View {
        AppCard(accentBorder: store.streakDays >= 3) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Summary")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 10
                ) {
                    MetricChip(title: "Entries", value: "\(store.itemsCreated)")
                    MetricChip(title: "Sessions", value: "\(store.totalSessionsCompleted)")
                    MetricChip(title: "Minutes", value: "\(store.totalMinutesUsed)")
                    MetricChip(title: "Streak", value: "\(store.streakDays)d", emphasize: store.streakDays >= 3)
                }
            }
        }
    }
}
