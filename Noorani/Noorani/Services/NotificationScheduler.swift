//
//  NotificationScheduler.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
//

import Foundation
import UserNotifications

/// Manages scheduling and cancellation of prayer time notifications
final class NotificationScheduler {

    // MARK: - Singleton
    static let shared = NotificationScheduler()

    private init() {}

    // MARK: - Public Methods

    /// Schedule all prayer notifications based on user preferences and prayer times
    func scheduleAllNotifications(
        prayerTimes: [String: Date],
        tomorrowPrayerTimes: [String: Date] = [:]
    ) {
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else {
            print("NotificationScheduler: Notifications disabled, skipping scheduling")
            return
        }

        // Cancel all existing notifications before rescheduling
        cancelAllNotifications()

        let calendar = Calendar.current
        let now = Date()

        // Schedule start notifications for each prayer
        for (prayerName, prayerTime) in prayerTimes {
            guard shouldScheduleStartNotification(for: prayerName) else { continue }

            let offset = getStartNotificationOffset(for: prayerName)
            let notificationTime = calendar.date(
                byAdding: .minute,
                value: -offset,
                to: prayerTime
            ) ?? prayerTime

            if notificationTime > now {
                scheduleNotification(
                    for: prayerName,
                    at: notificationTime,
                    prayerTime: prayerTime,
                    offset: offset
                )
            }
        }

        // Schedule tomorrow's Fajr
        if let tomorrowFajr = tomorrowPrayerTimes["Fajr"],
           shouldScheduleStartNotification(for: "Fajr") {
            let offset = getStartNotificationOffset(for: "Fajr")
            let notificationTime = calendar.date(
                byAdding: .minute,
                value: -offset,
                to: tomorrowFajr
            ) ?? tomorrowFajr

            if notificationTime > now {
                scheduleNotification(
                    for: "Fajr",
                    at: notificationTime,
                    prayerTime: tomorrowFajr,
                    offset: offset,
                    isTomorrow: true
                )
            }
        }

        // Schedule smart expiration notifications
        scheduleSmartExpirationNotifications(prayerTimes: prayerTimes)

        print("NotificationScheduler: Scheduled all notifications with per-prayer settings")
    }

