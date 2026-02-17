//
//  SharedDataManager.swift
//  Noorani
//
//  Copyright © 2025 AP Bros. All rights reserved.
//

import Foundation

/// Manages shared data for background tasks and future widget support
/// Stores prayer times and user preferences for background access
class SharedDataManager {
    static let shared = SharedDataManager()

    // Use App Groups for widget/extension data sharing
    private let appGroupId = "group.com.apbros.noorani"

    private var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupId) ?? UserDefaults.standard
    }

    private init() {}

    // MARK: - Prayer Times

    /// Save prayer times for background access
    func savePrayerTimes(_ prayerTimes: [String: Date]) {
        let defaults = sharedDefaults

        // Convert Date to TimeInterval for storage
        var timeIntervals: [String: TimeInterval] = [:]
        for (name, date) in prayerTimes {
            timeIntervals[name] = date.timeIntervalSince1970
        }

        defaults.set(timeIntervals, forKey: "prayerTimes")
        defaults.set(Date().timeIntervalSince1970, forKey: "prayerTimesUpdatedAt")

        print("✅ SharedDataManager: Saved prayer times")
    }

    /// Load prayer times from shared storage
    func loadPrayerTimes() -> [String: Date]? {
        let defaults = sharedDefaults

        guard let timeIntervals = defaults.dictionary(forKey: "prayerTimes") as? [String: TimeInterval] else {
            return nil
        }

        var prayerTimes: [String: Date] = [:]
        for (name, interval) in timeIntervals {
            prayerTimes[name] = Date(timeIntervalSince1970: interval)
        }

        return prayerTimes
    }

    // MARK: - Next Prayer Info

    /// Save next prayer information for background access
    func saveNextPrayerInfo(
        name: String,
        time: Date,
        icon: String
    ) {
        let defaults = sharedDefaults

        defaults.set(name, forKey: "nextPrayerName")
        defaults.set(time.timeIntervalSince1970, forKey: "nextPrayerTime")
        defaults.set(icon, forKey: "nextPrayerIcon")

        print("✅ SharedDataManager: Saved next prayer info (\(name))")
    }

    /// Load next prayer name
    func getNextPrayerName() -> String? {
        sharedDefaults.string(forKey: "nextPrayerName")
    }

    /// Load next prayer time
    func getNextPrayerTime() -> Date? {
        let interval = sharedDefaults.double(forKey: "nextPrayerTime")
        guard interval > 0 else {
            return nil
        }
        return Date(timeIntervalSince1970: interval)
    }

    /// Load next prayer icon
    func getNextPrayerIcon() -> String? {
        sharedDefaults.string(forKey: "nextPrayerIcon")
    }

    // MARK: - Live Activities Support

    /// Save Live Activities master toggle preference
    func saveLiveActivityPreference(enabled: Bool) {
        sharedDefaults.set(enabled, forKey: "liveActivitiesEnabled")
        print("✅ SharedDataManager: Live Activities enabled = \(enabled)")
    }

    /// Check if Live Activities are enabled
    func isLiveActivitiesEnabled() -> Bool {
        sharedDefaults.bool(forKey: "liveActivitiesEnabled")
    }

    /// Alias for isLiveActivitiesEnabled (used by ContentView)
    func areLiveActivitiesEnabled() -> Bool {
        isLiveActivitiesEnabled()
    }

    /// Map prayer names to their main prayer equivalents for settings lookup
    /// Sunset → Maghrib, Sunrise → Fajr, Midnight → Isha
    private func mapPrayerName(_ prayer: String) -> String {
        switch prayer.lowercased() {
        case "sunset":
            return "maghrib"
        case "sunrise":
            return "fajr"
        case "midnight":
            return "isha"
        default:
            return prayer.lowercased()
        }
    }

    /// Save per-prayer Live Activity toggle
    func savePrayerLiveActivityEnabled(prayer: String, enabled: Bool) {
        let key = "\(mapPrayerName(prayer))LiveActivityEnabled"
        sharedDefaults.set(enabled, forKey: key)
    }

    /// Check if Live Activity is enabled for a specific prayer
    func isPrayerLiveActivityEnabled(prayer: String) -> Bool {
        let key = "\(mapPrayerName(prayer))LiveActivityEnabled"
        // Default to true if not set
        return sharedDefaults.object(forKey: key) == nil ? true : sharedDefaults.bool(forKey: key)
    }

    /// Save Live Activity time offset for a prayer (minutes before prayer)
    func savePrayerLiveActivityOffset(prayer: String, minutes: Int) {
        let key = "\(mapPrayerName(prayer))LiveActivityOffset"
        sharedDefaults.set(minutes, forKey: key)
    }

    /// Get Live Activity time offset for a prayer (minutes before prayer)
    func getPrayerLiveActivityOffset(prayer: String) -> Int {
        let key = "\(mapPrayerName(prayer))LiveActivityOffset"
        let offset = sharedDefaults.integer(forKey: key)
        // Default to 30 minutes if not set
        return offset > 0 ? offset : 30
    }

    /// Check if Live Activity should start for a prayer based on settings and time window
    func shouldStartLiveActivity(prayerName: String, targetTime: Date) -> Bool {
        // Check master toggle
        guard isLiveActivitiesEnabled() else {
            return false
        }

        // Check per-prayer toggle (uses mapped prayer name)
        guard isPrayerLiveActivityEnabled(prayer: prayerName) else {
            return false
        }

        // Check time window (uses mapped prayer name)
        let offsetMinutes = getPrayerLiveActivityOffset(prayer: prayerName)
        let timeUntilPrayer = targetTime.timeIntervalSince(Date())

        // Activity should start if we're within the offset window and before prayer time
        return timeUntilPrayer > 0 && timeUntilPrayer <= TimeInterval(offsetMinutes * 60)
    }

    /// Save time format preference (12 or 24 hour)
    func saveTimeFormat(_ format: String) {
        sharedDefaults.set(format, forKey: "timeFormat")
    }

    /// Get time format preference
    func getTimeFormat() -> String {
        sharedDefaults.string(forKey: "timeFormat") ?? "12"
    }
}
