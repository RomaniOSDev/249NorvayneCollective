import SwiftUI

// MARK: - Building blocks

struct AppCard<Content: View>: View {
    var accentBorder: Bool = false
    var padding: CGFloat = 16
    var elevated: Bool = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ElevatedSurface(accent: accentBorder, elevated: elevated))
    }
}

struct IconBadge: View {
    let systemName: String
    var tint: Color = Color("AppAccent")
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color("AppBackground").opacity(0.35),
                            Color("AppSurface").opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: DepthStyle.softShadowColor, radius: 3, y: 2)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [tint.opacity(0.7), tint.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: size, height: size)

            Image(systemName: systemName)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
    }
}

struct StatusPill: View {
    let text: String
    var isWarning: Bool = false

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(Color("AppTextPrimary"))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isWarning
                            ? [Color("AppAccent").opacity(0.38), Color("AppAccent").opacity(0.18)]
                            : [Color("AppPrimary").opacity(0.38), Color("AppPrimary").opacity(0.18)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(isWarning ? Color("AppAccent").opacity(0.8) : Color("AppPrimary").opacity(0.8), lineWidth: 1)
            )
    }
}

struct MetricChip: View {
    let title: String
    let value: String
    var emphasize: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(1)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(emphasize ? Color("AppAccent") : Color("AppTextPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DepthStyle.chipRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color("AppBackground").opacity(0.55),
                            Color("AppSurface").opacity(0.65)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DepthStyle.chipRadius, style: .continuous)
                        .stroke(
                            emphasize ? Color("AppAccent").opacity(0.4) : Color("AppTextPrimary").opacity(0.08),
                            lineWidth: 1
                        )
                )
        )
    }
}

struct SectionHeaderView: View {
    let title: String
    var subtitle: String? = nil
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            if let trailing {
                Text(trailing)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppAccent"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.lightTap()
            action()
        } label: {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(DepthStyle.elevatedGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color("AppAccent"), Color("AppPrimary").opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )
                .appDepth()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feature cells

struct AssetCell: View {
    let name: String
    let kindTitle: String
    let thresholdText: String
    let symbolName: String
    var isAtRisk: Bool = false
    var notes: String? = nil

    var body: some View {
        HStack(spacing: 14) {
            IconBadge(
                systemName: symbolName,
                tint: isAtRisk ? Color("AppAccent") : Color("AppPrimary")
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(name)
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if isAtRisk {
                        StatusPill(text: "At risk", isWarning: true)
                    }
                }
                Text(kindTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
                Text("Threshold \(thresholdText)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("AppPrimary"))
                if let notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .padding(14)
        .background(cellBackground(isAtRisk))
    }
}

struct AlertCell: View {
    let severityTitle: String
    let symbolName: String
    let dateText: String
    let temperatureText: String
    var isFavorite: Bool = false
    var isHardFreeze: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            IconBadge(
                systemName: symbolName,
                tint: isHardFreeze ? Color("AppAccent") : Color("AppPrimary")
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(severityTitle)
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 4)
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(Color("AppAccent"))
                            .font(.caption)
                    }
                }
                Text(dateText)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                HStack(spacing: 8) {
                    StatusPill(text: temperatureText, isWarning: isHardFreeze)
                    StatusPill(text: isHardFreeze ? "Hard freeze" : "Light frost", isWarning: isHardFreeze)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .padding(14)
        .background(cellBackground(isHardFreeze))
    }
}

struct PlanCell: View {
    let title: String
    let stepCount: Int
    var kindTitle: String? = nil
    var isTemplate: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            IconBadge(systemName: "checklist", tint: Color("AppPrimary"))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 8) {
                    StatusPill(text: "\(stepCount) steps")
                    if isTemplate {
                        StatusPill(text: "Template")
                    }
                    if let kindTitle {
                        StatusPill(text: kindTitle, isWarning: false)
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .padding(14)
        .background(cellBackground(false))
    }
}

struct ChecklistCell: View {
    let title: String
    let isDone: Bool
    var isPulsed: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(isDone ? Color("AppAccent") : Color("AppTextSecondary").opacity(0.5), lineWidth: 2)
                    .frame(width: 28, height: 28)
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppAccent"))
                }
            }
            .frame(width: 44, height: 44)

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isDone ? Color("AppTextSecondary") : Color("AppTextPrimary"))
                .strikethrough(isDone, color: Color("AppTextSecondary"))
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            ElevatedSurface(accent: isDone || isPulsed, elevated: false)
        )
    }
}

