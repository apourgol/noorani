//
//  PrayerTimesFetcher.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
 
//
//

import Foundation
import SwiftUI

// MARK: - Prayer Calculation Method Models
struct PrayerCalculationMethod: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let params: PrayerMethodParams?
    let location: PrayerMethodLocation?
}

struct PrayerMethodParams: Codable, Hashable {
    let Fajr: Double?
    let Isha: IshaParam?
    let Maghrib: MaghribParam?
    let Midnight: String?
    let shafaq: String?

    enum IshaParam: Codable, Hashable {
        case degrees(Double)
        case minutes(String)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let degrees = try? container.decode(Double.self) {
                self = .degrees(degrees)
            } else if let minutes = try? container.decode(String.self) {
                self = .minutes(minutes)
            } else {
                throw DecodingError.typeMismatch(IshaParam.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Double or String"))
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .degrees(let degrees):
                try container.encode(degrees)
            case .minutes(let minutes):
                try container.encode(minutes)
            }
        }

        var displayValue: String {
            switch self {
            case .degrees(let degrees):
                return "\(degrees)°"
            case .minutes(let minutes):
                return minutes
            }
        }
    }

    enum MaghribParam: Codable, Hashable {
        case degrees(Double)
        case minutes(String)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let degrees = try? container.decode(Double.self) {
                self = .degrees(degrees)
            } else if let minutes = try? container.decode(String.self) {
                self = .minutes(minutes)
            } else {
                throw DecodingError.typeMismatch(MaghribParam.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Double or String"))
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .degrees(let degrees):
                try container.encode(degrees)
            case .minutes(let minutes):
                try container.encode(minutes)
            }
        }
    }
}

struct PrayerMethodLocation: Codable, Hashable {
    let latitude: Double
    let longitude: Double
}

struct PrayerCalculationMethodsResponse: Codable {
    let code: Int
    let status: String
    let data: [String: PrayerCalculationMethod]
}

@MainActor
class PrayerTimesFetcher: ObservableObject {
    // Published properties for UI updates
    @Published var isLoading: Bool = false
    @Published var hasError: Bool = false
    @Published var errorMessage: String = ""
    @Published var nextPrayerName: String = "Loading..."
    @Published var countdown: String = ""

    // Core data properties
    @Published var timings: [String: String] = [:]
    @Published var readableDate: String = ""
    @Published var hijriDate: String = ""
    @Published var prayerTimes: [String: Date] = [:]
    @Published var tomorrowPrayerTimes: [String: Date] = [:]
    @Published var availableMethods: [PrayerCalculationMethod] = []
    @Published var selectedMethod: PrayerCalculationMethod?

    // Prayer visibility toggles - only for prayers users might want to hide
    @AppStorage("showAsr") var showAsr: Bool = false // Hidden by default for Shia
    @AppStorage("showIsha") var showIsha: Bool = false // Hidden by default for Shia

    // Location and caching
    @AppStorage("currentLat") var currentLat: Double = 0.0
    @AppStorage("currentLng") var currentLng: Double = 0.0
    @AppStorage("lastFetchDate") private var lastFetchDate: String = ""
    @AppStorage("selectedMethodId") private var selectedMethodId: Int = 7 // Default to TEHRAN for Shia
    private var nextPrayerTime: Date?
    private var timer: Timer?

