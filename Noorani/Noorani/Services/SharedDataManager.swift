//
//  SharedDataManager.swift
//  Noorani
//
//  Copyright © 2025 AP Bros. All rights reserved.
//

// LIVE ACTIVITIES/WIDGETS DISABLED - ENTIRE FILE COMMENTED OUT
// This service shares data with widgets/Live Activities via App Groups
// We're using local notifications only now

import Foundation

/*
/// Manages shared data between main app and widget extension via App Groups
/// Used for sharing prayer times and user preferences with Live Activity widget
class SharedDataManager {
    static let shared = SharedDataManager()

    // IMPORTANT: Replace with your actual App Group identifier
    // Format: group.{your-bundle-id}
    // Example: group.com.apbros.noorani
    private let appGroupIdentifier = "group.com.apbros.noorani"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    // MARK: - Prayer Times

    /// Save prayer times for widget to access
    func savePrayerTimes(_ prayerTimes: [String: Date]) {
        guard let defaults = sharedDefaults else {
            print("SharedDataManager: App Group not configured")
            return
        }

        // Convert Date to TimeInterval for storage
        var timeIntervals: [String: TimeInterval] = [:]
        for (name, date) in prayerTimes {
            timeIntervals[name] = date.timeIntervalSince1970
        }

        defaults.set(timeIntervals, forKey: "prayerTimes")
        defaults.set(Date().timeIntervalSince1970, forKey: "prayerTimesUpdatedAt")
        defaults.synchronize()

        print("SharedDataManager: Saved prayer times to App Group")
    }

    /// Load prayer times from shared container
    func loadPrayerTimes() -> [String: Date]? {
        guard let defaults = sharedDefaults else {
            print("SharedDataManager: App Group not configured")
            return nil
        }

        guard let timeIntervals = defaults.dictionary(forKey: "prayerTimes") as? [String: TimeInterval] else {
            return nil
        }

        var prayerTimes: [String: Date] = [:]
        for (name, interval) in timeIntervals {
            prayerTimes[name] = Date(timeIntervalSince1970: interval)
        }

        return prayerTimes
    }

    // MARK: - User Preferences

    /// Save user preferences for widget
    func saveUserPreferences(
        liveActivitiesEnabled: Bool,
        liveActivityStartOffset: Int,
        fajrEnabled: Bool,
        dhuhrEnabled: Bool,
        asrEnabled: Bool,
        maghribEnabled: Bool,
        ishaEnabled: Bool
    ) {
        guard let defaults = sharedDefaults else {
            print("SharedDataManager: App Group not configured")
            return
        }

        defaults.set(liveActivitiesEnabled, forKey: "liveActivitiesEnabled")
        defaults.set(liveActivityStartOffset, forKey: "liveActivityStartOffset")
        defaults.set(fajrEnabled, forKey: "fajrLiveActivity")
        defaults.set(dhuhrEnabled, forKey: "dhuhrLiveActivity")
        defaults.set(asrEnabled, forKey: "asrLiveActivity")
        defaults.set(maghribEnabled, forKey: "maghribLiveActivity")
        defaults.set(ishaEnabled, forKey: "ishaLiveActivity")
        defaults.synchronize()

        print("SharedDataManager: Saved user preferences to App Group")
    }

    /// Load Live Activity enabled status
    func isLiveActivitiesEnabled() -> Bool {
        sharedDefaults?.bool(forKey: "liveActivitiesEnabled") ?? false
    }

    /// Load Live Activity start offset
    func getLiveActivityStartOffset() -> Int {
        sharedDefaults?.object(forKey: "liveActivityStartOffset") as? Int ?? 30
    }

    // MARK: - Next Prayer Info

    /// Save next prayer information for quick widget access
    func saveNextPrayerInfo(
        name: String,
        time: Date,
        icon: String
    ) {
        guard let defaults = sharedDefaults else {
            print("SharedDataManager: App Group not configured")
            return
        }

        defaults.set(name, forKey: "nextPrayerName")
        defaults.set(time.timeIntervalSince1970, forKey: "nextPrayerTime")
        defaults.set(icon, forKey: "nextPrayerIcon")
        defaults.synchronize()

        print("SharedDataManager: Saved next prayer info to App Group")
    }

    /// Load next prayer name
    func getNextPrayerName() -> String? {
        sharedDefaults?.string(forKey: "nextPrayerName")
    }

    /// Load next prayer time
    func getNextPrayerTime() -> Date? {
        guard let interval = sharedDefaults?.double(forKey: "nextPrayerTime"), interval > 0 else {
            return nil
        }
        return Date(timeIntervalSince1970: interval)
    }

    /// Load next prayer icon
    func getNextPrayerIcon() -> String? {
        sharedDefaults?.string(forKey: "nextPrayerIcon")
    }

    // MARK: - Location

    /// Save user location for widget
    func saveLocation(latitude: Double, longitude: Double, cityName: String?) {
        guard let defaults = sharedDefaults else {
            print("SharedDataManager: App Group not configured")
            return
        }

        defaults.set(latitude, forKey: "userLatitude")
        defaults.set(longitude, forKey: "userLongitude")
        if let city = cityName {
            defaults.set(city, forKey: "userCityName")
        }
        defaults.synchronize()

        print("SharedDataManager: Saved location to App Group")
    }

    /// Load user city name
    func getUserCityName() -> String? {
        sharedDefaults?.string(forKey: "userCityName")
    }
}
*/
