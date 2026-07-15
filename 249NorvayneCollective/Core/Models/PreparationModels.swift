import Foundation

struct SavedCity: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var country: String
    var admin1: String
    var latitude: Double
    var longitude: Double

    var displayName: String {
        let region = admin1.isEmpty ? country : "\(admin1), \(country)"
        return "\(name) · \(region)"
    }

    static func makeID(latitude: Double, longitude: Double) -> String {
        String(format: "%.4f,%.4f", latitude, longitude)
    }
}

enum AssetKind: String, Codable, CaseIterable, Identifiable {
    case roses
    case outdoorTap
    case greenhouse
    case pipes
    case tenderPlants
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .roses: return "Roses"
        case .outdoorTap: return "Outdoor Tap"
        case .greenhouse: return "Greenhouse"
        case .pipes: return "Pipes"
        case .tenderPlants: return "Tender Plants"
        case .custom: return "Custom"
        }
    }

    var symbolName: String {
        switch self {
        case .roses: return "leaf.fill"
        case .outdoorTap: return "drop.fill"
        case .greenhouse: return "house.fill"
        case .pipes: return "wrench.and.screwdriver.fill"
        case .tenderPlants: return "leaf.arrow.triangle.circlepath"
        case .custom: return "square.grid.2x2.fill"
        }
    }

    var defaultThresholdC: Double {
        switch self {
        case .roses: return -1
        case .outdoorTap: return 0
        case .greenhouse: return -2
        case .pipes: return 0
        case .tenderPlants: return 2
        case .custom: return 0
        }
    }
}

struct ProtectableAsset: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var kind: AssetKind
    var frostThresholdC: Double
    var notes: String

    init(
        id: UUID = UUID(),
        name: String,
        kind: AssetKind,
        frostThresholdC: Double? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.frostThresholdC = frostThresholdC ?? kind.defaultThresholdC
        self.notes = notes
    }
}

struct ProtectionPlan: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var steps: [String]
    var linkedKind: AssetKind?
    var isTemplate: Bool

    init(
        id: UUID = UUID(),
        title: String,
        steps: [String],
        linkedKind: AssetKind? = nil,
        isTemplate: Bool = false
    ) {
        self.id = id
        self.title = title
        self.steps = steps
        self.linkedKind = linkedKind
        self.isTemplate = isTemplate
    }
}

struct TonightChecklistItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var isDone: Bool
    var relatedAssetID: UUID?
    var relatedPlanID: UUID?

    init(
        id: UUID = UUID(),
        title: String,
        isDone: Bool = false,
        relatedAssetID: UUID? = nil,
        relatedPlanID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.relatedAssetID = relatedAssetID
        self.relatedPlanID = relatedPlanID
    }
}

struct FrostJournalEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var cityName: String
    var hadFrost: Bool
    var minTemperature: Double?
    var savedAssetNames: [String]
    var notes: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        cityName: String,
        hadFrost: Bool,
        minTemperature: Double? = nil,
        savedAssetNames: [String] = [],
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.cityName = cityName
        self.hadFrost = hadFrost
        self.minTemperature = minTemperature
        self.savedAssetNames = savedAssetNames
        self.notes = notes
    }
}

struct DayNightRisk: Equatable {
    var dayMinC: Double
    var nightMinC: Double
    var dayFrost: Bool
    var nightFrost: Bool
    var lowestAssetRiskName: String?
}

enum ProtectionPlanCatalog {
    static let defaults: [ProtectionPlan] = [
        ProtectionPlan(
            title: "Roses Cover Plan",
            steps: [
                "Water soil lightly before dusk",
                "Wrap bases with mulch or straw",
                "Drape breathable frost cloth overnight",
                "Remove cover after morning thaw"
            ],
            linkedKind: .roses,
            isTemplate: true
        ),
        ProtectionPlan(
            title: "Outdoor Tap Shutdown",
            steps: [
                "Close indoor shutoff valve",
                "Open outdoor faucet to drain",
                "Insulate exposed spigot",
                "Store hose indoors"
            ],
            linkedKind: .outdoorTap,
            isTemplate: true
        ),
        ProtectionPlan(
            title: "Greenhouse Seal",
            steps: [
                "Close vents and doors before sunset",
                "Add thermal mass (water barrels) if available",
                "Check heater or frost fan settings",
                "Inspect seals for drafts"
            ],
            linkedKind: .greenhouse,
            isTemplate: true
        ),
        ProtectionPlan(
            title: "Pipe Protection",
            steps: [
                "Insulate exposed outdoor pipes",
                "Allow a slight drip on vulnerable lines",
                "Open cabinet doors for indoor plumbing near outer walls",
                "Recheck pressure after sunrise"
            ],
            linkedKind: .pipes,
            isTemplate: true
        ),
        ProtectionPlan(
            title: "Tender Plants Rescue",
            steps: [
                "Move pots against a warm wall or indoors",
                "Group containers together",
                "Cover with frost fabric, not plastic on leaves",
                "Water soil to retain heat"
            ],
            linkedKind: .tenderPlants,
            isTemplate: true
        )
    ]
}

enum DefaultAssetsFactory {
    static func starterAssets() -> [ProtectableAsset] {
        [
            ProtectableAsset(name: "Garden Roses", kind: .roses),
            ProtectableAsset(name: "Yard Tap", kind: .outdoorTap),
            ProtectableAsset(name: "Back Greenhouse", kind: .greenhouse)
        ]
    }
}
