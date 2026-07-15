import Foundation
import Combine
import SwiftUI

@MainActor
final class Feature3ViewModel: ObservableObject {
    enum Timeframe: String, CaseIterable, Identifiable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"

        var id: String { rawValue }
    }

    @Published var selectedEntry: FrostEntry?
    @Published var showDetail = false
    @Published var showSuccessBadge = false

    private let store: AppStorageStore

    init(store: AppStorageStore) {
        self.store = store
    }

    var timeframe: Timeframe {
        get { Timeframe(rawValue: store.selectedTimeframe) ?? .daily }
        set { store.selectedTimeframe = newValue.rawValue }
    }

    var filteredHistory: [FrostEntry] {
        let calendar = Calendar.current
        let now = Date()
        let sorted = store.frostHistory.sorted { $0.date > $1.date }

        switch timeframe {
        case .daily:
            return sorted.filter { calendar.isDate($0.date, inSameDayAs: now) || $0.date <= now }
                .prefix(14)
                .map { $0 }
        case .weekly:
            guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return sorted }
            return sorted.filter { $0.date >= weekAgo }
        case .monthly:
            guard let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) else { return sorted }
            return sorted.filter { $0.date >= monthAgo }
        }
    }

    func syncData() {
        HapticFeedback.mediumTap()

        let calendar = Calendar.current
        var history = store.frostHistory
        var added = 0

        let forecastDays = store.frostForecasts.keys.sorted(by: >)
        for key in forecastDays.prefix(14) {
            guard store.frostForecasts[key] == true else { continue }
            let date = Date(timeIntervalSince1970: key)
            let exists = history.contains { calendar.isDate($0.date, inSameDayAs: date) }
            if exists { continue }

            let minTemp = Feature1ViewModel.syntheticTemperature(for: date)
            let duration = minTemp <= -3 ? 8.0 : 4.5
            let entry = FrostEntry(
                date: date,
                minTemperature: minTemp,
                durationHours: duration,
                summary: "Frost window lasting \(String(format: "%.1f", duration)) hours."
            )
            history.append(entry)
            added += 1
        }

        if added == 0 {
            for offset in 0..<5 {
                guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
                let temp = Feature1ViewModel.syntheticTemperature(for: day)
                guard temp <= 0 else { continue }
                let exists = history.contains { calendar.isDate($0.date, inSameDayAs: day) }
                if exists { continue }
                history.append(
                    FrostEntry(
                        date: calendar.startOfDay(for: day),
                        minTemperature: temp,
                        durationHours: temp <= -3 ? 7.0 : 3.5,
                        summary: "Synced frost occurrence from local records."
                    )
                )
                added += 1
            }
        }

        store.frostHistory = history.sorted { $0.date > $1.date }
        store.recordMeaningfulAction(itemsDelta: max(added, 1), sessionCompleted: true)

        HapticFeedback.updateAcknowledged()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showSuccessBadge = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showSuccessBadge = false
            }
        }
    }

    func deleteEntry(_ entry: FrostEntry) {
        HapticFeedback.lightTap()
        store.frostHistory.removeAll { $0.id == entry.id }
    }

    func openDetail(_ entry: FrostEntry) {
        HapticFeedback.lightTap()
        selectedEntry = entry
        showDetail = true
    }

    func setTimeframe(_ value: Timeframe) {
        HapticFeedback.lightTap()
        store.selectedTimeframe = value.rawValue
        objectWillChange.send()
    }
}
