import Foundation
import Combine

final class AppStorageStore: ObservableObject {
    static let shared = AppStorageStore()

    private let defaults: UserDefaults
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let totalSessionsCompleted = "totalSessionsCompleted"
        static let totalMinutesUsed = "totalMinutesUsed"
        static let streakDays = "streakDays"
        static let lastActivityDate = "lastActivityDate"
        static let achievementsUnlocked = "achievementsUnlocked"
        static let itemsCreated = "itemsCreated"
        static let frostForecasts = "frostForecasts"
        static let lastViewedDate = "lastViewedDate"
        static let preferredTemperatureUnit = "preferredTemperatureUnit"
        static let frostAlerts = "frostAlerts"
        static let lastSyncedAt = "lastSyncedAt"
        static let favoriteAlerts = "favoriteAlerts"
        static let frostHistory = "frostHistory"
        static let selectedTimeframe = "selectedTimeframe"
        static let forecastPoints = "forecastPoints"
        static let sessionStartDate = "sessionStartDate"
        static let selectedCity = "selectedCity"
        static let protectableAssets = "protectableAssets"
        static let protectionPlans = "protectionPlans"
        static let tonightChecklist = "tonightChecklist"
        static let frostJournal = "frostJournal"
        static let lastDayMinC = "lastDayMinC"
        static let lastNightMinC = "lastNightMinC"
        static let hasSeededPreparation = "hasSeededPreparation"
    }

    @Published var hasSeenOnboarding: Bool {
        didSet { defaults.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding) }
    }

    @Published var totalSessionsCompleted: Int {
        didSet { defaults.set(totalSessionsCompleted, forKey: Keys.totalSessionsCompleted) }
    }

    @Published var totalMinutesUsed: Int {
        didSet { defaults.set(totalMinutesUsed, forKey: Keys.totalMinutesUsed) }
    }

    @Published var streakDays: Int {
        didSet { defaults.set(streakDays, forKey: Keys.streakDays) }
    }

    @Published var lastActivityDate: Date? {
        didSet {
            if let lastActivityDate {
                defaults.set(lastActivityDate.timeIntervalSince1970, forKey: Keys.lastActivityDate)
            } else {
                defaults.removeObject(forKey: Keys.lastActivityDate)
            }
        }
    }

    @Published var achievementsUnlocked: [String: Date] {
        didSet { Self.saveCodable(achievementsUnlocked, key: Keys.achievementsUnlocked, defaults: defaults) }
    }

    @Published var itemsCreated: Int {
        didSet { defaults.set(itemsCreated, forKey: Keys.itemsCreated) }
    }

    @Published var frostForecasts: [TimeInterval: Bool] {
        didSet { Self.saveCodable(frostForecasts, key: Keys.frostForecasts, defaults: defaults) }
    }

    @Published var lastViewedDate: Date {
        didSet { defaults.set(lastViewedDate.timeIntervalSince1970, forKey: Keys.lastViewedDate) }
    }

    @Published var preferredTemperatureUnit: String {
        didSet { defaults.set(preferredTemperatureUnit, forKey: Keys.preferredTemperatureUnit) }
    }

    @Published var frostAlerts: [FrostAlert] {
        didSet { Self.saveCodable(frostAlerts, key: Keys.frostAlerts, defaults: defaults) }
    }

    @Published var lastSyncedAt: Date? {
        didSet {
            if let lastSyncedAt {
                defaults.set(lastSyncedAt.timeIntervalSince1970, forKey: Keys.lastSyncedAt)
            } else {
                defaults.removeObject(forKey: Keys.lastSyncedAt)
            }
        }
    }

    @Published var favoriteAlerts: [UUID] {
        didSet { Self.saveCodable(favoriteAlerts.map(\.uuidString), key: Keys.favoriteAlerts, defaults: defaults) }
    }

    @Published var frostHistory: [FrostEntry] {
        didSet { Self.saveCodable(frostHistory, key: Keys.frostHistory, defaults: defaults) }
    }

    @Published var selectedTimeframe: String {
        didSet { defaults.set(selectedTimeframe, forKey: Keys.selectedTimeframe) }
    }

    @Published var forecastPoints: [ForecastPointDTO] {
        didSet { Self.saveCodable(forecastPoints, key: Keys.forecastPoints, defaults: defaults) }
    }

    @Published var selectedCity: SavedCity? {
        didSet {
            if let selectedCity {
                Self.saveCodable(selectedCity, key: Keys.selectedCity, defaults: defaults)
            } else {
                defaults.removeObject(forKey: Keys.selectedCity)
            }
        }
    }

    @Published var protectableAssets: [ProtectableAsset] {
        didSet { Self.saveCodable(protectableAssets, key: Keys.protectableAssets, defaults: defaults) }
    }

    @Published var protectionPlans: [ProtectionPlan] {
        didSet { Self.saveCodable(protectionPlans, key: Keys.protectionPlans, defaults: defaults) }
    }

    @Published var tonightChecklist: [TonightChecklistItem] {
        didSet { Self.saveCodable(tonightChecklist, key: Keys.tonightChecklist, defaults: defaults) }
    }

    @Published var frostJournal: [FrostJournalEntry] {
        didSet { Self.saveCodable(frostJournal, key: Keys.frostJournal, defaults: defaults) }
    }

    @Published var lastDayMinC: Double? {
        didSet {
            if let lastDayMinC {
                defaults.set(lastDayMinC, forKey: Keys.lastDayMinC)
            } else {
                defaults.removeObject(forKey: Keys.lastDayMinC)
            }
        }
    }

    @Published var lastNightMinC: Double? {
        didSet {
            if let lastNightMinC {
                defaults.set(lastNightMinC, forKey: Keys.lastNightMinC)
            } else {
                defaults.removeObject(forKey: Keys.lastNightMinC)
            }
        }
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let loadedAchievements = Self.loadCodable([String: Date].self, key: Keys.achievementsUnlocked, defaults: defaults) ?? [:]
        let loadedForecasts = Self.loadCodable([TimeInterval: Bool].self, key: Keys.frostForecasts, defaults: defaults) ?? [:]
        let loadedAlerts = Self.loadCodable([FrostAlert].self, key: Keys.frostAlerts, defaults: defaults) ?? []
        let loadedHistory = Self.loadCodable([FrostEntry].self, key: Keys.frostHistory, defaults: defaults) ?? []
        let loadedPoints = Self.loadCodable([ForecastPointDTO].self, key: Keys.forecastPoints, defaults: defaults) ?? []
        let favoriteStrings = Self.loadCodable([String].self, key: Keys.favoriteAlerts, defaults: defaults) ?? []
        let loadedCity = Self.loadCodable(SavedCity.self, key: Keys.selectedCity, defaults: defaults)
        let loadedAssets = Self.loadCodable([ProtectableAsset].self, key: Keys.protectableAssets, defaults: defaults) ?? []
        let loadedPlans = Self.loadCodable([ProtectionPlan].self, key: Keys.protectionPlans, defaults: defaults) ?? []
        let loadedChecklist = Self.loadCodable([TonightChecklistItem].self, key: Keys.tonightChecklist, defaults: defaults) ?? []
        let loadedJournal = Self.loadCodable([FrostJournalEntry].self, key: Keys.frostJournal, defaults: defaults) ?? []

        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        totalSessionsCompleted = defaults.integer(forKey: Keys.totalSessionsCompleted)
        totalMinutesUsed = defaults.integer(forKey: Keys.totalMinutesUsed)
        streakDays = defaults.integer(forKey: Keys.streakDays)
        itemsCreated = defaults.integer(forKey: Keys.itemsCreated)
        preferredTemperatureUnit = defaults.string(forKey: Keys.preferredTemperatureUnit) ?? "C"
        selectedTimeframe = defaults.string(forKey: Keys.selectedTimeframe) ?? "Daily"

        if defaults.object(forKey: Keys.lastViewedDate) != nil {
            lastViewedDate = Date(timeIntervalSince1970: defaults.double(forKey: Keys.lastViewedDate))
        } else {
            lastViewedDate = Date()
        }

        if defaults.object(forKey: Keys.lastActivityDate) != nil {
            lastActivityDate = Date(timeIntervalSince1970: defaults.double(forKey: Keys.lastActivityDate))
        } else {
            lastActivityDate = nil
        }

        if defaults.object(forKey: Keys.lastSyncedAt) != nil {
            lastSyncedAt = Date(timeIntervalSince1970: defaults.double(forKey: Keys.lastSyncedAt))
        } else {
            lastSyncedAt = nil
        }

        if defaults.object(forKey: Keys.lastDayMinC) != nil {
            lastDayMinC = defaults.double(forKey: Keys.lastDayMinC)
        } else {
            lastDayMinC = nil
        }

        if defaults.object(forKey: Keys.lastNightMinC) != nil {
            lastNightMinC = defaults.double(forKey: Keys.lastNightMinC)
        } else {
            lastNightMinC = nil
        }

        achievementsUnlocked = loadedAchievements
        frostForecasts = loadedForecasts
        frostAlerts = loadedAlerts
        frostHistory = loadedHistory
        forecastPoints = loadedPoints
        favoriteAlerts = favoriteStrings.compactMap(UUID.init(uuidString:))
        selectedCity = loadedCity
        protectableAssets = loadedAssets
        protectionPlans = loadedPlans
        tonightChecklist = loadedChecklist
        frostJournal = loadedJournal

        if defaults.object(forKey: Keys.sessionStartDate) == nil {
            defaults.set(Date().timeIntervalSince1970, forKey: Keys.sessionStartDate)
        }

        seedPreparationDataIfNeeded()
    }

    private func seedPreparationDataIfNeeded() {
        let seeded = defaults.bool(forKey: Keys.hasSeededPreparation)
        if !seeded || protectableAssets.isEmpty {
            if protectableAssets.isEmpty {
                protectableAssets = DefaultAssetsFactory.starterAssets()
            }
        }
        if protectionPlans.isEmpty {
            protectionPlans = ProtectionPlanCatalog.defaults
        }
        defaults.set(true, forKey: Keys.hasSeededPreparation)
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
    }

    func recordMeaningfulAction(itemsDelta: Int = 0, sessionCompleted: Bool = false) {
        if itemsDelta > 0 {
            itemsCreated += itemsDelta
        }
        if sessionCompleted {
            totalSessionsCompleted += 1
        }
        updateStreak()
        accumulateUsageMinutes()
        evaluateAchievements()
    }

    func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let last = lastActivityDate else {
            streakDays = max(streakDays, 1)
            lastActivityDate = today
            return
        }

        let lastDay = calendar.startOfDay(for: last)
        if lastDay == today {
            if streakDays == 0 { streakDays = 1 }
            return
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), lastDay == yesterday {
            streakDays += 1
        } else {
            streakDays = 1
        }
        lastActivityDate = today
    }

    func accumulateUsageMinutes() {
        let start = Date(timeIntervalSince1970: defaults.double(forKey: Keys.sessionStartDate))
        let elapsed = max(0, Int(Date().timeIntervalSince(start) / 60))
        if elapsed > 0 {
            totalMinutesUsed += elapsed
            defaults.set(Date().timeIntervalSince1970, forKey: Keys.sessionStartDate)
        }
    }

    @discardableResult
    func evaluateAchievements() -> [AchievementDefinition] {
        var newly: [AchievementDefinition] = []
        for achievement in AchievementCatalog.all {
            if achievementsUnlocked[achievement.id] == nil, achievement.isUnlocked(self) {
                achievementsUnlocked[achievement.id] = Date()
                newly.append(achievement)
                NotificationCenter.default.post(
                    name: .achievementUnlocked,
                    object: nil,
                    userInfo: ["id": achievement.id, "title": achievement.title]
                )
            }
        }
        return newly
    }

    var currentDayNightRisk: DayNightRisk? {
        guard let day = lastDayMinC, let night = lastNightMinC else { return nil }
        let threatened = protectableAssets
            .filter { night <= $0.frostThresholdC || day <= $0.frostThresholdC }
            .sorted { $0.frostThresholdC > $1.frostThresholdC }
        return DayNightRisk(
            dayMinC: day,
            nightMinC: night,
            dayFrost: day <= 0,
            nightFrost: night <= 0,
            lowestAssetRiskName: threatened.first?.name
        )
    }

    func assetsAtRisk(forNightMin nightMin: Double?, dayMin: Double?) -> [ProtectableAsset] {
        let night = nightMin ?? lastNightMinC ?? 99
        let day = dayMin ?? lastDayMinC ?? 99
        return protectableAssets.filter { night <= $0.frostThresholdC || day <= $0.frostThresholdC }
    }

    func rebuildTonightChecklist() {
        let atRisk = assetsAtRisk(forNightMin: lastNightMinC, dayMin: lastDayMinC)
        var items: [TonightChecklistItem] = []

        if lastNightMinC != nil || lastDayMinC != nil {
            let nightText = lastNightMinC.map { displayTemperature($0) } ?? "—"
            items.append(
                TonightChecklistItem(
                    title: "Review tonight low: \(nightText)",
                    isDone: false
                )
            )
        }

        for asset in atRisk {
            items.append(
                TonightChecklistItem(
                    title: "Protect \(asset.name) (threshold \(displayTemperature(asset.frostThresholdC)))",
                    relatedAssetID: asset.id
                )
            )
            if let plan = protectionPlans.first(where: { $0.linkedKind == asset.kind }) {
                for step in plan.steps.prefix(2) {
                    items.append(
                        TonightChecklistItem(
                            title: "\(asset.name): \(step)",
                            relatedAssetID: asset.id,
                            relatedPlanID: plan.id
                        )
                    )
                }
            }
        }

        if items.isEmpty {
            items = [
                TonightChecklistItem(title: "Confirm city forecast is up to date"),
                TonightChecklistItem(title: "Walk outdoor assets before dusk"),
                TonightChecklistItem(title: "Stage covers and insulation nearby")
            ]
        }

        tonightChecklist = items
    }

    func buildNightPlanShareText() -> String {
        let city = selectedCity?.displayName ?? "Selected area"
        let night = lastNightMinC.map { displayTemperature($0) } ?? "n/a"
        let day = lastDayMinC.map { displayTemperature($0) } ?? "n/a"
        let riskAssets = assetsAtRisk(forNightMin: lastNightMinC, dayMin: lastDayMinC)

        var lines: [String] = [
            "Frost Night Plan",
            "Location: \(city)",
            "Daytime low: \(day)",
            "Tonight low: \(night)",
            ""
        ]

        if riskAssets.isEmpty {
            lines.append("No assets currently below their personal frost thresholds.")
        } else {
            lines.append("Assets to protect:")
            for asset in riskAssets {
                lines.append("• \(asset.name) (threshold \(displayTemperature(asset.frostThresholdC)))")
            }
        }

        lines.append("")
        lines.append("Tonight checklist:")
        if tonightChecklist.isEmpty {
            lines.append("• Rebuild checklist from Prepare tab")
        } else {
            for item in tonightChecklist {
                let mark = item.isDone ? "[x]" : "[ ]"
                lines.append("\(mark) \(item.title)")
            }
        }

        lines.append("")
        lines.append("Generated locally on device.")
        return lines.joined(separator: "\n")
    }

    func resetAllData() {
        let domain = Bundle.main.bundleIdentifier ?? ""
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()

        hasSeenOnboarding = false
        totalSessionsCompleted = 0
        totalMinutesUsed = 0
        streakDays = 0
        lastActivityDate = nil
        achievementsUnlocked = [:]
        itemsCreated = 0
        frostForecasts = [:]
        lastViewedDate = Date()
        preferredTemperatureUnit = "C"
        frostAlerts = []
        lastSyncedAt = nil
        favoriteAlerts = []
        frostHistory = []
        selectedTimeframe = "Daily"
        forecastPoints = []
        selectedCity = nil
        protectableAssets = DefaultAssetsFactory.starterAssets()
        protectionPlans = ProtectionPlanCatalog.defaults
        tonightChecklist = []
        frostJournal = []
        lastDayMinC = nil
        lastNightMinC = nil
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.sessionStartDate)
        defaults.set(true, forKey: Keys.hasSeededPreparation)

        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    func displayTemperature(_ celsius: Double) -> String {
        if preferredTemperatureUnit == "F" {
            let f = celsius * 9.0 / 5.0 + 32.0
            return String(format: "%.1f°F", f)
        }
        return String(format: "%.1f°C", celsius)
    }

    private static func saveCodable<T: Encodable>(_ value: T, key: String, defaults: UserDefaults) {
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private static func loadCodable<T: Decodable>(_ type: T.Type, key: String, defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(type, from: data)
    }
}

struct ForecastPointDTO: Codable, Equatable, Identifiable {
    var id: UUID
    var date: Date
    var temperature: Double
    var isFrostRisk: Bool

    func asPoint() -> ForecastPoint {
        ForecastPoint(id: id, date: date, temperature: temperature, isFrostRisk: isFrostRisk)
    }

    static func from(_ point: ForecastPoint) -> ForecastPointDTO {
        ForecastPointDTO(
            id: point.id,
            date: point.date,
            temperature: point.temperature,
            isFrostRisk: point.isFrostRisk
        )
    }
}
