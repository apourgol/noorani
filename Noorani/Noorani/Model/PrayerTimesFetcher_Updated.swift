//
//  PrayerTimesFetcher.swift
//  Noorani
//
//  Created by Amin Pourgol on 10/4/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Prayer Calculation Method Models
struct CalculationMethod: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let params: MethodParams?
    let location: MethodLocation?
}

struct MethodParams: Codable, Hashable {
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

struct MethodLocation: Codable, Hashable {
    let latitude: Double
    let longitude: Double
}

struct CalculationMethodsResponse: Codable {
    let code: Int
    let status: String
    let data: [String: CalculationMethod]
}

// MARK: - Prayer Times API Response Models
// Note: Prayer response models are defined in PrayerResponse.swift

class PrayerTimesFetcher: ObservableObject {
    @Published var timings: [String: String] = [:]
    @Published var readableDate: String = ""
    @Published var hijriDate: String = ""
    @Published var prayerTimes: [String: Date] = [:] // Today's prayer times only
    @Published var nextPrayerName: String = ""
    @Published var nextPrayerTime: Date?
    @Published var countdown: String = ""
    @Published var isLoading: Bool = false
    @Published var availableMethods: [CalculationMethod] = []
    @Published var selectedMethod: CalculationMethod?
    @Published var hasError: Bool = false
    @Published var errorMessage: String = ""

    @AppStorage("currentLat") var currentLat: Double = 0.0
    @AppStorage("currentLng") var currentLng: Double = 0.0
    @AppStorage("lastFetchDate") private var lastFetchDate: String = ""
    @AppStorage("cachedTimingsData") private var cachedTimingsData: Data = Data()
    @AppStorage("selectedMethodId") private var selectedMethodId: Int = 7 // Default to TEHRAN for Shia
    @AppStorage("cachedMethodsData") private var cachedMethodsData: Data = Data()
    
    // Prayer visibility toggles - only for prayers users might want to hide
    @AppStorage("showAsr") var showAsr: Bool = false // Hidden by default for Shia
    @AppStorage("showIsha") var showIsha: Bool = false // Hidden by default for Shia
    @AppStorage("showMidnight") var showMidnight: Bool = true // Visible by default

    private var timer: Timer?
    private var _cachedVisibleKeys: [String]?

    init() {
        loadCachedMethods()
        if availableMethods.isEmpty {
            loadDefaultMethods()
        }
        setSelectedMethod()
        loadCachedTimings()
        
        // Start countdown if we have prayer times loaded
        if !prayerTimes.isEmpty {
            updateNextPrayer()
        }
    }
    
    private func loadCachedTimings() {
        guard !cachedTimingsData.isEmpty else { return }
        
        // Check if cached data is from today
        let today = apiDateFormatter.string(from: Date())
        guard lastFetchDate == today else { 
            print("Cached data is outdated")
            return 
        }
        
        loadFromCache()
    }
    
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

