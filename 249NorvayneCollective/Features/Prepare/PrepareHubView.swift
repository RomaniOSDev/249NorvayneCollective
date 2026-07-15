import SwiftUI

struct PrepareHubView: View {
    let bottomInset: CGFloat
    @EnvironmentObject private var store: AppStorageStore
    @State private var segment = 0
    @State private var showShare = false
    @State private var shareText = ""
    @State private var showSuccessBadge = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                VStack(spacing: 0) {
                    AppCard(padding: 10) {
                        Picker("Section", selection: $segment) {
                            Text("Assets").tag(0)
                            Text("Plans").tag(1)
                            Text("Tonight").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: segment) { _ in
                            HapticFeedback.lightTap()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                    Group {
                        switch segment {
                        case 0:
                            AssetsListSection(bottomInset: bottomInset)
                        case 1:
                            ProtectionPlansSection(bottomInset: bottomInset)
                        default:
                            TonightChecklistSection(
                                bottomInset: bottomInset,
                                onShare: shareNightPlan,
                                onRebuild: {
                                    store.rebuildTonightChecklist()
                                    HapticFeedback.updateAcknowledged()
                                    pulseSuccess()
                                    store.recordMeaningfulAction(itemsDelta: 1, sessionCompleted: true)
                                }
                            )
                        }
                    }
                }

                if showSuccessBadge {
                    SuccessCheckBadge()
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .navigationTitle("Prepare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        shareNightPlan()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color("AppPrimary"))
                            .frame(minWidth: 44, minHeight: 44)
                    }
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showShare) {
                ActivityShareSheet(items: [shareText])
            }
        }
        .transparentScreenChrome()
    }

    private func shareNightPlan() {
        HapticFeedback.lightTap()
        if store.tonightChecklist.isEmpty {
            store.rebuildTonightChecklist()
        }
        shareText = store.buildNightPlanShareText()
        showShare = true
        store.recordMeaningfulAction(itemsDelta: 1, sessionCompleted: false)
        pulseSuccess()
    }

    private func pulseSuccess() {
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

private struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
