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
    
    // MARK: - Initialization
    init() {
        loadSettings()
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
    }
    
    // MARK: - Public Methods
    func toggleNotifications() {
        if notificationsEnabled {
            // Disable notifications
            notificationsEnabled = false
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        } else {
            // Request permission and enable notifications
            requestNotificationPermission()
        }
        saveSettings()
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
    }
    
    func updateNotificationOffset(_ offset: Int) {
        notificationOffset = max(0, min(offset, 60)) // Clamp between 0 and 60 minutes
        saveSettings()
    }
    
    func updateExpirationNotificationOffset(_ offset: Int) {
        expirationNotificationOffset = max(0, min(offset, 60)) // Clamp between 0 and 60 minutes
        saveSettings()
    }
    
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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if granted {
                    self?.notificationsEnabled = true
                    print("Notification permission granted")
                } else {
                    self?.notificationsEnabled = false
                    self?.showingPermissionAlert = true
                    print("Notification permission denied")
                }
                self?.saveSettings()
            }
        }
    }
    
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
}
