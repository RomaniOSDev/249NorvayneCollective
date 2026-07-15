import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case tracker
    case prepare
    case journal
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .tracker: return "Tracker"
        case .prepare: return "Prepare"
        case .journal: return "Journal"
        case .settings: return "Settings"
        }
    }

    var symbolName: String {
        switch self {
        case .tracker: return "thermometer.snowflake"
        case .prepare: return "shield.fill"
        case .journal: return "book.closed.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selection: AppTab
    @State private var pressedTab: AppTab?

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    HapticFeedback.lightTap()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.symbolName)
                            .font(.system(size: 18, weight: .semibold))
                        Text(tab.title)
                            .font(.caption2.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(
                        selection == tab ? Color("AppTextPrimary") : Color("AppTextSecondary")
                    )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .padding(.vertical, 6)
                    .background(
                        Group {
                            if selection == tab {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(DepthStyle.primaryButtonGradient)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color("AppTextPrimary").opacity(0.18), lineWidth: 1)
                                    )
                                    .shadow(color: DepthStyle.softShadowColor, radius: 4, y: 2)
                            } else {
                                Color.clear
                            }
                        }
                    )
                    .appPressScale(pressedTab == tab)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in pressedTab = tab }
                        .onEnded { _ in pressedTab = nil }
                )
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(DepthStyle.elevatedGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color("AppTextPrimary").opacity(0.16),
                                    Color("AppTextPrimary").opacity(0.04)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: DepthStyle.shadowColor, radius: 10, y: 5)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}