    // MARK: - Method Management
    private func loadDefaultMethods() {
        // Limited to main calculation methods for customer-facing simplicity
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
                let methodsDict = try JSONDecoder().decode([String: CalculationMethod].self, from: data)
                availableMethods = Array(methodsDict.values).sorted { $0.id < $1.id }
                cacheMethods()
            } catch {
                print("Error loading default methods: \(error)")
            }
        }
    }

    private func loadCachedMethods() {
        guard !cachedMethodsData.isEmpty else { return }
        do {
            availableMethods = try JSONDecoder().decode([CalculationMethod].self, from: cachedMethodsData)
        } catch {
            print("Error loading cached methods: \(error)")
        }
    }

    private func cacheMethods() {
        do {
            cachedMethodsData = try JSONEncoder().encode(availableMethods)
        } catch {
            print("Error caching methods: \(error)")
        }
    }

    private func setSelectedMethod() {
        if let method = availableMethods.first(where: { $0.id == selectedMethodId }) {
            selectedMethod = method
        } else if let defaultMethod = availableMethods.first(where: { $0.id == 7 }) {
            // Default to TEHRAN (Shia method)
            selectedMethod = defaultMethod
        } else {
            selectedMethod = availableMethods.first
        }
    }

    func selectMethod(_ method: CalculationMethod) {
        selectedMethod = method
        selectedMethodId = method.id

        // Clear cached data to force refresh with new method
        lastFetchDate = ""
        cachedTimingsData = Data()

        // Refetch prayer times if we have location
        if currentLat != 0.0 && currentLng != 0.0 {
            fetchPrayerTimes(latitude: currentLat, longitude: currentLng)
        }
    }

    // Helper method to get recommended methods based on sect
    func getRecommendedMethods(for sect: String = "shia") -> [CalculationMethod] {
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

    // Check if we need to fetch new data
    private func shouldFetchNewData(for latitude: Double, longitude: Double) -> Bool {
        let today = apiDateFormatter.string(from: Date())
        let locationChanged = abs(currentLat - latitude) > 0.001 || abs(currentLng - longitude) > 0.001
        let dateChanged = lastFetchDate != today
        return dateChanged || locationChanged || prayerTimes.isEmpty
    }

    func updateNextPrayer() {
        let now = Date()

        // Get all upcoming prayer times for today, sorted by time
        let upcomingPrayers = prayerTimes
            .filter { $0.value > now }
            .sorted { $0.value < $1.value }

        if let next = upcomingPrayers.first {
            nextPrayerName = next.key
            nextPrayerTime = next.value
            startCountdown(to: next.value)
        } else if !prayerTimes.isEmpty {
            // No more prayers today, but we have prayer times loaded
            nextPrayerName = "Fajr (Tomorrow)"
            nextPrayerTime = nil
            countdown = "—"
            timer?.invalidate()
        } else {
            // No prayer times loaded yet
            nextPrayerName = "Loading..."
            nextPrayerTime = nil
            countdown = ""
            timer?.invalidate()
        }
    }

    private var allowedPrayerKeys: Set<String> {
        // Return all prayer keys that we want to process from the API
        // We process all of them but only show the ones user has enabled
        return ["Fajr", "Sunrise", "Dhuhr", "Asr", "Sunset", "Maghrib", "Isha", "Midnight"]
    }
    
    // Get visible prayers based on user preferences in correct chronological order
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
        
        // Midnight goes at the very end if enabled
        if showMidnight { keys.append("Midnight") }
        
        return keys
    }
    
    // Call this when prayer visibility settings change to clear cache
    func clearVisibleKeysCache() {
        _cachedVisibleKeys = nil
    }

    private func startCountdown(to date: Date) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            let interval = date.timeIntervalSince(Date())
            if interval <= 0 {
                self?.countdown = "Now"
                self?.timer?.invalidate()
            } else {
                self?.countdown = self?.format(interval) ?? ""
            }
        }
    }

    private func format(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    func fetchPrayerTimes(latitude: Double, longitude: Double) {
        // Prevent multiple concurrent requests
        guard !isLoading else {
            print("Already loading prayer times, skipping request")
            return
        }
        
        // Check if we need to fetch new data
        if !shouldFetchNewData(for: latitude, longitude: longitude) {
            print("Using cached prayer times")
            loadFromCache()
            updateNextPrayer()
            return
        }

        // Ensure we have a calculation method
        if selectedMethod == nil {
            print("No calculation method selected, trying to load default")
            if let defaultMethod = availableMethods.first(where: { $0.id == selectedMethodId }) ?? availableMethods.first {
                selectedMethod = defaultMethod
                print("Loaded default method: \(defaultMethod.name)")
            } else {
                print("No calculation methods available")
                return
            }
        }
        
        guard let method = selectedMethod else {
            print("Failed to get calculation method")
            return
        }

        DispatchQueue.main.async {
            self.isLoading = true
        }

        // Use the selected calculation method
        let todayString = apiDateFormatter.string(from: Date())
        // Revert to working API call without invalid timezone parameter
        let urlString = "https://api.aladhan.com/v1/timings/\(todayString)?latitude=\(latitude)&longitude=\(longitude)&method=\(method.id)&iso8601=true&midnightMode=1"

        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { 
                self.isLoading = false 
                print("Invalid URL generated")
            }
            return
        }

        print("Fetching prayer times for: \(todayString) using method: \(method.name) (ID: \(method.id))")
        print("Request URL: \(urlString)")

        // Create request with timeout
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0 // 10 seconds timeout
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            defer {
                DispatchQueue.main.async { 
                    self.isLoading = false 
                }
            }

            // Check for network errors
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.hasError = true
                    self.errorMessage = "Network connection failed. Using cached data."
                    // Try to load from cache as fallback
                    self.loadFromCache()
                    self.updateNextPrayer()
                }
                return
            }
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse, 
               httpResponse.statusCode != 200 {
                print("HTTP Error: \(httpResponse.statusCode)")
                print("Request URL: \(url.absoluteString)")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Error response body: \(responseString)")
                }
                DispatchQueue.main.async {
                    self.hasError = true
                    self.errorMessage = "Server error (\(httpResponse.statusCode)). Using cached data."
                    self.loadFromCache()
                    self.updateNextPrayer()
                }
                return
            }

            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    self.loadFromCache()
                    self.updateNextPrayer()
                }
                return
            }

            do {
                let response = try JSONDecoder().decode(PrayerResponse.self, from: data)

                // Process data on background thread
                let processedData = self.processSingleDayResponse(response)

                // Update UI on main thread
                DispatchQueue.main.async {
                    // Clear any previous errors
                    self.hasError = false
                    self.errorMessage = ""
                    
                    self.timings = processedData.timings
                    self.readableDate = processedData.readableDate
                    self.hijriDate = processedData.hijriDate
                    self.prayerTimes = processedData.prayerTimes

                    // Update cached values
                    self.lastFetchDate = self.apiDateFormatter.string(from: Date())
                    self.currentLat = latitude
                    self.currentLng = longitude
                    
                    // Save to cache
                    self.saveToCache(response)

                    self.updateNextPrayer()
                    print("Prayer times updated successfully")
                }
            } catch {
                print("Decoding error: \(error)")
                DispatchQueue.main.async {
                    self.hasError = true
                    self.errorMessage = "Data parsing error. Using cached data."
                    // Try to load from cache as fallback
                    self.loadFromCache()
                    self.updateNextPrayer()
                }
            }
        }.resume()
    }
    
    private func saveToCache(_ response: PrayerResponse) {
        if let encoded = try? JSONEncoder().encode(response) {
            cachedTimingsData = encoded
        }
    }
    
    private func loadFromCache() {
        guard !cachedTimingsData.isEmpty else { return }
        
        do {
            let response = try JSONDecoder().decode(PrayerResponse.self, from: cachedTimingsData)
            let processed = processSingleDayResponse(response)
            
            timings = processed.timings
            readableDate = processed.readableDate
            hijriDate = processed.hijriDate
            prayerTimes = processed.prayerTimes
            
            print("Loaded prayer times from cache")
        } catch {
            print("Failed to load from cache: \(error)")
        }
    }

    private func processSingleDayResponse(_ response: PrayerResponse) -> (timings: [String: String], readableDate: String, hijriDate: String, prayerTimes: [String: Date]) {
        var resultPrayerTimes: [String: Date] = [:]

        // Convert timings to Date objects - include ALL prayers for today
        for (name, timeString) in response.data.timings {
            guard allowedPrayerKeys.contains(name) else { continue }
            if let prayerDate = isoDateFormatter.date(from: timeString) {
                resultPrayerTimes[name] = prayerDate
            } else {
                print("Failed to parse \(name): \(timeString)")
            }
        }

        return (
            timings: response.data.timings,
            readableDate: response.data.date.readable,
            hijriDate: response.data.date.hijri.date,
            prayerTimes: resultPrayerTimes
        )
    }
    
    func resetToDefaults() {
        // Reset to default calculation method
        self.selectedMethod = availableMethods.first { $0.id == 7 } ?? availableMethods.first // Default to TEHRAN (Shia method)
        if let defaultMethod = self.selectedMethod {
            selectedMethodId = defaultMethod.id
        }
        
        // Clear stored preferences
        UserDefaults.standard.removeObject(forKey: "selectedCalculationMethodID")
        lastFetchDate = ""
        cachedTimingsData = Data()
        
        // Reset prayer visibility to defaults (Shia configuration)
        showAsr = false // Hidden for Shia
        showIsha = false // Hidden for Shia
        showMidnight = true
        
        // Clear AppStorage keys for prayer visibility
        UserDefaults.standard.removeObject(forKey: "showAsr")
        UserDefaults.standard.removeObject(forKey: "showIsha") 
        UserDefaults.standard.removeObject(forKey: "showMidnight")
        
        // Clear errors
        hasError = false
        errorMessage = ""
        
        // Refresh data with defaults if we have location
        if currentLat != 0.0 && currentLng != 0.0 {
            fetchPrayerTimes(latitude: currentLat, longitude: currentLng)
        }
    }
    
    func refreshPrayerTimes() {
        guard currentLat != 0.0 && currentLng != 0.0 else {
            print("No location available for refresh")
            return
        }
        
        // Clear cache to force fresh data
        hasError = false
        errorMessage = ""
        lastFetchDate = ""
        cachedTimingsData = Data()
        
        fetchPrayerTimes(latitude: currentLat, longitude: currentLng)
    }
}

#Preview {
    ContentView()
}
