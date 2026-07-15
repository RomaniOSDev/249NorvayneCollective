import Foundation
import Combine
import SwiftUI

@MainActor
final class Feature2ViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var showSearch = false
    @Published var selectedAlert: FrostAlert?
    @Published var showDetail = false
    @Published var showSuccessBadge = false
    @Published var pulsedID: UUID?

    private let store: AppStorageStore

    init(store: AppStorageStore) {
        self.store = store
    }

    var filteredAlerts: [FrostAlert] {
        let sorted = store.frostAlerts.sorted { $0.date > $1.date }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sorted }
        return sorted.filter { alert in
            alert.severity.title.localizedCaseInsensitiveContains(query)
                || alert.note.localizedCaseInsensitiveContains(query)
                || alert.date.formatted(date: .abbreviated, time: .shortened)
                    .localizedCaseInsensitiveContains(query)
        }
    }

    func refreshAlerts() {
        HapticFeedback.mediumTap()

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var created = 0
        var newAlerts = store.frostAlerts

        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let temperature = Feature1ViewModel.syntheticTemperature(for: day)
            guard temperature <= 0 else { continue }

            let dayStart = calendar.startOfDay(for: day)
            let already = newAlerts.contains {
                calendar.isDate($0.date, inSameDayAs: dayStart)
            }
            if already { continue }

            let hour = 4 + (offset % 3)
            let stamped = calendar.date(bySettingHour: hour, minute: 15, second: 0, of: dayStart) ?? dayStart
            let severity: FrostSeverity = temperature <= -3 ? .hardFreeze : .lightFrost
            let alert = FrostAlert(
                date: stamped,
                temperature: temperature,
                severity: severity,
                note: severity == .hardFreeze
                    ? "Hard freeze conditions recorded."
                    : "Light frost conditions recorded."
            )
            newAlerts.append(alert)
            created += 1
        }

        store.frostAlerts = newAlerts.sorted { $0.date > $1.date }
        store.lastSyncedAt = Date()
        store.recordMeaningfulAction(itemsDelta: max(created, 1), sessionCompleted: true)

        HapticFeedback.lightAcknowledge()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showSuccessBadge = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showSuccessBadge = false
            }
        }
    }

    func deleteAlert(_ alert: FrostAlert) {
        HapticFeedback.lightTap()
        store.frostAlerts.removeAll { $0.id == alert.id }
        store.favoriteAlerts.removeAll { $0 == alert.id }
    }

    func toggleFavorite(_ alert: FrostAlert) {
        HapticFeedback.lightTap()
        if store.favoriteAlerts.contains(alert.id) {
            store.favoriteAlerts.removeAll { $0 == alert.id }
        } else {
            store.favoriteAlerts.append(alert.id)
            pulsedID = alert.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.pulsedID = nil
            }
        }
    }

    func openDetail(_ alert: FrostAlert) {
        HapticFeedback.lightTap()
        selectedAlert = alert
        showDetail = true
    }
}
