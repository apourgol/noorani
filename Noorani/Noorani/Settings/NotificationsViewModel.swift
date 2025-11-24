//
//  NotificationsViewModel.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
 
  

//

import Foundation
import SwiftUI
import UserNotifications

@MainActor
class NotificationsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var notificationsEnabled: Bool = false
    @Published var fajrNotification: Bool = true
    @Published var sunriseNotification: Bool = false
    @Published var dhuhrNotification: Bool = true
    @Published var asrNotification: Bool = true
    @Published var sunsetNotification: Bool = false
    @Published var maghribNotification: Bool = true
    @Published var ishaNotification: Bool = true
    @Published var midnightNotification: Bool = false
    @Published var notificationOffset: Int = 0 // Minutes before prayer
    @Published var expirationNotificationOffset: Int = 15 // Minutes before expiration
    @Published var showingPermissionAlert: Bool = false

    // LIVE ACTIVITIES DISABLED - LOCAL NOTIFICATIONS ONLY
    // @Published var liveActivitiesEnabled: Bool = false
    // @Published var liveActivityStartOffset: Int = 30
    @Published var pendingNotificationsCount: Int = 0

    // Per-prayer Live Activity toggles (DISABLED)
    // @Published var fajrLiveActivity: Bool = true
    // @Published var dhuhrLiveActivity: Bool = true
    // @Published var asrLiveActivity: Bool = true
    // @Published var maghribLiveActivity: Bool = true
    // @Published var ishaLiveActivity: Bool = true

    // Per-prayer notification settings (start notifications)
    @Published var fajrStartNotificationEnabled: Bool = true
    @Published var dhuhrStartNotificationEnabled: Bool = true
    @Published var asrStartNotificationEnabled: Bool = false  // OFF by default for Shia schedule
    @Published var maghribStartNotificationEnabled: Bool = true
    @Published var ishaStartNotificationEnabled: Bool = false  // OFF by default for Shia schedule

    // Per-prayer notification offsets (start)
    @Published var fajrStartNotificationOffset: Int = 0
    @Published var dhuhrStartNotificationOffset: Int = 0
    @Published var asrStartNotificationOffset: Int = 0
    @Published var maghribStartNotificationOffset: Int = 0
    @Published var ishaStartNotificationOffset: Int = 0

    // Per-prayer notification settings (expiration notifications)
    @Published var fajrExpireNotificationEnabled: Bool = false
    @Published var dhuhrExpireNotificationEnabled: Bool = false
    @Published var asrExpireNotificationEnabled: Bool = false
    @Published var maghribExpireNotificationEnabled: Bool = false
    @Published var ishaExpireNotificationEnabled: Bool = false

    // Per-prayer expiration notification offsets
    @Published var fajrExpireNotificationOffset: Int = 15
    @Published var dhuhrExpireNotificationOffset: Int = 15
    @Published var asrExpireNotificationOffset: Int = 15
    @Published var maghribExpireNotificationOffset: Int = 15
    @Published var ishaExpireNotificationOffset: Int = 15

    // Reference to prayer times fetcher for rescheduling
    weak var prayerTimesFetcher: PrayerTimesFetcher?

    // MARK: - Initialization
    init() {
        loadSettings()
        checkNotificationPermission()
        updatePendingNotificationsCount()
    }
    
    // MARK: - Private Methods
    private func loadSettings() {
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        fajrNotification = UserDefaults.standard.object(forKey: "fajrNotification") as? Bool ?? true
        sunriseNotification = UserDefaults.standard.bool(forKey: "sunriseNotification")
        dhuhrNotification = UserDefaults.standard.object(forKey: "dhuhrNotification") as? Bool ?? true
        asrNotification = UserDefaults.standard.object(forKey: "asrNotification") as? Bool ?? true
        sunsetNotification = UserDefaults.standard.bool(forKey: "sunsetNotification")
        maghribNotification = UserDefaults.standard.object(forKey: "maghribNotification") as? Bool ?? true
        ishaNotification = UserDefaults.standard.object(forKey: "ishaNotification") as? Bool ?? true
        midnightNotification = UserDefaults.standard.bool(forKey: "midnightNotification")
        notificationOffset = UserDefaults.standard.integer(forKey: "notificationOffset")
        expirationNotificationOffset = UserDefaults.standard.object(forKey: "expirationNotificationOffset") as? Int ?? 15
        // LIVE ACTIVITIES DISABLED
        // liveActivitiesEnabled = UserDefaults.standard.bool(forKey: "liveActivitiesEnabled")
        // liveActivityStartOffset = UserDefaults.standard.object(forKey: "liveActivityStartOffset") as? Int ?? 30

        // Load per-prayer Live Activity settings (DISABLED)
        // fajrLiveActivity = UserDefaults.standard.object(forKey: "fajrLiveActivity") as? Bool ?? true
        // dhuhrLiveActivity = UserDefaults.standard.object(forKey: "dhuhrLiveActivity") as? Bool ?? true
        // asrLiveActivity = UserDefaults.standard.object(forKey: "asrLiveActivity") as? Bool ?? true
        // maghribLiveActivity = UserDefaults.standard.object(forKey: "maghribLiveActivity") as? Bool ?? true
        // ishaLiveActivity = UserDefaults.standard.object(forKey: "ishaLiveActivity") as? Bool ?? true

        // Load per-prayer start notification settings
        fajrStartNotificationEnabled = UserDefaults.standard.object(forKey: "fajrStartNotificationEnabled") as? Bool ?? true
        dhuhrStartNotificationEnabled = UserDefaults.standard.object(forKey: "dhuhrStartNotificationEnabled") as? Bool ?? true
        asrStartNotificationEnabled = UserDefaults.standard.object(forKey: "asrStartNotificationEnabled") as? Bool ?? false  // OFF by default for Shia
        maghribStartNotificationEnabled = UserDefaults.standard.object(forKey: "maghribStartNotificationEnabled") as? Bool ?? true
        ishaStartNotificationEnabled = UserDefaults.standard.object(forKey: "ishaStartNotificationEnabled") as? Bool ?? false  // OFF by default for Shia

        // Load per-prayer start notification offsets
        fajrStartNotificationOffset = UserDefaults.standard.object(forKey: "fajrStartNotificationOffset") as? Int ?? 0
        dhuhrStartNotificationOffset = UserDefaults.standard.object(forKey: "dhuhrStartNotificationOffset") as? Int ?? 0
        asrStartNotificationOffset = UserDefaults.standard.object(forKey: "asrStartNotificationOffset") as? Int ?? 0
        maghribStartNotificationOffset = UserDefaults.standard.object(forKey: "maghribStartNotificationOffset") as? Int ?? 0
        ishaStartNotificationOffset = UserDefaults.standard.object(forKey: "ishaStartNotificationOffset") as? Int ?? 0

        // Load per-prayer expire notification settings
        fajrExpireNotificationEnabled = UserDefaults.standard.object(forKey: "fajrExpireNotificationEnabled") as? Bool ?? false
        dhuhrExpireNotificationEnabled = UserDefaults.standard.object(forKey: "dhuhrExpireNotificationEnabled") as? Bool ?? false
        asrExpireNotificationEnabled = UserDefaults.standard.object(forKey: "asrExpireNotificationEnabled") as? Bool ?? false
        maghribExpireNotificationEnabled = UserDefaults.standard.object(forKey: "maghribExpireNotificationEnabled") as? Bool ?? false
        ishaExpireNotificationEnabled = UserDefaults.standard.object(forKey: "ishaExpireNotificationEnabled") as? Bool ?? false

        // Load per-prayer expire notification offsets
        fajrExpireNotificationOffset = UserDefaults.standard.object(forKey: "fajrExpireNotificationOffset") as? Int ?? 15
        dhuhrExpireNotificationOffset = UserDefaults.standard.object(forKey: "dhuhrExpireNotificationOffset") as? Int ?? 15
        asrExpireNotificationOffset = UserDefaults.standard.object(forKey: "asrExpireNotificationOffset") as? Int ?? 15
        maghribExpireNotificationOffset = UserDefaults.standard.object(forKey: "maghribExpireNotificationOffset") as? Int ?? 15
        ishaExpireNotificationOffset = UserDefaults.standard.object(forKey: "ishaExpireNotificationOffset") as? Int ?? 15
    }

    private func saveSettings() {
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(fajrNotification, forKey: "fajrNotification")
        UserDefaults.standard.set(sunriseNotification, forKey: "sunriseNotification")
        UserDefaults.standard.set(dhuhrNotification, forKey: "dhuhrNotification")
        UserDefaults.standard.set(asrNotification, forKey: "asrNotification")
        UserDefaults.standard.set(sunsetNotification, forKey: "sunsetNotification")
        UserDefaults.standard.set(maghribNotification, forKey: "maghribNotification")
        UserDefaults.standard.set(ishaNotification, forKey: "ishaNotification")
        UserDefaults.standard.set(midnightNotification, forKey: "midnightNotification")
        UserDefaults.standard.set(notificationOffset, forKey: "notificationOffset")
        UserDefaults.standard.set(expirationNotificationOffset, forKey: "expirationNotificationOffset")
        // LIVE ACTIVITIES DISABLED
        // UserDefaults.standard.set(liveActivitiesEnabled, forKey: "liveActivitiesEnabled")
        // UserDefaults.standard.set(liveActivityStartOffset, forKey: "liveActivityStartOffset")

        // Save per-prayer Live Activity settings (DISABLED)
        // UserDefaults.standard.set(fajrLiveActivity, forKey: "fajrLiveActivity")
        // UserDefaults.standard.set(dhuhrLiveActivity, forKey: "dhuhrLiveActivity")
        // UserDefaults.standard.set(asrLiveActivity, forKey: "asrLiveActivity")
        // UserDefaults.standard.set(maghribLiveActivity, forKey: "maghribLiveActivity")
        // UserDefaults.standard.set(ishaLiveActivity, forKey: "ishaLiveActivity")

        // Save per-prayer start notification settings
        UserDefaults.standard.set(fajrStartNotificationEnabled, forKey: "fajrStartNotificationEnabled")
        UserDefaults.standard.set(dhuhrStartNotificationEnabled, forKey: "dhuhrStartNotificationEnabled")
        UserDefaults.standard.set(asrStartNotificationEnabled, forKey: "asrStartNotificationEnabled")
        UserDefaults.standard.set(maghribStartNotificationEnabled, forKey: "maghribStartNotificationEnabled")
        UserDefaults.standard.set(ishaStartNotificationEnabled, forKey: "ishaStartNotificationEnabled")

        // Save per-prayer start notification offsets
        UserDefaults.standard.set(fajrStartNotificationOffset, forKey: "fajrStartNotificationOffset")
        UserDefaults.standard.set(dhuhrStartNotificationOffset, forKey: "dhuhrStartNotificationOffset")
        UserDefaults.standard.set(asrStartNotificationOffset, forKey: "asrStartNotificationOffset")
        UserDefaults.standard.set(maghribStartNotificationOffset, forKey: "maghribStartNotificationOffset")
        UserDefaults.standard.set(ishaStartNotificationOffset, forKey: "ishaStartNotificationOffset")

        // Save per-prayer expire notification settings
        UserDefaults.standard.set(fajrExpireNotificationEnabled, forKey: "fajrExpireNotificationEnabled")
        UserDefaults.standard.set(dhuhrExpireNotificationEnabled, forKey: "dhuhrExpireNotificationEnabled")
        UserDefaults.standard.set(asrExpireNotificationEnabled, forKey: "asrExpireNotificationEnabled")
        UserDefaults.standard.set(maghribExpireNotificationEnabled, forKey: "maghribExpireNotificationEnabled")
        UserDefaults.standard.set(ishaExpireNotificationEnabled, forKey: "ishaExpireNotificationEnabled")

        // Save per-prayer expire notification offsets
        UserDefaults.standard.set(fajrExpireNotificationOffset, forKey: "fajrExpireNotificationOffset")
        UserDefaults.standard.set(dhuhrExpireNotificationOffset, forKey: "dhuhrExpireNotificationOffset")
        UserDefaults.standard.set(asrExpireNotificationOffset, forKey: "asrExpireNotificationOffset")
        UserDefaults.standard.set(maghribExpireNotificationOffset, forKey: "maghribExpireNotificationOffset")
        UserDefaults.standard.set(ishaExpireNotificationOffset, forKey: "ishaExpireNotificationOffset")
    }
    
    // MARK: - Public Methods
    func toggleNotifications() {
        if notificationsEnabled {
            // Disable notifications
            notificationsEnabled = false
            NotificationScheduler.shared.cancelAllNotifications()
            saveSettings()
            updatePendingNotificationsCount()
        } else {
            // Request permission and enable notifications
            requestNotificationPermission()
        }
    }

    func updatePrayerNotification(prayer: String, enabled: Bool) {
        switch prayer.lowercased() {
        case "fajr":
            fajrNotification = enabled
        case "sunrise":
            sunriseNotification = enabled
        case "dhuhr":
            dhuhrNotification = enabled
        case "asr":
            asrNotification = enabled
        case "sunset":
            sunsetNotification = enabled
        case "maghrib":
            maghribNotification = enabled
        case "isha":
            ishaNotification = enabled
        case "midnight":
            midnightNotification = enabled
        default:
            break
        }
        saveSettings()
        rescheduleNotifications()

        // LIVE ACTIVITIES DISABLED - No Firestore sync
        // if liveActivitiesEnabled {
        //     syncToFirestore()
        // }
    }

    func updateNotificationOffset(_ offset: Int) {
        notificationOffset = max(0, min(offset, 30)) // Clamp between 0 and 30 minutes
        saveSettings()
        rescheduleNotifications()
    }

    func updateExpirationNotificationOffset(_ offset: Int) {
        expirationNotificationOffset = max(0, min(offset, 30)) // Clamp between 0 and 30 minutes
        saveSettings()
        rescheduleNotifications()
    }

    // LIVE ACTIVITIES DISABLED
    /*
    func updateLiveActivityStartOffset(_ offset: Int) {
        // Clamp to allowed range: 5-180 minutes
        let clampedValue = max(5, min(offset, 180))

        // Only update and sync if value actually changed
        guard clampedValue != liveActivityStartOffset else {
            return // No change, skip unnecessary writes
        }

        liveActivityStartOffset = clampedValue
        saveSettings()

        // Sync to Firestore if Live Activities are enabled
        if liveActivitiesEnabled {
            syncToFirestore()
        }
    }

    func toggleLiveActivities() {
        liveActivitiesEnabled.toggle()
        saveSettings()

        // Sync to Firestore for remote push-to-start
        if liveActivitiesEnabled {
            print("🔔 Live Activities enabled, syncing to Firestore...")
            syncToFirestore()
        } else {
            print("🔕 Live Activities disabled")
        }
    }

    func updatePrayerLiveActivity(prayer: String, enabled: Bool) {
        switch prayer.lowercased() {
        case "fajr":
            fajrLiveActivity = enabled
        case "dhuhr":
            dhuhrLiveActivity = enabled
        case "asr":
            asrLiveActivity = enabled
        case "maghrib":
            maghribLiveActivity = enabled
        case "isha":
            ishaLiveActivity = enabled
        default:
            break
        }
        saveSettings()

        // Sync to Firestore if Live Activities are enabled
        if liveActivitiesEnabled {
            syncToFirestore()
        }
    }
    */

    /// Update whether start notification is enabled for a specific prayer
    func updatePrayerStartNotificationEnabled(prayer: String, enabled: Bool) {
        switch prayer.lowercased() {
        case "fajr":
            fajrStartNotificationEnabled = enabled
        case "dhuhr":
            dhuhrStartNotificationEnabled = enabled
        case "asr":
            asrStartNotificationEnabled = enabled
        case "maghrib":
            maghribStartNotificationEnabled = enabled
        case "isha":
            ishaStartNotificationEnabled = enabled
        default:
            break
        }
        saveSettings()
        rescheduleNotifications()

        // LIVE ACTIVITIES DISABLED - No Firestore sync
        // if liveActivitiesEnabled {
        //     syncToFirestore()
        // }
    }

    /// Update start notification offset for a specific prayer
    func updatePrayerStartNotificationOffset(prayer: String, offset: Int) {
        let clampedOffset = max(0, min(offset, 60)) // Clamp between 0 and 60

        switch prayer.lowercased() {
        case "fajr":
            fajrStartNotificationOffset = clampedOffset
        case "dhuhr":
            dhuhrStartNotificationOffset = clampedOffset
        case "asr":
            asrStartNotificationOffset = clampedOffset
        case "maghrib":
            maghribStartNotificationOffset = clampedOffset
        case "isha":
            ishaStartNotificationOffset = clampedOffset
        default:
            break
        }
        saveSettings()
        rescheduleNotifications()
    }

    /// Update whether expiration notification is enabled for a specific prayer
    func updatePrayerExpireNotificationEnabled(prayer: String, enabled: Bool) {
        switch prayer.lowercased() {
        case "fajr":
            fajrExpireNotificationEnabled = enabled
        case "dhuhr":
            dhuhrExpireNotificationEnabled = enabled
        case "asr":
            asrExpireNotificationEnabled = enabled
        case "maghrib":
            maghribExpireNotificationEnabled = enabled
        case "isha":
            ishaExpireNotificationEnabled = enabled
        default:
            break
        }
        saveSettings()
        rescheduleNotifications()

        // LIVE ACTIVITIES DISABLED - No Firestore sync
        // if liveActivitiesEnabled {
        //     syncToFirestore()
        // }
    }

    /// Update expiration notification offset for a specific prayer
    func updatePrayerExpireNotificationOffset(prayer: String, offset: Int) {
        let clampedOffset = max(0, min(offset, 60)) // Clamp between 0 and 60

        switch prayer.lowercased() {
        case "fajr":
            fajrExpireNotificationOffset = clampedOffset
        case "dhuhr":
            dhuhrExpireNotificationOffset = clampedOffset
        case "asr":
            asrExpireNotificationOffset = clampedOffset
        case "maghrib":
            maghribExpireNotificationOffset = clampedOffset
        case "isha":
            ishaExpireNotificationOffset = clampedOffset
        default:
            break
        }
        saveSettings()
        rescheduleNotifications()
    }

    // LIVE ACTIVITIES DISABLED - No Firestore sync
    /*
    /// Sync current settings to Firestore for remote Live Activity scheduling
    func syncToFirestore() {
        if #available(iOS 17.2, *) {
            Task { @MainActor in
                print("📤 Syncing settings to Firestore...")
                await PushToStartManager.shared.syncAllSettings()
                print("✅ Firestore sync complete")
            }
        } else {
            print("⚠️ iOS 17.2+ required for push-to-start Live Activities")
        }
    }
    */
    
    // MARK: - Prayer Expiration Logic
    // Returns the expiration time for a given prayer
    func getExpirationTime(for prayer: String, prayerTimes: [String: Date]) -> Date? {
        switch prayer.lowercased() {
        case "fajr":
            return prayerTimes["Sunrise"] // Fajr expires at Sunrise
        case "dhuhr":
            // Dhuhr expires at Sunset (or Asr if enabled)
            return prayerTimes["Asr"] ?? prayerTimes["Sunset"]
        case "asr":
            return prayerTimes["Sunset"] // Asr expires at Sunset
        case "maghrib", "isha":
            return prayerTimes["Midnight"] // Maghrib and Isha expire at Midnight
        default:
            return nil // Sunrise, Sunset, Midnight don't have expiration times
        }
    }
    
    private func requestNotificationPermission() {
        NotificationScheduler.shared.requestAuthorization { [weak self] granted in
            guard let self = self else { return }
            if granted {
                self.notificationsEnabled = true
                self.saveSettings()
                self.rescheduleNotifications()
                print("Notification permission granted")
            } else {
                self.notificationsEnabled = false
                self.showingPermissionAlert = true
                self.saveSettings()
                print("Notification permission denied")
            }
            self.updatePendingNotificationsCount()
        }
    }

    func checkNotificationPermission() {
        NotificationScheduler.shared.checkAuthorizationStatus { [weak self] status in
            guard let self = self else { return }
            let wasEnabled = self.notificationsEnabled
            self.notificationsEnabled = status == .authorized

            // If permission was revoked, update saved settings
            if wasEnabled && !self.notificationsEnabled {
                self.saveSettings()
            }
        }
    }

    // MARK: - Scheduling Methods

    private func rescheduleNotifications() {
        // Trigger rescheduling through PrayerTimesFetcher if available
        prayerTimesFetcher?.rescheduleNotifications()
        updatePendingNotificationsCount()
    }

    func updatePendingNotificationsCount() {
        NotificationScheduler.shared.getPendingNotifications { [weak self] requests in
            self?.pendingNotificationsCount = requests.count
        }
    }

    /// Debug method to list all pending notifications
    func listPendingNotifications(completion: @escaping ([String]) -> Void) {
        NotificationScheduler.shared.getPendingNotifications { requests in
            let descriptions = requests.map { request in
                let trigger = request.trigger as? UNCalendarNotificationTrigger
                let triggerDateComponents = trigger?.dateComponents
                let dateString = triggerDateComponents.map { components in
                    let date = Calendar.current.date(from: components) ?? Date()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM d, h:mm a"
                    return formatter.string(from: date)
                } ?? "Unknown"
                return "\(request.identifier): \(dateString)"
            }
            completion(descriptions)
        }
    }
}
