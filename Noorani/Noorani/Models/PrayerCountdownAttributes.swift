//
//  PrayerCountdownAttributes.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
//

// LIVE ACTIVITIES DISABLED - ENTIRE FILE COMMENTED OUT
// This model is for Live Activity attributes which we've removed

import Foundation
// import ActivityKit

/*
/// ActivityKit attributes for Prayer Countdown Live Activity
/// This model defines the static and dynamic content for the Live Activity
@available(iOS 16.1, *)
struct PrayerCountdownAttributes: ActivityAttributes {

    // MARK: - Content State (Dynamic data that changes)
    public struct ContentState: Codable, Hashable {
        /// Name of the upcoming prayer (e.g., "Fajr", "Dhuhr")
        var prayerName: String

        /// Target time when the prayer starts
        var targetTime: Date

        /// Remaining seconds until prayer time (for manual updates if needed)
        var remainingSeconds: Int

        /// Whether to show the countdown timer
        var showTimer: Bool

        /// Optional message to display
        var message: String?

        // MARK: - Custom Coding for APNs Push-to-Start
        enum CodingKeys: String, CodingKey {
            case prayerName, targetTime, remainingSeconds, showTimer, message
        }

        public init(prayerName: String, targetTime: Date, remainingSeconds: Int, showTimer: Bool, message: String?) {
            self.prayerName = prayerName
            self.targetTime = targetTime
            self.remainingSeconds = remainingSeconds
            self.showTimer = showTimer
            self.message = message
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            prayerName = try container.decode(String.self, forKey: .prayerName)
            remainingSeconds = try container.decode(Int.self, forKey: .remainingSeconds)
            showTimer = try container.decode(Bool.self, forKey: .showTimer)
            message = try container.decodeIfPresent(String.self, forKey: .message)

            // Decode targetTime from Unix timestamp (seconds since epoch)
            // APNs sends this as a number (Int or Double)
            if let timestamp = try? container.decode(Double.self, forKey: .targetTime) {
                targetTime = Date(timeIntervalSince1970: timestamp)
            } else if let timestamp = try? container.decode(Int.self, forKey: .targetTime) {
                targetTime = Date(timeIntervalSince1970: TimeInterval(timestamp))
            } else {
                // Fallback to ISO string if needed
                let dateString = try container.decode(String.self, forKey: .targetTime)
                let formatter = ISO8601DateFormatter()
                targetTime = formatter.date(from: dateString) ?? Date()
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(prayerName, forKey: .prayerName)
            try container.encode(targetTime, forKey: .targetTime)
            try container.encode(remainingSeconds, forKey: .remainingSeconds)
            try container.encode(showTimer, forKey: .showTimer)
            try container.encodeIfPresent(message, forKey: .message)
        }
    }

    // MARK: - Static Attributes (Don't change during activity lifetime)

    /// Icon for the prayer (SF Symbol name)
    var prayerIcon: String

    /// Color theme identifier for the prayer
    var colorTheme: String

    /// Formatted prayer time string for display
    var formattedPrayerTime: String

    /// Whether this is an expiration warning (vs upcoming prayer)
    var isExpirationWarning: Bool
}

// MARK: - Prayer Icon Mapping
@available(iOS 16.1, *)
extension PrayerCountdownAttributes {

    /// Get the appropriate SF Symbol icon for a prayer
    static func icon(for prayer: String) -> String {
        switch prayer.lowercased() {
        case "fajr":
            return "sunrise.fill"
        case "sunrise":
            return "sun.horizon.fill"
        case "dhuhr":
            return "sun.max.fill"
        case "asr":
            return "sun.min.fill"
        case "sunset":
            return "sunset.fill"
        case "maghrib":
            return "moon.fill"
        case "isha":
            return "moon.stars.fill"
        case "midnight":
            return "moon.zzz.fill"
        default:
            return "clock.fill"
        }
    }

    /// Get a color theme identifier for a prayer
    static func colorTheme(for prayer: String) -> String {
        switch prayer.lowercased() {
        case "fajr":
            return "dawn"       // Light blue/purple
        case "sunrise":
            return "sunrise"    // Orange/yellow
        case "dhuhr":
            return "noon"       // Bright yellow
        case "asr":
            return "afternoon"  // Golden
        case "sunset":
            return "sunset"     // Orange/red
        case "maghrib":
            return "evening"    // Purple/blue
        case "isha":
            return "night"      // Dark blue
        case "midnight":
            return "midnight"   // Dark purple
        default:
            return "default"
        }
    }
}
*/