    /// Cancel all pending prayer notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("NotificationScheduler: Cancelled all pending notifications")
    }

    /// Cancel notifications for a specific prayer
    func cancelNotification(for prayer: String) {
        let identifiers = [
            "prayer_\(prayer.lowercased())",
            "prayer_\(prayer.lowercased())_tomorrow",
            "expiration_\(prayer.lowercased())",
            "expiration_grouped_dhuhr", // Clean up grouped identifiers
            "expiration_grouped_maghrib"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    // MARK: - Private Methods

    private func shouldScheduleStartNotification(for prayer: String) -> Bool {
        let key = "\(prayer.lowercased())StartNotificationEnabled"
        switch prayer.lowercased() {
        case "fajr", "dhuhr", "asr", "maghrib", "isha":
            return UserDefaults.standard.object(forKey: key) as? Bool ?? true
        default:
            return UserDefaults.standard.object(forKey: key) as? Bool ?? false
        }
    }

    private func shouldScheduleExpireNotification(for prayer: String) -> Bool {
        let key = "\(prayer.lowercased())ExpireNotificationEnabled"
        return UserDefaults.standard.object(forKey: key) as? Bool ?? false
    }

    private func getStartNotificationOffset(for prayer: String) -> Int {
        let key = "\(prayer.lowercased())StartNotificationOffset"
        return UserDefaults.standard.object(forKey: key) as? Int ?? 0
    }

    private func getExpireNotificationOffset(for prayer: String) -> Int {
        let key = "\(prayer.lowercased())ExpireNotificationOffset"
        return UserDefaults.standard.object(forKey: key) as? Int ?? 15
    }

    private func scheduleNotification(
        for prayer: String,
        at notificationTime: Date,
        prayerTime: Date,
        offset: Int,
        isTomorrow: Bool = false
    ) {
        let content = UNMutableNotificationContent()

        let timeFormatter = DateFormatter()
        let timeFormat = UserDefaults.standard.string(forKey: "timeFormat") ?? "12"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = timeFormat == "24" ? "HH:mm" : "h:mm a"
        let formattedTime = timeFormatter.string(from: prayerTime)

        content.title = "\(prayer) Prayer"
        if offset > 0 {
            content.body = "\(prayer) prayer in \(offset) minutes at \(formattedTime)"
        } else {
            content.body = "It's time for \(prayer) prayer (\(formattedTime))"
        }
        content.sound = .default
        content.badge = 0

        content.userInfo = [
            "prayerName": prayer,
            "prayerTime": prayerTime.timeIntervalSince1970,
            "notificationType": "prayerReminder"
        ]

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: notificationTime
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let identifier = isTomorrow ? "prayer_\(prayer.lowercased())_tomorrow" : "prayer_\(prayer.lowercased())"

        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    // MARK: - SMART EXPIRATION LOGIC (FIXED FOR GROUPED TEXT)

    private func scheduleSmartExpirationNotifications(prayerTimes: [String: Date]) {
        let calendar = Calendar.current
        let now = Date()

        // 1. Fajr expires at Sunrise (Standalone)
        if shouldScheduleExpireNotification(for: "Fajr"),
           let sunriseTime = prayerTimes["Sunrise"] {
            let offset = getExpireNotificationOffset(for: "Fajr")
            let notificationTime = calendar.date(
                byAdding: .minute,
                value: -offset,
                to: sunriseTime
            ) ?? sunriseTime

            if notificationTime > now {
                scheduleExpirationNotification(
                    for: "Fajr",
                    at: notificationTime,
                    expirationTime: sunriseTime,
                    offset: offset
                )
            }
        }

        // 2. Dhuhr & Asr expire at Sunset
        // If EITHER is enabled, we send a notification that says "Dhuhr & Asr"
        let dhuhrEnabled = shouldScheduleExpireNotification(for: "Dhuhr")
        let asrEnabled = shouldScheduleExpireNotification(for: "Asr")

        if (dhuhrEnabled || asrEnabled), let sunsetTime = prayerTimes["Sunset"] {
            // Determine offset: Prioritize Dhuhr's offset if enabled, otherwise Asr's
            let offset = dhuhrEnabled ? getExpireOffset("Dhuhr") : getExpireOffset("Asr")

            let notificationTime = calendar.date(
                byAdding: .minute,
                value: -offset,
                to: sunsetTime
            ) ?? sunsetTime

            if notificationTime > now {
                // ALWAYS use ["Dhuhr", "Asr"] for the text, regardless of which toggle is on
                scheduleGroupedExpirationNotification(
                    for: ["Dhuhr", "Asr"],
                    at: notificationTime,
                    expirationTime: sunsetTime,
                    offset: offset
                )
            }
        }

        // 3. Maghrib & Isha expire at Midnight
        // If EITHER is enabled, we send a notification that says "Maghrib & Isha"
        let maghribEnabled = shouldScheduleExpireNotification(for: "Maghrib")
        let ishaEnabled = shouldScheduleExpireNotification(for: "Isha")

        if (maghribEnabled || ishaEnabled), let midnightTime = prayerTimes["Midnight"] {
            // Determine offset: Prioritize Maghrib's offset if enabled, otherwise Isha's
            let offset = maghribEnabled ? getExpireOffset("Maghrib") : getExpireOffset("Isha")

            let notificationTime = calendar.date(
                byAdding: .minute,
                value: -offset,
                to: midnightTime
            ) ?? midnightTime

            if notificationTime > now {
                // ALWAYS use ["Maghrib", "Isha"] for the text, regardless of which toggle is on
                scheduleGroupedExpirationNotification(
                    for: ["Maghrib", "Isha"],
                    at: notificationTime,
                    expirationTime: midnightTime,
                    offset: offset
                )
            }
        }
    }

    // Helper to safely get offset
    private func getExpireOffset(_ prayer: String) -> Int {
        return getExpireNotificationOffset(for: prayer)
    }

    private func scheduleGroupedExpirationNotification(
        for prayers: [String],
        at notificationTime: Date,
        expirationTime: Date,
        offset: Int
    ) {
        let content = UNMutableNotificationContent()

        let timeFormatter = DateFormatter()
        let timeFormat = UserDefaults.standard.string(forKey: "timeFormat") ?? "12"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = timeFormat == "24" ? "HH:mm" : "h:mm a"
        let formattedTime = timeFormatter.string(from: expirationTime)

        // Force the text to show all prayers in the array (e.g. "Dhuhr & Asr")
        let prayerList = prayers.joined(separator: " & ")
        content.title = "Prayer Time Ending Soon"
        content.body = "\(prayerList) prayer times end in \(offset) minutes at \(formattedTime)"
        content.sound = .default
        content.badge = 0

        content.userInfo = [
            "prayers": prayers,
            "expirationTime": expirationTime.timeIntervalSince1970,
            "notificationType": "groupedPrayerExpiration"
        ]

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: notificationTime
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        // Identifier uses the first prayer name (e.g. "expiration_grouped_dhuhr")
        let identifier = "expiration_grouped_\(prayers.first!.lowercased())"

        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    private func scheduleExpirationNotification(
        for prayer: String,
        at notificationTime: Date,
        expirationTime: Date,
        offset: Int
    ) {
        let content = UNMutableNotificationContent()

        let timeFormatter = DateFormatter()
        let timeFormat = UserDefaults.standard.string(forKey: "timeFormat") ?? "12"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = timeFormat == "24" ? "HH:mm" : "h:mm a"
        let formattedTime = timeFormatter.string(from: expirationTime)

        content.title = "\(prayer) Time Ending Soon"
        content.body = "\(prayer) prayer time ends in \(offset) minutes at \(formattedTime)"
        content.sound = .default
        content.badge = 0

        content.userInfo = [
            "prayerName": prayer,
            "expirationTime": expirationTime.timeIntervalSince1970,
            "notificationType": "prayerExpiration"
        ]

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: notificationTime
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let identifier = "expiration_\(prayer.lowercased())"

        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    /// Get list of all pending notifications (for debugging)
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }

    // MARK: - Extended 30-Day Notification Scheduling

    func scheduleMonthOfNotifications(monthPrayerTimes: [Date: [String: Date]]) {
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else { return }
        cancelAllNotifications()

        let calendar = Calendar.current
        let now = Date()
        let sortedDates = monthPrayerTimes.keys.sorted()
        let maxNotifications = 61
        var allPotentialNotifications: [(request: UNNotificationRequest, priority: Int, date: Date)] = []

        for (index, date) in sortedDates.enumerated() {
            guard let dayPrayerTimes = monthPrayerTimes[date] else { continue }
            let datePriority = sortedDates.count - index

            // 1. Add START notifications
            for prayer in ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"] {
                guard shouldScheduleStartNotification(for: prayer),
                      let prayerTime = dayPrayerTimes[prayer] else { continue }

                let offset = getStartNotificationOffset(for: prayer)
                let notificationTime = calendar.date(
                    byAdding: .minute,
                    value: -offset,
                    to: prayerTime
                ) ?? prayerTime

                guard notificationTime > now else { continue }

                if let request = createNotificationRequest(
                    for: prayer,
                    at: notificationTime,
                    prayerTime: prayerTime,
                    offset: offset,
                    dayDate: date
                ) {
                    let priority = datePriority * 10 + 5
                    allPotentialNotifications.append((request, priority, date))
                }
            }

            // 2. Add EXPIRATION notifications

            // Fajr -> Sunrise
            if shouldScheduleExpireNotification(for: "Fajr"),
               let sunriseTime = dayPrayerTimes["Sunrise"] {
                let offset = getExpireNotificationOffset(for: "Fajr")
                let notificationTime = calendar.date(
                    byAdding: .minute,
                    value: -offset,
                    to: sunriseTime
                ) ?? sunriseTime

                if notificationTime > now,
                   let request = createExpirationNotificationRequest(
                       for: "Fajr",
                       at: notificationTime,
                       expirationTime: sunriseTime,
                       offset: offset,
                       dayDate: date
                   ) {
                    allPotentialNotifications.append((request, datePriority * 10 + 3, date))
                }
            }

            // Dhuhr & Asr -> Sunset (ALWAYS display grouped text if EITHER is enabled)
            let dhuhrEnabled = shouldScheduleExpireNotification(for: "Dhuhr")
            let asrEnabled = shouldScheduleExpireNotification(for: "Asr")

            if (dhuhrEnabled || asrEnabled), let sunsetTime = dayPrayerTimes["Sunset"] {
                let offset = dhuhrEnabled ? getExpireOffset("Dhuhr") : getExpireOffset("Asr")
                let notificationTime = calendar.date(
                    byAdding: .minute,
                    value: -offset,
                    to: sunsetTime
                ) ?? sunsetTime

                if notificationTime > now {
                    // Explicitly force both names in the list
                    if let request = createGroupedExpirationRequest(
                        for: ["Dhuhr", "Asr"],
                        at: notificationTime,
                        expirationTime: sunsetTime,
                        offset: offset,
                        dayDate: date
                    ) {
                        allPotentialNotifications.append((request, datePriority * 10 + 3, date))
                    }
                }
            }

            // Maghrib & Isha -> Midnight (ALWAYS display grouped text if EITHER is enabled)
            let maghribEnabled = shouldScheduleExpireNotification(for: "Maghrib")
            let ishaEnabled = shouldScheduleExpireNotification(for: "Isha")

            if (maghribEnabled || ishaEnabled), let midnightTime = dayPrayerTimes["Midnight"] {
                let offset = maghribEnabled ? getExpireOffset("Maghrib") : getExpireOffset("Isha")
                let notificationTime = calendar.date(
                    byAdding: .minute,
                    value: -offset,
                    to: midnightTime
                ) ?? midnightTime

                if notificationTime > now {
                    // Explicitly force both names in the list
                    if let request = createGroupedExpirationRequest(
                        for: ["Maghrib", "Isha"],
                        at: notificationTime,
                        expirationTime: midnightTime,
                        offset: offset,
                        dayDate: date
                    ) {
                        allPotentialNotifications.append((request, datePriority * 10 + 3, date))
                    }
                }
            }
        }

        // Sort and filter (Max 64)
        allPotentialNotifications.sort { $0.priority > $1.priority }
        var notificationRequests: [UNNotificationRequest] = []
        for notification in allPotentialNotifications.prefix(maxNotifications) {
            notificationRequests.append(notification.request)
        }

        // Add reminders
        if sortedDates.count >= 28 {
            let day28 = sortedDates[min(27, sortedDates.count - 1)]
            if let reminderRequest = createRefreshReminderNotification(for: day28) {
                notificationRequests.append(reminderRequest)
            }
        }
        if sortedDates.count >= 30 {
            let day30 = sortedDates[min(29, sortedDates.count - 1)]
            if let finalRequest = createFinalReminderNotification(for: day30) {
                notificationRequests.append(finalRequest)
            }
        }

        // Schedule
        let center = UNUserNotificationCenter.current()
        for request in notificationRequests {
            center.add(request)
        }

        if let lastDate = sortedDates.last {
            UserDefaults.standard.set(lastDate.timeIntervalSince1970, forKey: "lastScheduledNotificationDate")
        }
    }

    private func createNotificationRequest(
        for prayer: String,
        at notificationTime: Date,
        prayerTime: Date,
        offset: Int,
        dayDate: Date
    ) -> UNNotificationRequest? {
        let content = UNMutableNotificationContent()
        let timeFormatter = DateFormatter()
        let timeFormat = UserDefaults.standard.string(forKey: "timeFormat") ?? "12"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = timeFormat == "24" ? "HH:mm" : "h:mm a"
        let formattedTime = timeFormatter.string(from: prayerTime)

        content.title = "\(prayer) Prayer"
        content.body = offset > 0 ? "\(prayer) prayer in \(offset) minutes at \(formattedTime)" : "It's time for \(prayer) prayer (\(formattedTime))"
        content.sound = .default
        content.badge = 0
        content.userInfo = ["prayerName": prayer, "prayerTime": prayerTime.timeIntervalSince1970, "notificationType": "prayerReminder"]

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: dayDate)
        let identifier = "prayer_\(prayer.lowercased())_\(dateString)"

        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    private func createExpirationNotificationRequest(
        for prayer: String,
        at notificationTime: Date,
        expirationTime: Date,
        offset: Int,
        dayDate: Date
    ) -> UNNotificationRequest? {
        let content = UNMutableNotificationContent()
        let timeFormatter = DateFormatter()
        let timeFormat = UserDefaults.standard.string(forKey: "timeFormat") ?? "12"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = timeFormat == "24" ? "HH:mm" : "h:mm a"
        let formattedTime = timeFormatter.string(from: expirationTime)

        content.title = "\(prayer) Time Ending Soon"
        content.body = "\(prayer) prayer time ends in \(offset) minutes at \(formattedTime)"
        content.sound = .default
        content.badge = 0
        content.userInfo = ["prayerName": prayer, "expirationTime": expirationTime.timeIntervalSince1970, "notificationType": "prayerExpiration"]

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: dayDate)
        let identifier = "expiration_\(prayer.lowercased())_\(dateString)"

        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    private func createGroupedExpirationRequest(
        for prayers: [String],
        at notificationTime: Date,
        expirationTime: Date,
        offset: Int,
        dayDate: Date
    ) -> UNNotificationRequest? {
        let content = UNMutableNotificationContent()
        let timeFormatter = DateFormatter()
        let timeFormat = UserDefaults.standard.string(forKey: "timeFormat") ?? "12"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = timeFormat == "24" ? "HH:mm" : "h:mm a"
        let formattedTime = timeFormatter.string(from: expirationTime)

        let prayerList = prayers.joined(separator: " & ")
        content.title = "Prayer Time Ending Soon"
        content.body = "\(prayerList) prayer times end in \(offset) minutes at \(formattedTime)"
        content.sound = .default
        content.badge = 0
        content.userInfo = ["prayers": prayers, "expirationTime": expirationTime.timeIntervalSince1970, "notificationType": "groupedPrayerExpiration"]

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: dayDate)
        let identifier = "expiration_grouped_\(prayers.first!.lowercased())_\(dateString)"

        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    private func createRefreshReminderNotification(for date: Date) -> UNNotificationRequest? {
        let content = UNMutableNotificationContent()
        content.title = "Prayer Notifications Expiring Soon"
        content.body = "Open Noorani to refresh your prayer notifications for the next 30 days"
        content.sound = .default
        content.badge = 0
        content.userInfo = ["notificationType": "refreshReminder"]

        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = 9
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: "refresh_reminder", content: content, trigger: trigger)
    }

    private func createFinalReminderNotification(for date: Date) -> UNNotificationRequest? {
        let content = UNMutableNotificationContent()
        content.title = "Prayer Notifications Expired"
        content.body = "Open Noorani now to continue receiving prayer time reminders"
        content.sound = .default
        content.badge = 0
        content.userInfo = ["notificationType": "finalReminder"]

        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = 9
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: "final_reminder", content: content, trigger: trigger)
    }
}
