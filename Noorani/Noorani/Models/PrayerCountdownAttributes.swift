//
//  PrayerCountdownAttributes.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
//

import Foundation
import ActivityKit

/// ActivityKit attributes for Prayer Countdown Live Activity
/// Simplified design following LivePolls best practices - minimal static attributes,
/// with helper functions to derive icon/color from prayer name
@available(iOS 16.1, *)
struct PrayerCountdownAttributes: ActivityAttributes {

    // MARK: - Content State (Dynamic data that updates)
    public struct ContentState: Codable, Hashable {
        /// Name of the upcoming prayer (e.g., "Fajr", "Dhuhr")
        var prayerName: String

        /// Target time when the prayer starts
        var targetTime: Date

        /// Formatted time string for display (e.g., "5:30 AM")
        var formattedTime: String

        /// Calculated remaining seconds for manual countdown display
        var remainingSeconds: Int

        /// Last update timestamp for staleness detection
        var updatedAt: Date
    }

    // MARK: - Countdown Formatting

    /// Format countdown for Lock Screen display
    /// Hours: "1 hour, 27 min" | Minutes: "27:45"
    static func formatForLockScreen(_ seconds: Int) -> String {
        guard seconds > 0 else { return "Now" }

        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            // "1 hour, 27 min" format
            if hours == 1 {
                return "1 hour, \(minutes) min"
            } else {
                return "\(hours) hours, \(minutes) min"
            }
        } else {
            // MM:SS format for under an hour
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    /// Format countdown for Dynamic Island display
    /// Hours: "1h:27m" | Minutes: "27:45"
    static func formatForDynamicIsland(_ seconds: Int) -> String {
        guard seconds > 0 else { return "Now" }

        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            // "1h:27m" compact format
            return String(format: "%dh:%02dm", hours, minutes)
        } else {
            // MM:SS format for under an hour
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    // MARK: - Static Attributes (Only truly immutable data)

    /// Unique identifier for this prayer activity (e.g., "fajr_2025-02-16")
    var prayerId: String
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

    /// Get accent color for a prayer (hex string)
    static func accentColor(for prayer: String) -> String {
        switch prayer.lowercased() {
        case "fajr":
            return "#8B5CF6"  // Purple (dawn)
        case "sunrise":
            return "#F59E0B"  // Amber
        case "dhuhr":
            return "#EAB308"  // Yellow (noon sun)
        case "asr":
            return "#F97316"  // Orange (afternoon)
        case "sunset":
            return "#EF4444"  // Red
        case "maghrib":
            return "#6366F1"  // Indigo (evening)
        case "isha":
            return "#3B82F6"  // Blue (night)
        case "midnight":
            return "#1E3A8A"  // Dark blue
        default:
            return "#D4892E"  // App accent color
        }
    }
}
