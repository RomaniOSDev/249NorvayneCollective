import SwiftUI

struct AlertsInsightsContainerView: View {
    let bottomInset: CGFloat
    @State private var segment = 0

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                Picker("Section", selection: $segment) {
                    Text("Alerts").tag(0)
                    Text("Insights").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .onChange(of: segment) { _ in
                    HapticFeedback.lightTap()
                }

                Group {
                    if segment == 0 {
                        Feature2View(bottomInset: bottomInset)
                    } else {
                        Feature3View(bottomInset: bottomInset)
                    }
                }
            }
        }
    }
}
