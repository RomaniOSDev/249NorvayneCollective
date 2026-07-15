import Foundation

enum FrostSeverity: String, Codable, CaseIterable, Identifiable {
    case lightFrost
    case hardFreeze

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lightFrost: return "Light Frost"
        case .hardFreeze: return "Hard Freeze"
        }
    }

    var symbolName: String {
        switch self {
        case .lightFrost: return "snowflake"
        case .hardFreeze: return "thermometer.snowflake"
        }
    }
}

struct FrostAlert: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let temperature: Double
    let severity: FrostSeverity
    var note: String

    init(
        id: UUID = UUID(),
        date: Date,
        temperature: Double,
        severity: FrostSeverity,
        note: String = ""
    ) {
        self.id = id
        self.date = date
        self.temperature = temperature
        self.severity = severity
        self.note = note
    }
}

struct FrostEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let minTemperature: Double
    let durationHours: Double
    var summary: String

    init(
        id: UUID = UUID(),
        date: Date,
        minTemperature: Double,
        durationHours: Double,
        summary: String = ""
    ) {
        self.id = id
        self.date = date
        self.minTemperature = minTemperature
        self.durationHours = durationHours
        self.summary = summary
    }
}

struct ForecastPoint: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let temperature: Double
    let isFrostRisk: Bool

    init(id: UUID = UUID(), date: Date, temperature: Double, isFrostRisk: Bool) {
        self.id = id
        self.date = date
        self.temperature = temperature
        self.isFrostRisk = isFrostRisk
    }
}

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbolName: String
    let isUnlocked: (AppStorageStore) -> Bool
}

enum AchievementCatalog {
    static let all: [AchievementDefinition] = [
        AchievementDefinition(
            id: "first_check",
            title: "First Check",
            detail: "You checked the frost tracker.",
            symbolName: "checkmark.circle.fill",
            isUnlocked: { $0.itemsCreated >= 1 }
        ),
        AchievementDefinition(
            id: "daily_monitor",
            title: "Daily Monitor",
            detail: "Monitored frost conditions for a full week.",
            symbolName: "calendar.badge.checkmark",
            isUnlocked: { $0.streakDays >= 7 }
        ),
        AchievementDefinition(
            id: "alert_setup",
            title: "Alert Setup",
            detail: "Set up your first custom frost alert.",
            symbolName: "bell.badge.fill",
            isUnlocked: { $0.itemsCreated >= 3 }
        ),
        AchievementDefinition(
            id: "cold_protector",
            title: "Cold Protector",
            detail: "Received alerts for five consecutive days with frost risk.",
            symbolName: "shield.fill",
            isUnlocked: { $0.totalSessionsCompleted >= 5 }
        ),
        AchievementDefinition(
            id: "plus_10_monitors",
            title: "+10 Monitors",
            detail: "+10 sessions monitoring frost conditions completed.",
            symbolName: "gauge",
            isUnlocked: { $0.totalSessionsCompleted >= 10 }
        ),
        AchievementDefinition(
            id: "getting_going",
            title: "Getting Going",
            detail: "Reached 10 items.",
            symbolName: "leaf.fill",
            isUnlocked: { $0.itemsCreated >= 10 }
        ),
        AchievementDefinition(
            id: "power_user",
            title: "Power User",
            detail: "Reached 50 items.",
            symbolName: "bolt.fill",
            isUnlocked: { $0.itemsCreated >= 50 }
        ),
        AchievementDefinition(
            id: "active_user",
            title: "Active User",
            detail: "Completed 10 sessions.",
            symbolName: "flame.fill",
            isUnlocked: { $0.totalSessionsCompleted >= 10 }
        )
    ]
}

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}