    // Cache formatters to avoid recreating them
    private let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter
    }()

    private let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()

    private let allowedPrayerKeys: Set<String> = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Sunset", "Maghrib", "Isha", "Midnight"]

    init() {
        loadDefaultMethods()
        setSelectedMethod()

        // Update next prayer if we have data
        if !prayerTimes.isEmpty {
            updateNextPrayer()
        }
    }

    // MARK: - Method Management
    private func loadDefaultMethods() {
        let defaultMethodsJSON = """
        {
            "JAFARI": {"id": 0, "name": "Qom", "params": {"Fajr": 16, "Isha": 14, "Maghrib": 4, "Midnight": "JAFARI"}, "location": {"latitude": 34.6415764, "longitude": 50.8746035}},
            "KARACHI": {"id": 1, "name": "Karachi", "params": {"Fajr": 18, "Isha": 18}, "location": {"latitude": 24.8614622, "longitude": 67.0099388}},
            "ISNA": {"id": 2, "name": "ISNA", "params": {"Fajr": 15, "Isha": 15}, "location": {"latitude": 39.70421229999999, "longitude": -86.39943869999999}},
            "MWL": {"id": 3, "name": "Muslim World League", "params": {"Fajr": 18, "Isha": 17}, "location": {"latitude": 51.5194682, "longitude": -0.1360365}},
            "MAKKAH": {"id": 4, "name": "Makkah Umm al-Qura", "params": {"Fajr": 18.5, "Isha": "90 min"}, "location": {"latitude": 21.3890824, "longitude": 39.8579118}},
            "EGYPT": {"id": 5, "name": "Egyptian", "params": {"Fajr": 19.5, "Isha": 17.5}, "location": {"latitude": 30.0444196, "longitude": 31.2357116}},
            "TEHRAN": {"id": 7, "name": "Tehran", "params": {"Fajr": 17.7, "Isha": 14, "Maghrib": 4.5, "Midnight": "JAFARI"}, "location": {"latitude": 35.6891975, "longitude": 51.3889736}}
        }
        """

        if let data = defaultMethodsJSON.data(using: .utf8) {
            do {
                let methodsDict = try JSONDecoder().decode([String: PrayerCalculationMethod].self, from: data)
                availableMethods = Array(methodsDict.values).sorted(by: { $0.id < $1.id })
            } catch {
                print("Error loading default methods: \(error)")
            }
        }
    }

    private func setSelectedMethod() {
        if let method = availableMethods.first(where: { $0.id == selectedMethodId }) {
            selectedMethod = method
        } else if let defaultMethod = availableMethods.first(where: { $0.id == 7 }) {
            // Default to TEHRAN (Shia method)
            selectedMethod = defaultMethod
            selectedMethodId = 7
        } else {
            selectedMethod = availableMethods.first
            selectedMethodId = selectedMethod?.id ?? 0
        }
    }

    func selectMethod(_ method: PrayerCalculationMethod) {
        selectedMethod = method
        selectedMethodId = method.id

        // Clear cache to refresh with new method
        lastFetchDate = ""

        // Refetch prayer times if we have location
        if currentLat != 0.0 && currentLng != 0.0 {
            Task {
                await fetchPrayerTimes(latitude: currentLat, longitude: currentLng)
            }
        }
    }

    // Helper method to get recommended methods based on sect
    func getRecommendedMethods(for sect: String = "shia") -> [PrayerCalculationMethod] {
        if sect.lowercased() == "shia" {
            // Recommended Shia methods
            return availableMethods.filter { method in
                [0, 7].contains(method.id) // JAFARI, TEHRAN
            }
        } else {
            // Recommended Sunni methods
            return availableMethods.filter { method in
                [1, 2, 3, 4, 5].contains(method.id) // KARACHI, ISNA, MWL, MAKKAH, EGYPT
            }
        }
    }

    // MARK: - Location Management
    func updateLocation(latitude: Double, longitude: Double) async {
        print("🌍 Location update requested: \(latitude), \(longitude)")

        // Always update the stored coordinates immediately
        currentLat = latitude
        currentLng = longitude

        // Always clear cache for location changes to ensure fresh data
        lastFetchDate = ""

        print("📍 Location updated, fetching fresh prayer times")
        await fetchPrayerTimesForLocation(latitude: latitude, longitude: longitude)
    }

    // Dedicated method for location-based fetches that bypasses cache
    private func fetchPrayerTimesForLocation(latitude: Double, longitude: Double) async {
        // Prevent multiple concurrent requests
        if isLoading {
            print("⚠️ Already loading prayer times, skipping location update")
            return
        }

        // Ensure we have a calculation method
        guard let method = selectedMethod else {
            print("❌ No calculation method selected")
            return
        }

        isLoading = true
        hasError = false
        errorMessage = ""

        let todayString = apiDateFormatter.string(from: Date())
        let urlString = "https://api.aladhan.com/v1/timings/\(todayString)?latitude=\(latitude)&longitude=\(longitude)&method=\(method.id)&iso8601=true&midnightMode=1"

        guard let url = URL(string: urlString) else {
            isLoading = false
            print("❌ Invalid URL generated")
            return
        }

        print("🌐 Fetching prayer times for location: \(todayString) using method: \(method.name) (ID: \(method.id))")
        print("🔗 Request URL: \(urlString)")

        var request = URLRequest(url: url)
        request.timeoutInterval = 15.0
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            Task { @MainActor in
                self.isLoading = false

                // Check for network errors
                if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                    self.hasError = true
                    self.errorMessage = "Network connection failed"
                    return
                }

                // Check HTTP response
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode != 200 {
                    print("❌ HTTP Error: \(httpResponse.statusCode)")
                    self.hasError = true
                    self.errorMessage = "Server error (\(httpResponse.statusCode))"
                    return
                }

                guard let data = data else {
                    print("❌ No data received")
                    return
                }

                do {
                    let response = try JSONDecoder().decode(PrayerResponse.self, from: data)
                    let processedData = self.processPrayerResponse(response)

                    self.hasError = false
                    self.errorMessage = ""

                    self.timings = processedData.timings
                    self.readableDate = processedData.readableDate
                    self.hijriDate = processedData.hijriDate
                    self.prayerTimes = processedData.prayerTimes

                    // Update cache info with the new location
                    self.lastFetchDate = self.apiDateFormatter.string(from: Date())
                    self.currentLat = latitude
                    self.currentLng = longitude

                    self.updateNextPrayer()
                    print("✅ Prayer times updated successfully for new location")
                } catch {
                    print("❌ Decoding error: \(error)")
                    self.hasError = true
                    self.errorMessage = "Data parsing error"
                }
            }
        }.resume()
    }

    // MARK: - Prayer Time Fetching
    private func shouldFetchNewData(for latitude: Double, longitude: Double) async -> Bool {
        let today = apiDateFormatter.string(from: Date())
        let dateChanged = lastFetchDate != today
        let noData = prayerTimes.isEmpty

        // Always fetch if date changed or no data exists
        if dateChanged || noData {
            print("🔄 Should fetch new data? Date changed: \(dateChanged), No data: \(noData)")
            return true
        }

        // If we have recent data for today, we can skip
        print("🔄 Using existing data for today")
        return false
    }

    func fetchPrayerTimes(latitude: Double, longitude: Double) async {
        // Prevent multiple concurrent requests
        if isLoading {
            print("⚠️ Already loading prayer times, skipping request")
            return
        }

        // For location updates, always fetch fresh data
        // For other calls, check if we need fresh data
        let needsData = await shouldFetchNewData(for: latitude, longitude: longitude)
        if !needsData {
            print("📋 Using existing prayer times for today")
            return
        }

        // Ensure we have a calculation method
        guard let method = selectedMethod else {
            print("❌ No calculation method selected")
            return
        }

        isLoading = true
        hasError = false
        errorMessage = ""

        let todayString = apiDateFormatter.string(from: Date())
        let urlString = "https://api.aladhan.com/v1/timings/\(todayString)?latitude=\(latitude)&longitude=\(longitude)&method=\(method.id)&iso8601=true&midnightMode=1"

        guard let url = URL(string: urlString) else {
            isLoading = false
            print("❌ Invalid URL generated")
            return
        }

        print("🌐 Fetching prayer times for: \(todayString) using method: \(method.name) (ID: \(method.id))")
        print("🔗 Request URL: \(urlString)")

        var request = URLRequest(url: url)
        request.timeoutInterval = 15.0
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            Task { @MainActor in
                self.isLoading = false

                // Check for network errors
                if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                    self.hasError = true
                    self.errorMessage = "Network connection failed"
                    return
                }

                // Check HTTP response
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode != 200 {
                    print("❌ HTTP Error: \(httpResponse.statusCode)")
                    self.hasError = true
                    self.errorMessage = "Server error (\(httpResponse.statusCode))"
                    return
                }

                guard let data = data else {
                    print("❌ No data received")
                    return
                }

                do {
                    let response = try JSONDecoder().decode(PrayerResponse.self, from: data)
                    let processedData = self.processPrayerResponse(response)

                    self.hasError = false
                    self.errorMessage = ""

                    self.timings = processedData.timings
                    self.readableDate = processedData.readableDate
                    self.hijriDate = processedData.hijriDate
                    self.prayerTimes = processedData.prayerTimes

                    // Update cache info
                    self.lastFetchDate = self.apiDateFormatter.string(from: Date())
                    self.currentLat = latitude
                    self.currentLng = longitude

                    self.updateNextPrayer()
                    print("✅ Prayer times updated successfully")
                } catch {
                    print("❌ Decoding error: \(error)")
                    self.hasError = true
                    self.errorMessage = "Data parsing error"
                }
            }
        }.resume()
    }

    private func processPrayerResponse(_ response: PrayerResponse) -> (timings: [String: String], readableDate: String, hijriDate: String, prayerTimes: [String: Date]) {
        var resultPrayerTimes: [String: Date] = [:]

        // Convert timings to Date objects
        for (name, timeString) in response.data.timings {
            guard allowedPrayerKeys.contains(name) else { continue }
            if let prayerDate = isoDateFormatter.date(from: timeString) {
                resultPrayerTimes[name] = prayerDate
            } else {
                print("⚠️ Failed to parse \(name): \(timeString)")
            }
        }

        return (
            timings: response.data.timings,
            readableDate: response.data.date.readable,
            hijriDate: response.data.date.hijri.date,
            prayerTimes: resultPrayerTimes
        )
    }

    // MARK: - Next Prayer Management
    private func isVisible(prayer: String) -> Bool {
        switch prayer {
        case "Asr":
            return showAsr
        case "Isha":
            return showIsha
        case "Midnight":
            return true // Always visible
        case "Fajr", "Sunrise", "Dhuhr", "Sunset", "Maghrib":
            return true // Always visible
        default:
            return false
        }
    }

    func updateNextPrayer() {
        let now = Date()

        // Get only visible prayers that are upcoming today, sorted by time
        let upcomingPrayers = prayerTimes
            .filter { prayerName, prayerTime in
                let isUpcoming = prayerTime > now
                let visible = isVisible(prayer: prayerName)
                return isUpcoming && visible
            }
            .sorted(by: { $0.value < $1.value })

        if let next = upcomingPrayers.first {
            // Found upcoming visible prayer today
            nextPrayerName = next.key
            nextPrayerTime = next.value
            startCountdown(to: next.value)
            print("⏰ Next prayer: \(next.key) at \(next.value)")
        } else if !prayerTimes.isEmpty {
            // No more visible prayers today - check for tomorrow's Fajr (if visible)
            if isVisible(prayer: "Fajr") {
                if let tomorrowFajr = tomorrowPrayerTimes["Fajr"] {
                    // We have tomorrow's Fajr time
                    nextPrayerName = "Fajr"
                    nextPrayerTime = tomorrowFajr
                    startCountdown(to: tomorrowFajr)
                    print("🌅 Next prayer: Tomorrow's Fajr at \(tomorrowFajr)")
                } else {
                    // Need to fetch tomorrow's prayer times
                    nextPrayerName = "Fajr"
                    nextPrayerTime = nil
                    countdown = "Loading..."
                    timer?.invalidate()
                    fetchTomorrowPrayerTimes()
                    print("🌅 Need to fetch tomorrow's Fajr")
                }
            } else {
                // Fajr is not visible, show "No more prayers"
                nextPrayerName = "—"
                nextPrayerTime = nil
                countdown = "—"
                timer?.invalidate()
                print("😴 No more visible prayers today")
            }
        } else {
            // No prayer times loaded yet
            nextPrayerName = "Loading..."
            nextPrayerTime = nil
            countdown = ""
            timer?.invalidate()
            print("⏳ No prayer times loaded yet")
        }
    }

    // Public method to update next prayer when visibility settings change
    func updateNextPrayerForVisibilityChange() {
        print("👁️ Prayer visibility settings changed, updating next prayer...")
        timer?.invalidate()
        timer = nil
        updateNextPrayer()
    }

    private func startCountdown(to date: Date) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let interval = date.timeIntervalSince(Date())
            if interval <= 0 {
                Task { @MainActor in
                    self.countdown = "Now"
                    self.timer?.invalidate()
                    // When countdown reaches zero, update to find next prayer
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        Task { @MainActor in
                            self.updateNextPrayer()
                        }
                    }
                }
            } else {
                Task { @MainActor in
                    self.countdown = self.format(interval)
                }
            }
        }
    }

    private func fetchTomorrowPrayerTimes() {
        guard let method = selectedMethod else { return }
        guard currentLat != 0.0 && currentLng != 0.0 else { return }

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let tomorrowString = apiDateFormatter.string(from: tomorrow)
        let urlString = "https://api.aladhan.com/v1/timings/\(tomorrowString)?latitude=\(currentLat)&longitude=\(currentLng)&method=\(method.id)&iso8601=true&midnightMode=1"

        guard let url = URL(string: urlString) else { return }

        print("🌅 Fetching tomorrow's prayer times: \(tomorrowString)")

        var request = URLRequest(url: url)
        request.timeoutInterval = 15.0
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Error fetching tomorrow's prayer times: \(error)")
                return
            }

            guard let data = data else { return }

            do {
                let response = try JSONDecoder().decode(PrayerResponse.self, from: data)

                // Extract tomorrow's prayer times on background thread
                var tomorrowTimes: [String: Date] = [:]
                for (name, timeString) in response.data.timings {
                    guard self.allowedPrayerKeys.contains(name) else { continue }
                    if let prayerDate = self.isoDateFormatter.date(from: timeString) {
                        tomorrowTimes[name] = prayerDate
                    }
                }

                Task { @MainActor in
                    self.tomorrowPrayerTimes = tomorrowTimes
                    self.updateNextPrayer()
                }
            } catch {
                print("❌ Error decoding tomorrow's prayer times: \(error)")
            }
        }.resume()
    }

    private func format(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - Utility Methods
    var visiblePrayerKeys: [String] {
        var keys: [String] = []

        // Add prayers in chronological order
        keys.append("Fajr")
        keys.append("Sunrise")
        keys.append("Dhuhr")

        // Asr goes between Dhuhr and Sunset if enabled
        if showAsr { keys.append("Asr") }

        keys.append("Sunset")
        keys.append("Maghrib")

        // Isha goes between Maghrib and Midnight if enabled
        if showIsha { keys.append("Isha") }

        // Midnight is always visible
        keys.append("Midnight")

        return keys
    }

    func resetToDefaults() {
        // Reset to default calculation method
        selectedMethod = availableMethods.first(where: { $0.id == 7 }) ?? availableMethods.first // Default to TEHRAN (Shia method)
        if let defaultMethod = selectedMethod {
            selectedMethodId = defaultMethod.id
        }

        // Clear stored preferences
        lastFetchDate = ""

        // Reset prayer visibility to defaults (Shia configuration)
        showAsr = false // Hidden for Shia
        showIsha = false // Hidden for Shia

        // Reset countdown and next prayer info
        nextPrayerName = "Loading..."
        countdown = ""
        nextPrayerTime = nil

        // Clear errors
        hasError = false
        errorMessage = ""

        // Refresh data with defaults if we have location
        if currentLat != 0.0 && currentLng != 0.0 {
            Task {
                await fetchPrayerTimes(latitude: currentLat, longitude: currentLng)
            }
        }
    }

    func refreshPrayerTimes() {
        guard currentLat != 0.0 && currentLng != 0.0 else {
            print("⚠️ No location available for refresh")
            return
        }

        // Clear cache to fresh data
        hasError = false
        errorMessage = ""
        lastFetchDate = ""

        Task {
            await fetchPrayerTimes(latitude: currentLat, longitude: currentLng)
        }
    }


}

#Preview {
    ContentView()
}
