import SwiftUI

struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            // Static 3-stop gradient — no Canvas loops, no animation, no blur.
            DepthStyle.backgroundGradient

            // Cheap depth accents (few shapes, not per-pixel pattern).
            Circle()
                .fill(Color("AppPrimary").opacity(0.10))
                .frame(width: 280, height: 280)
                .offset(x: -120, y: -220)
                .allowsHitTesting(false)

            Circle()
                .fill(Color("AppAccent").opacity(0.08))
                .frame(width: 240, height: 240)
                .offset(x: 140, y: 320)
                .allowsHitTesting(false)

            LinearGradient(
                colors: [
                    Color("AppTextPrimary").opacity(0.04),
                    Color.clear,
                    Color("AppBackground").opacity(0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}
