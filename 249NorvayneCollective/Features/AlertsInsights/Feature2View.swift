import SwiftUI

struct Feature2View: View {
    let bottomInset: CGFloat
    var usesOwnNavigation: Bool = true
    @EnvironmentObject private var store: AppStorageStore
    @StateObject private var viewModel: Feature2ViewModel

    init(bottomInset: CGFloat, usesOwnNavigation: Bool = true) {
        self.bottomInset = bottomInset
        self.usesOwnNavigation = usesOwnNavigation
        _viewModel = StateObject(wrappedValue: Feature2ViewModel(store: AppStorageStore.shared))
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
                if viewModel.showSearch {
                    TextField("Search alerts", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color("AppSurface"))
                        )
                        .foregroundStyle(Color("AppTextPrimary"))
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }

                Group {
                    if viewModel.filteredAlerts.isEmpty {
                        ScrollView {
                            VStack(spacing: 18) {
                                SectionHeaderView(
                                    title: "Alert History",
                                    subtitle: "Past frost alerts sorted newest first"
                                )
                                EmptyStateView(
                                    symbolName: "snowflake.circle",
                                    title: "No past alerts recorded yet",
                                    message: "No alerts yet. Check back when alerts start coming in."
                                )
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                        }
                        .clearScrollBackground()
                    } else {
                        List {
                            Section {
                                SectionHeaderView(
                                    title: "Alert History",
                                    subtitle: "Swipe for favorite or delete",
                                    trailing: "\(viewModel.filteredAlerts.count)"
                                )
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }

                            ForEach(viewModel.filteredAlerts) { alert in
                                Button {
                                    viewModel.openDetail(alert)
                                } label: {
                                    AlertCell(
                                        severityTitle: alert.severity.title,
                                        symbolName: alert.severity.symbolName,
                                        dateText: alert.date.formatted(date: .abbreviated, time: .shortened),
                                        temperatureText: store.displayTemperature(alert.temperature),
                                        isFavorite: store.favoriteAlerts.contains(alert.id),
                                        isHardFreeze: alert.severity == .hardFreeze
                                    )
                                    .opacity(viewModel.pulsedID == alert.id ? 0.85 : 1)
                                }
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.deleteAlert(alert)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button {
                                        viewModel.toggleFavorite(alert)
                                    } label: {
                                        Label(
                                            store.favoriteAlerts.contains(alert.id) ? "Unfavorite" : "Favorite",
                                            systemImage: store.favoriteAlerts.contains(alert.id) ? "star.slash" : "star"
                                        )
                                    }
                                    .tint(Color("AppPrimary"))
                                }
                            }
                        }
                        .listStyle(.plain)
                        .clearScrollBackground()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    PrimaryButton(title: "Refresh Alerts") {
                        viewModel.refreshAlerts()
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
        .navigationTitle("Frost Alert History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticFeedback.lightTap()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.showSearch.toggle()
                        if !viewModel.showSearch { viewModel.searchText = "" }
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color("AppPrimary"))
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .toolbarBackground(Color("AppBackground"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $viewModel.showDetail) {
            if let alert = viewModel.selectedAlert {
                AlertDetailSheet(alert: alert, store: store)
            }
        }
    }

}

private struct AlertDetailSheet: View {
    let alert: FrostAlert
    let store: AppStorageStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        AlertCell(
                            severityTitle: alert.severity.title,
                            symbolName: alert.severity.symbolName,
                            dateText: alert.date.formatted(date: .complete, time: .standard),
                            temperatureText: store.displayTemperature(alert.temperature),
                            isFavorite: store.favoriteAlerts.contains(alert.id),
                            isHardFreeze: alert.severity == .hardFreeze
                        )
                        AppCard {
                            Text(alert.note.isEmpty
                                 ? "Review this alert to plan protection for the next cold night."
                                 : alert.note)
                                .font(.subheadline)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Alert Detail")
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