struct JournalCell: View {
    let dateText: String
    let cityName: String
    let hadFrost: Bool
    var temperatureText: String? = nil
    var protectedText: String? = nil
    var notes: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                IconBadge(
                    systemName: hadFrost ? "snowflake" : "sun.max.fill",
                    tint: hadFrost ? Color("AppAccent") : Color("AppPrimary")
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateText)
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text(cityName)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(2)
                }
                Spacer()
                StatusPill(text: hadFrost ? "Frost" : "Clear", isWarning: hadFrost)
            }

            if let temperatureText {
                Label(temperatureText, systemImage: "thermometer.medium")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))
            }

            if let protectedText, !protectedText.isEmpty {
                Label(protectedText, systemImage: "shield.fill")
                    .font(.caption)
                    .foregroundStyle(Color("AppAccent"))
                    .lineLimit(2)
            }

            if let notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(3)
            }
        }
        .padding(14)
        .background(cellBackground(hadFrost))
    }
}

struct HistoryCell: View {
    let dateText: String
    let minTempText: String
    let durationText: String

    var body: some View {
        HStack(spacing: 14) {
            IconBadge(systemName: "calendar", tint: Color("AppAccent"))
            VStack(alignment: .leading, spacing: 6) {
                Text(dateText)
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(minTempText)
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                StatusPill(text: durationText, isWarning: true)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .padding(14)
        .background(cellBackground(false))
    }
}

struct AchievementCell: View {
    let title: String
    let detail: String
    let symbolName: String
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color("AppBackground").opacity(0.5))
                    .frame(width: 56, height: 56)
                Circle()
                    .stroke(unlocked ? Color("AppAccent") : Color("AppTextSecondary").opacity(0.35), lineWidth: 2)
                    .frame(width: 56, height: 56)
                Image(systemName: symbolName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(unlocked ? Color("AppAccent") : Color("AppTextSecondary"))
            }

            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            Text(detail)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.7)

            StatusPill(text: unlocked ? "Unlocked" : "Locked", isWarning: unlocked)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(ElevatedSurface(accent: unlocked, elevated: unlocked))
        .opacity(unlocked ? 1 : 0.72)
    }
}

struct SettingsRowCell: View {
    let title: String
    let systemImage: String
    var value: String? = nil
    var isDestructive: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(
                systemName: systemImage,
                tint: isDestructive ? Color.red.opacity(0.9) : Color("AppPrimary"),
                size: 40
            )
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(isDestructive ? Color.red.opacity(0.95) : Color("AppTextPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            if let value {
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}

struct RiskHeroCard: View {
    let cityLabel: String
    let dayText: String
    let nightText: String
    let dayRisky: Bool
    let nightRisky: Bool
    let assetsLine: String

    var body: some View {
        AppCard(accentBorder: nightRisky || dayRisky) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Live Frost Outlook")
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text(cityLabel)
                            .font(.caption)
                            .foregroundStyle(Color("AppAccent"))
                            .lineLimit(2)
                    }
                    Spacer()
                    IconBadge(
                        systemName: nightRisky ? "exclamationmark.triangle.fill" : "checkmark.shield.fill",
                        tint: nightRisky ? Color("AppAccent") : Color("AppPrimary")
                    )
                }

                HStack(spacing: 10) {
                    MetricChip(title: "Day low", value: dayText, emphasize: dayRisky)
                    MetricChip(title: "Night low", value: nightText, emphasize: nightRisky)
                }

                Text(assetsLine)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(3)
            }
        }
    }
}

private func cellBackground(_ emphasize: Bool) -> some View {
    // Lists: gradient + stroke only (no drop shadow) to keep scroll buttery.
    ElevatedSurface(accent: emphasize, elevated: false)
}
