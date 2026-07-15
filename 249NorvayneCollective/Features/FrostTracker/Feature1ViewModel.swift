import Foundation
import Combine
import SwiftUI

@MainActor
final class Feature1ViewModel: ObservableObject {
    enum Mode: String, CaseIterable, Identifiable {
        case daily = "Daily Forecast"
        case weekly = "Weekly Overview"

        var id: String { rawValue }
    }

    @Published var mode: Mode = .daily
    @Published var rangeStart: Date = Calendar.current.startOfDay(for: Date())
    @Published var rangeEnd: Date = Calendar.current.date(
        byAdding: .day,
        value: 6,
        to: Calendar.current.startOfDay(for: Date())
    ) ?? Date()
    @Published var points: [ForecastPoint] = []
    @Published var selectedPoint: ForecastPoint?
    @Published var showSuccessBadge = false
    @Published var chartPulse = false
    @Published var dateError: String?
    @Published var shakeDates = 0
    @Published var cityQuery = ""
    @Published var cityResults: [GeocodingResult] = []
    @Published var isSearchingCity = false
    @Published var isLoadingForecast = false
    @Published var statusMessage: String?
    @Published var dayMinC: Double?
    @Published var nightMinC: Double?

    private let store: AppStorageStore
    private let weatherService: OpenMeteoService
    private var searchTask: Task<Void, Never>?

    init(store: AppStorageStore, weatherService: OpenMeteoService = .shared) {
        self.store = store
        self.weatherService = weatherService
        points = store.forecastPoints.map { $0.asPoint() }.sorted { $0.date < $1.date }
        dayMinC = store.lastDayMinC
        nightMinC = store.lastNightMinC
        if let city = store.selectedCity {
            cityQuery = city.name
        }
    }

    var isEmpty: Bool { points.isEmpty }

    var selectedCityLabel: String {
        store.selectedCity?.displayName ?? "No city selected"
    }

    func reloadFromStore() {
        points = store.forecastPoints.map { $0.asPoint() }.sorted { $0.date < $1.date }
        dayMinC = store.lastDayMinC
        nightMinC = store.lastNightMinC
        cityQuery = store.selectedCity?.name ?? ""
        cityResults = []
        statusMessage = nil
    }

