import SwiftUI

struct TonightChecklistSection: View {
    let bottomInset: CGFloat
    let onShare: () -> Void
    let onRebuild: () -> Void
    @EnvironmentObject private var store: AppStorageStore
    @State private var pulsedID: UUID?

    private var doneCount: Int {
        store.tonightChecklist.filter(\.isDone).count
    }

    var body: some View {
        List {
            Section {
                riskSummary
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if store.tonightChecklist.isEmpty {
                Section {
                    EmptyStateView(
                        symbolName: "moon.stars",
                        title: "No tonight checklist",
                        message: "Rebuild from the latest forecast and assets at risk."
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            } else {
                Section {
                    SectionHeaderView(
                        title: "Tonight Checklist",
                        subtitle: "Tap to complete each action",
                        trailing: "\(doneCount)/\(store.tonightChecklist.count)"
                    )
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    ForEach(store.tonightChecklist) { item in
                        Button {
                            toggle(item)
                        } label: {
                            ChecklistCell(
                                title: item.title,
                                isDone: item.isDone,
                                isPulsed: pulsedID == item.id
                            )
                        }
                        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                remove(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .clearScrollBackground()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 10) {
                PrimaryButton(title: "Rebuild Checklist") {
                    onRebuild()
                }
                SecondaryButton(title: "Share Night Plan", action: onShare)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, bottomInset)
            .background(
                LinearGradient(
                    colors: [
                        Color("AppBackground").opacity(0),
                        Color("AppBackground").opacity(0.92),
                        Color("AppBackground")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    private var riskSummary: some View {
        let night = store.lastNightMinC
        let day = store.lastDayMinC
        let atRisk = store.assetsAtRisk(forNightMin: night, dayMin: day)

        return RiskHeroCard(
            cityLabel: store.selectedCity?.displayName ?? "Select a city in Tracker first",
            dayText: day.map(store.displayTemperature) ?? "—",
            nightText: night.map(store.displayTemperature) ?? "—",
            dayRisky: (day ?? 99) <= 0,
            nightRisky: (night ?? 99) <= 0,
            assetsLine: atRisk.isEmpty
                ? "No assets under threshold for the latest lows."
                : "\(atRisk.count) asset(s) need protection tonight."
        )
    }

    private func toggle(_ item: TonightChecklistItem) {
        HapticFeedback.lightTap()
        guard let index = store.tonightChecklist.firstIndex(where: { $0.id == item.id }) else { return }
        store.tonightChecklist[index].isDone.toggle()
        if store.tonightChecklist[index].isDone {
            HapticFeedback.success()
            pulsedID = item.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                pulsedID = nil
            }
            if store.tonightChecklist.allSatisfy(\.isDone) {
                store.recordMeaningfulAction(itemsDelta: 1, sessionCompleted: true)
            }
        }
    }

    private func remove(_ item: TonightChecklistItem) {
        HapticFeedback.lightTap()
        store.tonightChecklist.removeAll { $0.id == item.id }
    }
}
