import Foundation

enum OpenMeteoServiceError: LocalizedError {
    case invalidURL
    case badResponse
    case decodingFailed
    case noResults
    case cityRequired

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Could not build the request."
        case .badResponse: return "Weather service returned an unexpected response."
        case .decodingFailed: return "Could not read forecast data."
        case .noResults: return "No matching cities found."
        case .cityRequired: return "Choose a city before updating the forecast."
        }
    }
}

struct GeocodingResult: Identifiable, Equatable {
    let id: Int
    let name: String
    let country: String
    let admin1: String
    let latitude: Double
    let longitude: Double

    var savedCity: SavedCity {
        SavedCity(
            id: SavedCity.makeID(latitude: latitude, longitude: longitude),
            name: name,
            country: country,
            admin1: admin1,
            latitude: latitude,
            longitude: longitude
        )
    }
}

struct HourlyTemperature: Equatable {
    let date: Date
    let temperature: Double
}

struct OpenMeteoForecastPayload: Equatable {
    let points: [ForecastPoint]
    let dayMinC: Double
    let nightMinC: Double
    let hourly: [HourlyTemperature]
}

actor OpenMeteoService {
    static let shared = OpenMeteoService()

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func searchCities(query: String) async throws -> [GeocodingResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")
        components?.queryItems = [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "count", value: "8"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]
        guard let url = components?.url else { throw OpenMeteoServiceError.invalidURL }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw OpenMeteoServiceError.badResponse
        }

        let decoded = try decoder.decode(GeocodingResponseDTO.self, from: data)
        let results = (decoded.results ?? []).map {
            GeocodingResult(
                id: $0.id,
                name: $0.name,
                country: $0.country ?? "",
                admin1: $0.admin1 ?? "",
                latitude: $0.latitude,
                longitude: $0.longitude
            )
        }
        if results.isEmpty { throw OpenMeteoServiceError.noResults }
        return results
    }

    func fetchForecast(latitude: Double, longitude: Double, days: Int = 7) async throws -> OpenMeteoForecastPayload {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "hourly", value: "temperature_2m"),
            URLQueryItem(name: "daily", value: "temperature_2m_min,temperature_2m_max,sunrise,sunset"),
            URLQueryItem(name: "forecast_days", value: String(max(1, min(days, 16)))),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        guard let url = components?.url else { throw OpenMeteoServiceError.invalidURL }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw OpenMeteoServiceError.badResponse
        }

        let decoded = try decoder.decode(ForecastResponseDTO.self, from: data)
        return Self.mapForecast(decoded)
    }

    nonisolated private static func mapForecast(_ dto: ForecastResponseDTO) -> OpenMeteoForecastPayload {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]

        let dailyTimes = dto.daily?.time ?? []
        let dailyMins = dto.daily?.temperature_2m_min ?? []
        let sunrises = dto.daily?.sunrise ?? []
        let sunsets = dto.daily?.sunset ?? []

        var points: [ForecastPoint] = []
        for index in dailyTimes.indices {
            guard let day = parseDay(dailyTimes[index]) else { continue }
            let minTemp = index < dailyMins.count ? dailyMins[index] : 0
            points.append(
                ForecastPoint(
                    date: day,
                    temperature: minTemp,
                    isFrostRisk: minTemp <= 0
                )
            )
        }

        let hourlyTimes = dto.hourly?.time ?? []
        let hourlyTemps = dto.hourly?.temperature_2m ?? []
        var hourly: [HourlyTemperature] = []
        for index in hourlyTimes.indices {
            let raw = hourlyTimes[index]
            let date = iso.date(from: raw) ?? parseDayHour(raw)
            guard let date else { continue }
            let temp = index < hourlyTemps.count ? hourlyTemps[index] : 0
            hourly.append(HourlyTemperature(date: date, temperature: temp))
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today.addingTimeInterval(86400)

        let sunriseToday = sunrises.first.flatMap { iso.date(from: $0) ?? parseDayHour($0) }
        let sunsetToday = sunsets.first.flatMap { iso.date(from: $0) ?? parseDayHour($0) }
        let sunriseTomorrow: Date? = {
            if sunrises.count > 1 {
                return iso.date(from: sunrises[1]) ?? parseDayHour(sunrises[1])
            }
            return nil
        }()

        let dayStart = sunriseToday ?? today.addingTimeInterval(6 * 3600)
        let dayEnd = sunsetToday ?? today.addingTimeInterval(18 * 3600)
        let nightEnd = sunriseTomorrow ?? tomorrow.addingTimeInterval(6 * 3600)

        let dayTemps = hourly.filter { $0.date >= dayStart && $0.date < dayEnd }.map(\.temperature)
        let nightTemps = hourly.filter { $0.date >= dayEnd && $0.date < nightEnd }.map(\.temperature)

        let dayMin = dayTemps.min() ?? (points.first?.temperature ?? 0)
        let nightMin = nightTemps.min() ?? dayMin

        return OpenMeteoForecastPayload(
            points: points,
            dayMinC: dayMin,
            nightMinC: nightMin,
            hourly: hourly
        )
    }

    nonisolated private static func parseDay(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }

    nonisolated private static func parseDayHour(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter.date(from: value)
    }
}

// MARK: - DTOs

private struct GeocodingResponseDTO: Decodable {
    let results: [GeocodingItemDTO]?
}

private struct GeocodingItemDTO: Decodable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let admin1: String?
}

private struct ForecastResponseDTO: Decodable {
    let hourly: HourlyDTO?
    let daily: DailyDTO?
}

private struct HourlyDTO: Decodable {
    let time: [String]
    let temperature_2m: [Double]
}

private struct DailyDTO: Decodable {
    let time: [String]
    let temperature_2m_min: [Double]?
    let temperature_2m_max: [Double]?
    let sunrise: [String]?
    let sunset: [String]?
}
