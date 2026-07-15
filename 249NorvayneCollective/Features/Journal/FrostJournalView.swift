import SwiftUI

struct FrostJournalView: View {
    let bottomInset: CGFloat
    @EnvironmentObject private var store: AppStorageStore
    @State private var segment = 0
    @State private var showComposer = false
    @State private var hadFrost = true
    @State private var minTempText = ""
    @State private var notes = ""
    @State private var selectedSavedNames: Set<String> = []
    @State private var tempError: String?
    @State private var shakeTemp = 0
    @State private var showSuccessBadge = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                VStack(spacing: 0) {
                    AppCard(padding: 10) {
                        Picker("Section", selection: $segment) {
                            Text("Journal").tag(0)
                            Text("Alerts").tag(1)
                            Text("Insights").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: segment) { _ in
                            HapticFeedback.lightTap()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Group {
                        switch segment {
                        case 0:
                            journalContent
                        case 1:
                            Feature2View(bottomInset: bottomInset, usesOwnNavigation: false)
                        default:
                            Feature3View(bottomInset: bottomInset, usesOwnNavigation: false)
                        }
                    }
                }

                if showSuccessBadge {
                    SuccessCheckBadge()
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(segment == 0 ? "Frost Journal" : (segment == 1 ? "Alert History" : "Pattern Insights"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                }
                if segment == 0 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            HapticFeedback.lightTap()
                            openComposer()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color("AppPrimary"))
                                .frame(minWidth: 44, minHeight: 44)
                        }
                    }
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showComposer) {
                composerSheet
            }
        }
        .transparentScreenChrome()
    }

    private var journalContent: some View {
        Group {
            if store.frostJournal.isEmpty {
                ScrollView {
                    VStack(spacing: 18) {
                        SectionHeaderView(
                            title: "Night Log",
                            subtitle: "Record frost outcomes and what you protected"
                        )
                        EmptyStateView(
                            symbolName: "book.closed",
                            title: "No journal entries yet",
                            message: "Log whether frost hit and which assets you protected."
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
                .clearScrollBackground()
            } else {
                List {
                    Section {
                        SectionHeaderView(
                            title: "Night Log",
                            subtitle: "Newest entries first",
                            trailing: "\(store.frostJournal.count)"
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }

                    ForEach(store.frostJournal.sorted { $0.date > $1.date }) { entry in
                        JournalCell(
                            dateText: entry.date.formatted(date: .abbreviated, time: .omitted),
                            cityName: entry.cityName,
                            hadFrost: entry.hadFrost,
                            temperatureText: entry.minTemperature.map { "Low \(store.displayTemperature($0))" },
                            protectedText: entry.savedAssetNames.isEmpty
                                ? nil
                                : "Protected: " + entry.savedAssetNames.joined(separator: ", "),
                            notes: entry.notes.isEmpty ? nil : entry.notes
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticFeedback.lightTap()
                                store.frostJournal.removeAll { $0.id == entry.id }
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
            PrimaryButton(title: "Log Frost Night") {
                openComposer()
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

    private var composerSheet: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        AppCard {
                            Toggle("Frost occurred", isOn: $hadFrost)
                                .tint(Color("AppAccent"))
                                .foregroundStyle(Color("AppTextPrimary"))
                        }

                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Observed low (°C)")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                TextField("e.g. -2.5", text: $minTempText)
                                    .keyboardType(.decimalPad)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .modifier(ShakeEffect(animatableData: CGFloat(shakeTemp)))
                                if let tempError {
                                    Text(tempError)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }

                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Assets that made it through")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color("AppTextPrimary"))

                                ForEach(store.protectableAssets) { asset in
                                    Button {
                                        HapticFeedback.lightTap()
                                        if selectedSavedNames.contains(asset.name) {
                                            selectedSavedNames.remove(asset.name)
                                        } else {
                                            selectedSavedNames.insert(asset.name)
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            IconBadge(
                                                systemName: selectedSavedNames.contains(asset.name)
                                                ? "checkmark.circle.fill"
                                                : asset.kind.symbolName,
                                                tint: selectedSavedNames.contains(asset.name)
                                                ? Color("AppAccent")
                                                : Color("AppPrimary"),
                                                size: 36
                                            )
                                            Text(asset.name)
                                                .foregroundStyle(Color("AppTextPrimary"))
                                            Spacer()
                                        }
                                        .padding(8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color("AppBackground").opacity(0.4))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        AppCard {
                            TextField("Notes", text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                                .foregroundStyle(Color("AppTextPrimary"))
                        }

                        PrimaryButton(title: "Save Entry") {
                            saveEntry()
                        }
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        HapticFeedback.lightTap()
                        showComposer = false
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func openComposer() {
        hadFrost = (store.lastNightMinC ?? 1) <= 0
        minTempText = store.lastNightMinC.map { String(format: "%.1f", $0) } ?? ""
        notes = ""
        selectedSavedNames = Set(store.assetsAtRisk(forNightMin: store.lastNightMinC, dayMin: store.lastDayMinC).map(\.name))
        tempError = nil
        showComposer = true
    }

    private func saveEntry() {
        var minTemp: Double?
        let trimmed = minTempText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            guard let value = Double(trimmed.replacingOccurrences(of: ",", with: ".")) else {
                tempError = "Enter a valid temperature number."
                shakeTemp += 1
                HapticFeedback.warning()
                return
            }
            minTemp = value
        }

        HapticFeedback.mediumTap()
        let entry = FrostJournalEntry(
            cityName: store.selectedCity?.displayName ?? "Unspecified area",
            hadFrost: hadFrost,
            minTemperature: minTemp,
            savedAssetNames: Array(selectedSavedNames).sorted(),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        store.frostJournal.insert(entry, at: 0)
        store.recordMeaningfulAction(itemsDelta: 1, sessionCompleted: true)
        HapticFeedback.success()
        showComposer = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showSuccessBadge = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showSuccessBadge = false
            }
        }
    }
}
