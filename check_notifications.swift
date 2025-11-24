#!/usr/bin/env swift

// Debug script to check scheduled notifications
// Run this in your app's debug console or add to a debug view

import UserNotifications
import Foundation

let center = UNUserNotificationCenter.current()

center.getPendingNotificationRequests { requests in
    print("\n" + String(repeating: "=", count: 80))
    print("📅 SCHEDULED NOTIFICATIONS DEBUG REPORT")
    print(String(repeating: "=", count: 80))
    print("Total pending notifications: \(requests.count)")
    print(String(repeating: "=", count: 80))

    if requests.isEmpty {
        print("❌ NO NOTIFICATIONS SCHEDULED!")
        print("   This means notifications will NOT fire without opening the app.")
        exit(0)
    }

    // Group by prayer type
    var fajrNotifications: [UNNotificationRequest] = []
    var otherPrayerNotifications: [UNNotificationRequest] = []
    var expirationNotifications: [UNNotificationRequest] = []
    var reminderNotifications: [UNNotificationRequest] = []

    for request in requests {
        let id = request.identifier
        if id.contains("fajr") && !id.contains("expiration") {
            fajrNotifications.append(request)
        } else if id.hasPrefix("prayer_") && !id.contains("expiration") {
            otherPrayerNotifications.append(request)
        } else if id.contains("expiration") {
            expirationNotifications.append(request)
        } else if id.contains("reminder") {
            reminderNotifications.append(request)
        }
    }

    print("\n🌅 FAJR NOTIFICATIONS: \(fajrNotifications.count)")
    print(String(repeating: "-", count: 80))
    for request in fajrNotifications.sorted(by: {
        guard let t1 = ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate(),
              let t2 = ($1.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() else { return false }
        return t1 < t2
    }) {
        if let trigger = request.trigger as? UNCalendarNotificationTrigger,
           let triggerDate = trigger.nextTriggerDate() {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd, yyyy 'at' h:mm a"
            print("   ✓ \(request.identifier)")
            print("     └─ Fires: \(formatter.string(from: triggerDate))")
        }
    }

    print("\n🕌 OTHER PRAYER NOTIFICATIONS: \(otherPrayerNotifications.count)")
    print(String(repeating: "-", count: 80))

    // Count by prayer type
    let dhuhrCount = otherPrayerNotifications.filter { $0.identifier.contains("dhuhr") }.count
    let asrCount = otherPrayerNotifications.filter { $0.identifier.contains("asr") }.count
    let maghribCount = otherPrayerNotifications.filter { $0.identifier.contains("maghrib") }.count
    let ishaCount = otherPrayerNotifications.filter { $0.identifier.contains("isha") }.count

    print("   Dhuhr: \(dhuhrCount) | Asr: \(asrCount) | Maghrib: \(maghribCount) | Isha: \(ishaCount)")

    print("\n⏰ EXPIRATION NOTIFICATIONS: \(expirationNotifications.count)")
    print(String(repeating: "-", count: 80))

    print("\n🔔 REFRESH REMINDERS: \(reminderNotifications.count)")
    print(String(repeating: "-", count: 80))
    for request in reminderNotifications {
        if let trigger = request.trigger as? UNCalendarNotificationTrigger,
           let triggerDate = trigger.nextTriggerDate() {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd, yyyy 'at' h:mm a"
            print("   ✓ \(request.identifier)")
            print("     └─ Fires: \(formatter.string(from: triggerDate))")
        }
    }

    // Check date range
    print("\n📆 DATE RANGE ANALYSIS")
    print(String(repeating: "-", count: 80))

    var allDates: [Date] = []
    for request in requests {
        if let trigger = request.trigger as? UNCalendarNotificationTrigger,
           let triggerDate = trigger.nextTriggerDate() {
            allDates.append(triggerDate)
        }
    }

    if let earliest = allDates.min(), let latest = allDates.max() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        let daysDiff = Calendar.current.dateComponents([.day], from: earliest, to: latest).day ?? 0
        print("   First notification: \(formatter.string(from: earliest))")
        print("   Last notification:  \(formatter.string(from: latest))")
        print("   Coverage: \(daysDiff) days")

        if daysDiff < 25 {
            print("\n   ⚠️  WARNING: Less than 30 days scheduled!")
            print("   ⚠️  This suggests 30-day scheduling FAILED and fell back to daily mode.")
        } else {
            print("\n   ✅ Good: Full month coverage detected")
        }
    }

    // Check for Fajr gap
    print("\n🔍 FAJR COVERAGE CHECK")
    print(String(repeating: "-", count: 80))

    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    var fajrDates: [Date] = []
    for request in fajrNotifications {
        if let trigger = request.trigger as? UNCalendarNotificationTrigger,
           let triggerDate = trigger.nextTriggerDate() {
            fajrDates.append(calendar.startOfDay(for: triggerDate))
        }
    }
    fajrDates = Array(Set(fajrDates)).sorted()

    if fajrDates.count <= 2 {
        print("   ❌ CRITICAL: Only \(fajrDates.count) Fajr notification(s) scheduled!")
        print("   ❌ You will NOT receive Fajr after tomorrow without opening the app!")
    } else {
        print("   ✅ \(fajrDates.count) Fajr notifications scheduled")

        // Check for gaps
        for i in 1..<fajrDates.count {
            let daysBetween = calendar.dateComponents([.day], from: fajrDates[i-1], to: fajrDates[i]).day ?? 0
            if daysBetween > 1 {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                print("   ⚠️  Gap detected: \(daysBetween) days between \(formatter.string(from: fajrDates[i-1])) and \(formatter.string(from: fajrDates[i]))")
            }
        }
    }

    // Check UserDefaults
    print("\n💾 SCHEDULING METADATA")
    print(String(repeating: "-", count: 80))

    let lastScheduled = UserDefaults.standard.double(forKey: "lastScheduledNotificationDate")
    if lastScheduled > 0 {
        let lastDate = Date(timeIntervalSince1970: lastScheduled)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy 'at' h:mm a"
        let daysSince = (Date().timeIntervalSince1970 - lastScheduled) / 86400
        print("   Last 30-day schedule: \(formatter.string(from: lastDate))")
        print("   Days since: \(Int(daysSince))")

        if daysSince > 7 {
            print("   ✅ Next app open will trigger 30-day refresh (7+ days passed)")
        } else {
            print("   ⏳ 30-day refresh in \(Int(7 - daysSince)) days")
        }
    } else {
        print("   ⚠️  Never scheduled 30-day notifications!")
    }

    let notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    print("   Notifications enabled: \(notificationsEnabled ? "✅ YES" : "❌ NO")")

    let currentLat = UserDefaults.standard.double(forKey: "currentLat")
    let currentLng = UserDefaults.standard.double(forKey: "currentLng")
    print("   Current location: (\(currentLat), \(currentLng))")

    if currentLat == 0.0 && currentLng == 0.0 {
        print("   ❌ INVALID LOCATION! 30-day scheduling will FAIL!")
    }

    print("\n" + String(repeating: "=", count: 80))
    print("END REPORT")
    print(String(repeating: "=", count: 80) + "\n")
}

// Keep script running
RunLoop.current.run(until: Date(timeIntervalSinceNow: 2))
