import SwiftUI

struct AssetsListSection: View {
    let bottomInset: CGFloat
    @EnvironmentObject private var store: AppStorageStore
    @State private var showEditor = false
    @State private var draftName = ""
    @State private var draftKind: AssetKind = .custom
    @State private var draftThreshold: Double = 0
    @State private var draftNotes = ""
    @State private var editingAsset: ProtectableAsset?
    @State private var nameError: String?
    @State private var shakeName = 0

    var body: some View {
        Group {
            if store.protectableAssets.isEmpty {
                ScrollView {
                    VStack(spacing: 18) {
                        SectionHeaderView(
                            title: "Protected Assets",
                            subtitle: "Track what needs cover when temperatures drop"
                        )
                        EmptyStateView(
                            symbolName: "leaf.fill",
                            title: "No assets yet",
                            message: "Add roses, taps, greenhouses, or pipes with personal frost thresholds."
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
                            title: "Protected Assets",
                            subtitle: "Tap to edit · swipe to delete",
                            trailing: "\(store.protectableAssets.count)"
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }

                    ForEach(store.protectableAssets) { asset in
                        Button {
                            HapticFeedback.lightTap()
                            beginEdit(asset)
                        } label: {
                            AssetCell(
                                name: asset.name,
                                kindTitle: asset.kind.title,
                                thresholdText: store.displayTemperature(asset.frostThresholdC),
                                symbolName: asset.kind.symbolName,
                                isAtRisk: isAtRisk(asset),
                                notes: asset.notes.isEmpty ? nil : asset.notes
                            )
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                delete(asset)
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
            PrimaryButton(title: "Add Asset") {
                beginCreate()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, bottomInset)
            .background(tabBarButtonBackdrop)
        }
        .sheet(isPresented: $showEditor) {
            assetEditor
        }
    }

    private var tabBarButtonBackdrop: some View {
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
    }

    private func isAtRisk(_ asset: ProtectableAsset) -> Bool {
        store.assetsAtRisk(forNightMin: store.lastNightMinC, dayMin: store.lastDayMinC)
            .contains(where: { $0.id == asset.id })
    }

    private var assetEditor: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        AppCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Asset details")
                                    .font(.headline)
                                    .foregroundStyle(Color("AppTextPrimary"))

                                TextField("Asset name", text: $draftName)
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color("AppBackground").opacity(0.5)))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .modifier(ShakeEffect(animatableData: CGFloat(shakeName)))

                                if let nameError {
                                    Text(nameError)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }

                                Picker("Type", selection: $draftKind) {
                                    ForEach(AssetKind.allCases) { kind in
                                        Label(kind.title, systemImage: kind.symbolName).tag(kind)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Color("AppPrimary"))
                                .onChange(of: draftKind) { newValue in
                                    if editingAsset == nil {
                                        draftThreshold = newValue.defaultThresholdC
                                    }
                                }
                            }
                        }

                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Frost threshold: \(store.displayTemperature(draftThreshold))")
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Slider(value: $draftThreshold, in: -15...8, step: 0.5)
                                    .tint(Color("AppAccent"))
                                Text("Alert when forecast dips to this temperature or lower.")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                        }

                        AppCard {
                            TextField("Notes (optional)", text: $draftNotes, axis: .vertical)
                                .lineLimit(3...5)
                                .foregroundStyle(Color("AppTextPrimary"))
                        }

                        PrimaryButton(title: "Save Asset") {
                            saveAsset()
                        }
                    }
                    .padding(20)
                }
                .clearScrollBackground()
            }
            .navigationTitle(editingAsset == nil ? "New Asset" : "Edit Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        HapticFeedback.lightTap()
                        showEditor = false
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func beginCreate() {
        HapticFeedback.lightTap()
        editingAsset = nil
        draftName = ""
        draftKind = .roses
        draftThreshold = AssetKind.roses.defaultThresholdC
        draftNotes = ""
        nameError = nil
        showEditor = true
    }

    private func beginEdit(_ asset: ProtectableAsset) {
        editingAsset = asset
        draftName = asset.name
        draftKind = asset.kind
        draftThreshold = asset.frostThresholdC
        draftNotes = asset.notes
        nameError = nil
        showEditor = true
    }

    private func saveAsset() {
        let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            nameError = "Enter a name for this asset."
            shakeName += 1
            HapticFeedback.warning()
            return
        }
        HapticFeedback.mediumTap()
        if var existing = editingAsset {
            existing.name = name
            existing.kind = draftKind
            existing.frostThresholdC = draftThreshold
            existing.notes = draftNotes
            if let index = store.protectableAssets.firstIndex(where: { $0.id == existing.id }) {
                store.protectableAssets[index] = existing
            }
        } else {
            store.protectableAssets.append(
                ProtectableAsset(name: name, kind: draftKind, frostThresholdC: draftThreshold, notes: draftNotes)
            )
            store.recordMeaningfulAction(itemsDelta: 1, sessionCompleted: false)
        }
        HapticFeedback.success()
        showEditor = false
        store.rebuildTonightChecklist()
    }

    private func delete(_ asset: ProtectableAsset) {
        HapticFeedback.lightTap()
        store.protectableAssets.removeAll { $0.id == asset.id }
        store.rebuildTonightChecklist()
    }
}
