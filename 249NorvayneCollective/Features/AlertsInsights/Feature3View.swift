import SwiftUI

struct Feature3View: View {
    let bottomInset: CGFloat
    var usesOwnNavigation: Bool = true
    @EnvironmentObject private var store: AppStorageStore
    @StateObject private var viewModel: Feature3ViewModel

    init(bottomInset: CGFloat, usesOwnNavigation: Bool = true) {
        self.bottomInset = bottomInset
        self.usesOwnNavigation = usesOwnNavigation
        _viewModel = StateObject(wrappedValue: Feature3ViewModel(store: AppStorageStore.shared))
    }

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

            VStack(spacing: 0) {
                Picker(
                    "Timeframe",
                    selection: Binding(
                        get: { Feature3ViewModel.Timeframe(rawValue: store.selectedTimeframe) ?? .daily },
                        set: { viewModel.setTimeframe($0) }
                    )
                ) {
                    ForEach(Feature3ViewModel.Timeframe.allCases) { frame in
                        Text(frame.rawValue).tag(frame)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Group {
                    if viewModel.filteredHistory.isEmpty {
                        ScrollView {
                            VStack(spacing: 18) {
                                SectionHeaderView(
                                    title: "Frost Patterns",
                                    subtitle: "Historical lows and frost duration"
                                )
                                EmptyStateView(
                                    symbolName: "thermometer.snowflake",
                                    title: "No frost history yet",
                                    message: "Enable data logging by syncing frost records from your forecasts."
                                )
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                        }
                        .clearScrollBackground()
                    } else {
                        List {
                            ForEach(viewModel.filteredHistory) { entry in
                                Button {
                                    viewModel.openDetail(entry)
                                } label: {
                                    HistoryCell(
                                        dateText: entry.date.formatted(date: .abbreviated, time: .omitted),
                                        minTempText: "Min \(store.displayTemperature(entry.minTemperature))",
                                        durationText: String(format: "%.1f h", entry.durationHours)
                                    )
                                }
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.deleteEntry(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .clearScrollBackground()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    PrimaryButton(title: "Sync Data") {
                        viewModel.syncData()
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

            if viewModel.showSuccessBadge {
                SuccessCheckBadge()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle("Frost Pattern Insights")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppBackground"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $viewModel.showDetail) {
            if let entry = viewModel.selectedEntry {
                HistoryDetailSheet(entry: entry, store: store)
            }
        }
    }

}

private struct HistoryDetailSheet: View {
    let entry: FrostEntry
    let store: AppStorageStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(entry.date.formatted(date: .complete, time: .omitted))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))

                        Text("Minimum temperature: \(store.displayTemperature(entry.minTemperature))")
                            .foregroundStyle(Color("AppTextPrimary"))

                        Text("Frost duration: \(String(format: "%.1f", entry.durationHours)) hours")
                            .foregroundStyle(Color("AppTextPrimary"))

                        Text(entry.summary.isEmpty
                             ? "Use this pattern to schedule covers and pipe protection ahead of similar nights."
                             : entry.summary)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Pattern Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        HapticFeedback.lightTap()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
