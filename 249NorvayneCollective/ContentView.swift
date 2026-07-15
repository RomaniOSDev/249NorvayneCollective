import SwiftUI

struct ContentView: View {
    @ObservedObject private var store = AppStorageStore.shared

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .environmentObject(store)
        .preferredColorScheme(.dark)
        .onAppear {
            store.evaluateAchievements()
        }
    }
}

#Preview {
    ContentView()
}