    func searchCitiesDebounced() {
        searchTask?.cancel()
        let query = cityQuery
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await searchCities(query: query)
        }
    }

    func searchCities(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            cityResults = []
            return
        }
        isSearchingCity = true
        defer { isSearchingCity = false }
        do {
            cityResults = try await weatherService.searchCities(query: trimmed)
            statusMessage = nil
        } catch {
            cityResults = []
            if trimmed.count >= 2 {
                statusMessage = error.localizedDescription
            }
        }
    }

    func selectCity(_ result: GeocodingResult) {
        HapticFeedback.lightTap()
        store.selectedCity = result.savedCity
        cityQuery = result.name
        cityResults = []
        statusMessage = "City saved. Tap Update Forecast."
        store.recordMeaningfulAction(itemsDelta: 1, sessionCompleted: false)
    }

    func updateForecast() {
        HapticFeedback.mediumTap()

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: rangeStart)
        let end = calendar.startOfDay(for: rangeEnd)

        guard start <= end else {
            dateError = "End date must be on or after the start date."
            shakeDates += 1
            HapticFeedback.warning()
            return
        }

        let maxSpan = calendar.date(byAdding: .day, value: 30, to: start) ?? end
        guard end <= maxSpan else {
            dateError = "Choose a range of 30 days or fewer."
            shakeDates += 1
            HapticFeedback.warning()
            return
        }

        dateError = nil

        guard let city = store.selectedCity else {
            dateError = OpenMeteoServiceError.cityRequired.localizedDescription
            shakeDates += 1
            HapticFeedback.warning()
            return
        }

        isLoadingForecast = true
        statusMessage = nil

        let forecastDays: Int
        switch mode {
        case .daily:
            forecastDays = max(1, (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1)
        case .weekly:
            forecastDays = 7
        }

        Task {
            do {
                let payload = try await weatherService.fetchForecast(
                    latitude: city.latitude,
                    longitude: city.longitude,
                    days: min(forecastDays, 16)
                )
                applyPayload(payload, start: start, end: end, mode: mode)
                withSuccessFeedback()
            } catch {
                // Offline / network failure: keep utility usable with local model.
                applySyntheticFallback(start: start, dayCount: forecastDays)
                statusMessage = "Using local estimate — \(error.localizedDescription)"
                withSuccessFeedback()
            }
            isLoadingForecast = false
        }
    }

    private func applyPayload(_ payload: OpenMeteoForecastPayload, start: Date, end: Date, mode: Mode) {
        let calendar = Calendar.current
        var filtered = payload.points.filter { point in
            let day = calendar.startOfDay(for: point.date)
            return day >= start && day <= end
        }
        if mode == .weekly {
            filtered = Array(payload.points.prefix(7))
        }
        if filtered.isEmpty {
            filtered = payload.points
        }

        points = filtered
        dayMinC = payload.dayMinC
        nightMinC = payload.nightMinC
        store.lastDayMinC = payload.dayMinC
        store.lastNightMinC = payload.nightMinC
        store.forecastPoints = filtered.map(ForecastPointDTO.from)

        var forecasts = store.frostForecasts
        for point in filtered {
            forecasts[calendar.startOfDay(for: point.date).timeIntervalSince1970] = point.isFrostRisk
        }
        store.frostForecasts = forecasts
        store.lastViewedDate = Date()
        store.rebuildTonightChecklist()
        store.recordMeaningfulAction(itemsDelta: max(filtered.count, 1), sessionCompleted: true)
        statusMessage = "Forecast updated for \(store.selectedCity?.name ?? "city")."
    }

    private func applySyntheticFallback(start: Date, dayCount: Int) {
        let calendar = Calendar.current
        var generated: [ForecastPoint] = []
        var forecasts = store.frostForecasts
        for offset in 0..<dayCount {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            let temperature = Self.syntheticTemperature(for: day)
            let frost = temperature <= 0
            generated.append(ForecastPoint(date: day, temperature: temperature, isFrostRisk: frost))
            forecasts[day.timeIntervalSince1970] = frost
        }
        points = generated
        let night = generated.first?.temperature ?? 0
        let day = (generated.first?.temperature ?? 0) + 3
        dayMinC = day
        nightMinC = night
        store.lastDayMinC = day
        store.lastNightMinC = night
        store.forecastPoints = generated.map(ForecastPointDTO.from)
        store.frostForecasts = forecasts
        store.lastViewedDate = Date()
        store.rebuildTonightChecklist()
        store.recordMeaningfulAction(itemsDelta: max(generated.count, 1), sessionCompleted: true)
    }

    func selectPoint(at relativeX: CGFloat, width: CGFloat) {
        guard !points.isEmpty, width > 0 else { return }
        let clamped = min(max(relativeX, 0), width)
        let index = Int(round(clamped / width * CGFloat(points.count - 1)))
        let safeIndex = min(max(index, 0), points.count - 1)
        selectedPoint = points[safeIndex]
        HapticFeedback.lightTap()
        HapticFeedback.tick()
    }

    private func withSuccessFeedback() {
        HapticFeedback.updateAcknowledged()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showSuccessBadge = true
            chartPulse = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showSuccessBadge = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.chartPulse = false
            }
        }
    }

    static func syntheticTemperature(for date: Date) -> Double {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = Calendar.current.component(.year, from: date)
        let seed = Double((year * 1000 + day) % 97)
        let seasonal = -4.0 + 18.0 * sin((Double(day) / 365.0) * 2.0 * .pi + 1.2)
        let noise = (seed / 97.0 - 0.5) * 6.0
        return (seasonal + noise).rounded(toPlaces: 1)
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
