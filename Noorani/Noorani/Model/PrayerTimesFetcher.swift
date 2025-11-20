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

        // CRITICAL: Clear tomorrow's times to prevent timezone bugs
        // When switching locations, tomorrow's times from old location are invalid
        tomorrowPrayerTimes = [:]

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

                    // Schedule notifications after fetching prayer times
                    self.scheduleNotificationsIfEnabled()
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

                    // Schedule notifications after fetching prayer times
                    self.scheduleNotificationsIfEnabled()
                } catch {
                    print("❌ Decoding error: \(error)")
                    self.hasError = true
                    self.errorMessage = "Data parsing error"
                }
            }
        }.resume()
    }

    // MARK: - Notification Scheduling
    private func scheduleNotificationsIfEnabled() {
        // WIDGETS/LIVE ACTIVITIES DISABLED - saveToSharedContainer() commented out
        // saveToSharedContainer()

        // Check if notifications are enabled before scheduling
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else {
            print("📵 Notifications disabled, skipping notification scheduling")
            return
        }

        print("🔔 Scheduling prayer notifications...")

        // LIVE ACTIVITIES DISABLED
        // scheduleLiveActivitiesIfEnabled()

        // Check if we should fetch and schedule 30 days of notifications
        let lastScheduledDate = UserDefaults.standard.double(forKey: "lastScheduledNotificationDate")
        let daysSinceLastSchedule = (Date().timeIntervalSince1970 - lastScheduledDate) / 86400

        // Defer heavy notification scheduling to avoid blocking UI
        // This ensures prayer times appear instantly on first launch
        if lastScheduledDate == 0 || daysSinceLastSchedule > 7 {
            print("📅 Deferring 30-day notification fetch to background...")

            // Delay 5 seconds to ensure UI is fully rendered
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                guard let self = self else { return }

                Task(priority: .utility) {
                    print("📅 Background: Fetching 30 days of prayer times...")
                    let monthPrayerTimes = await self.fetchMonthOfPrayerTimes()

                    if !monthPrayerTimes.isEmpty {
                        NotificationScheduler.shared.scheduleMonthOfNotifications(monthPrayerTimes: monthPrayerTimes)
                        print("✅ Background: 30-day notifications scheduled")
                    } else {
                        // Fallback to single day scheduling
                        NotificationScheduler.shared.scheduleAllNotifications(
                            prayerTimes: self.prayerTimes,
                            tomorrowPrayerTimes: self.tomorrowPrayerTimes
                        )
                    }
                }
            }
        } else {
            // Use existing single day scheduling for regular updates (fast)
            // Run in background to avoid any UI blocking
            Task(priority: .utility) {
                NotificationScheduler.shared.scheduleAllNotifications(
                    prayerTimes: prayerTimes,
                    tomorrowPrayerTimes: tomorrowPrayerTimes
                )
            }
        }
    }

    // LIVE ACTIVITIES DISABLED
    /*
    private func scheduleLiveActivitiesIfEnabled() {
        guard UserDefaults.standard.bool(forKey: "liveActivitiesEnabled") else {
            print("📵 Live Activities disabled, skipping scheduling")
            return
        }

        if #available(iOS 16.1, *) {
            print("⏰ Scheduling Live Activities...")
            LiveActivityManager.shared.scheduleAllLiveActivities(
                prayerTimes: prayerTimes,
                tomorrowPrayerTimes: tomorrowPrayerTimes
            )
        }
    }
    */

    // WIDGETS/LIVE ACTIVITIES DISABLED - SharedDataManager commented out
    /*
    /// Save prayer times and preferences to shared App Group container for widget access
    private func saveToSharedContainer() {
        // Save prayer times
        SharedDataManager.shared.savePrayerTimes(prayerTimes)

        // Save next prayer info
        if !nextPrayerName.isEmpty && nextPrayerName != "Loading...",
           let nextTime = prayerTimes[nextPrayerName] {
            let icon = getPrayerIcon(for: nextPrayerName)
            SharedDataManager.shared.saveNextPrayerInfo(
                name: nextPrayerName,
                time: nextTime,
                icon: icon
            )
        }

        // LIVE ACTIVITIES DISABLED - Comment out Live Activity preference saving
        // Save user preferences
        SharedDataManager.shared.saveUserPreferences(
            liveActivitiesEnabled: UserDefaults.standard.bool(forKey: "liveActivitiesEnabled"),
            liveActivityStartOffset: UserDefaults.standard.object(forKey: "liveActivityStartOffset") as? Int ?? 30,
            fajrEnabled: UserDefaults.standard.object(forKey: "fajrNotification") as? Bool ?? true,
            dhuhrEnabled: UserDefaults.standard.object(forKey: "dhuhrNotification") as? Bool ?? true,
            asrEnabled: UserDefaults.standard.object(forKey: "asrNotification") as? Bool ?? true,
            maghribEnabled: UserDefaults.standard.object(forKey: "maghribNotification") as? Bool ?? true,
            ishaEnabled: UserDefaults.standard.object(forKey: "ishaNotification") as? Bool ?? true
        )

        // Save location
        if currentLat != 0 && currentLng != 0 {
            SharedDataManager.shared.saveLocation(
                latitude: currentLat,
                longitude: currentLng,
                cityName: nil // Can be enhanced to include city name
            )
        }

        print("✅ Saved prayer data to shared container")
    }
    */

    /// Get SF Symbol icon for a prayer
    private func getPrayerIcon(for prayerName: String) -> String {
        switch prayerName {
        case "Fajr":
            return "sunrise.fill"
        case "Sunrise":
            return "sun.horizon.fill"
        case "Dhuhr":
            return "sun.max.fill"
        case "Asr":
            return "sun.min.fill"
        case "Sunset":
            return "sunset.fill"
        case "Maghrib":
            return "moon.fill"
        case "Isha":
            return "moon.stars.fill"
        case "Midnight":
            return "moon.zzz.fill"
        default:
            return "clock.fill"
        }
    }

    /// Force reschedule all notifications (call when settings change)
    func rescheduleNotifications() {
        scheduleNotificationsIfEnabled()
    }

    // LIVE ACTIVITIES DISABLED
    /*
    /// Force reschedule Live Activities (call when settings change)
    func rescheduleLiveActivities() {
        scheduleLiveActivitiesIfEnabled()
    }
    */

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
            // No more visible prayers today - check tomorrow's times for ANY upcoming prayer
            let upcomingTomorrowPrayers = tomorrowPrayerTimes
                .filter { prayerName, prayerTime in
                    let isUpcoming = prayerTime > now
                    let visible = isVisible(prayer: prayerName)
                    return isUpcoming && visible
                }
                .sorted(by: { $0.value < $1.value })

            if let nextTomorrow = upcomingTomorrowPrayers.first {
                // Found an upcoming prayer in tomorrow's data
                nextPrayerName = nextTomorrow.key
                nextPrayerTime = nextTomorrow.value
                startCountdown(to: nextTomorrow.value)
                print("🌅 Next prayer: Tomorrow's \(nextTomorrow.key) at \(nextTomorrow.value)")
            } else if tomorrowPrayerTimes.isEmpty && isVisible(prayer: "Fajr") {
                // No tomorrow data yet and Fajr is visible - fetch it
                nextPrayerName = "Fajr"
                nextPrayerTime = nil
                countdown = "Loading..."
                timer?.invalidate()
                fetchTomorrowPrayerTimes()
                print("🌅 Need to fetch tomorrow's prayer times")
            } else {
                // Either:
                // 1. We have tomorrow's data but all prayers are in the past (timezone issue)
                // 2. Fajr is not visible
                // Clear stale data and show placeholder
                if !tomorrowPrayerTimes.isEmpty {
                    print("⚠️ Tomorrow's prayers are all in the past, clearing stale data")
                    tomorrowPrayerTimes = [:]
                }
                nextPrayerName = "—"
                nextPrayerTime = nil
                countdown = "—"
                timer?.invalidate()
                print("😴 No more visible upcoming prayers")
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

    // MARK: - 30-Day Prayer Times for Extended Notifications

    /// Fetch 30 days of prayer times for extended notification scheduling
    func fetchMonthOfPrayerTimes() async -> [Date: [String: Date]] {
        guard let method = selectedMethod else {
            print("❌ No calculation method selected for month fetch")
            return [:]
        }
        guard currentLat != 0.0 && currentLng != 0.0 else {
            print("❌ No location for month fetch")
            return [:]
        }

        let calendar = Calendar.current
        let today = Date()
        let year = calendar.component(.year, from: today)
        let month = calendar.component(.month, from: today)

        // Fetch current month from Aladhan Calendar API
        let urlString = "https://api.aladhan.com/v1/calendar/\(year)/\(month)?latitude=\(currentLat)&longitude=\(currentLng)&method=\(method.id)&iso8601=true&midnightMode=1"

        guard let url = URL(string: urlString) else {
            print("❌ Invalid calendar URL")
            return [:]
        }

        print("📅 Fetching month of prayer times: \(month)/\(year)")

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 30.0

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ Calendar API error")
                return [:]
            }

            let calendarResponse = try JSONDecoder().decode(CalendarPrayerResponse.self, from: data)

            var monthPrayerTimes: [Date: [String: Date]] = [:]

            for dayData in calendarResponse.data {
                // Parse the date for this day
                let dateComponents = dayData.date.gregorian
                guard let dayNum = Int(dateComponents.day),
                      let yearNum = Int(dateComponents.year) else {
                    continue
                }
                let monthNum = dateComponents.month.number

                var dateComps = DateComponents()
                dateComps.year = yearNum
                dateComps.month = monthNum
                dateComps.day = dayNum
                guard let dayDate = calendar.date(from: dateComps) else { continue }

                // Only include future dates
                guard dayDate >= calendar.startOfDay(for: today) else { continue }

                // Parse prayer times for this day
                var dayPrayerTimes: [String: Date] = [:]
                for (name, timeString) in dayData.timings {
                    guard allowedPrayerKeys.contains(name) else { continue }
                    if let prayerDate = isoDateFormatter.date(from: timeString) {
                        dayPrayerTimes[name] = prayerDate
                    }
                }

                monthPrayerTimes[dayDate] = dayPrayerTimes
            }

            // If we need more days, fetch next month too
            if monthPrayerTimes.count < 30 {
                let nextMonthTimes = await fetchNextMonthPrayerTimes(year: year, month: month)
                monthPrayerTimes.merge(nextMonthTimes) { current, _ in current }
            }

            print("✅ Fetched \(monthPrayerTimes.count) days of prayer times")
            return monthPrayerTimes

        } catch {
            print("❌ Error fetching month prayer times: \(error)")
            return [:]
        }
    }

    private func fetchNextMonthPrayerTimes(year: Int, month: Int) async -> [Date: [String: Date]] {
        guard let method = selectedMethod else { return [:] }

        let calendar = Calendar.current
        var nextMonth = month + 1
        var nextYear = year
        if nextMonth > 12 {
            nextMonth = 1
            nextYear += 1
        }

        let urlString = "https://api.aladhan.com/v1/calendar/\(nextYear)/\(nextMonth)?latitude=\(currentLat)&longitude=\(currentLng)&method=\(method.id)&iso8601=true&midnightMode=1"

        guard let url = URL(string: urlString) else { return [:] }

        print("📅 Fetching next month: \(nextMonth)/\(nextYear)")

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 30.0

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return [:]
            }

            let calendarResponse = try JSONDecoder().decode(CalendarPrayerResponse.self, from: data)

            var monthPrayerTimes: [Date: [String: Date]] = [:]
            let today = Date()

            for dayData in calendarResponse.data {
                let dateComponents = dayData.date.gregorian
                guard let dayNum = Int(dateComponents.day),
                      let yearNum = Int(dateComponents.year) else {
                    continue
                }
                let monthNum = dateComponents.month.number

                var dateComps = DateComponents()
                dateComps.year = yearNum
                dateComps.month = monthNum
                dateComps.day = dayNum
                guard let dayDate = calendar.date(from: dateComps) else { continue }

                // Only include future dates
                guard dayDate > today else { continue }

                var dayPrayerTimes: [String: Date] = [:]
                for (name, timeString) in dayData.timings {
                    guard allowedPrayerKeys.contains(name) else { continue }
                    if let prayerDate = isoDateFormatter.date(from: timeString) {
                        dayPrayerTimes[name] = prayerDate
                    }
                }

                monthPrayerTimes[dayDate] = dayPrayerTimes
            }

            return monthPrayerTimes
        } catch {
            print("❌ Error fetching next month: \(error)")
            return [:]
        }
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
