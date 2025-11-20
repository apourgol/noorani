//
//  PushToStartManager.swift
//  Noorani
//
//  Copyright © 2025 AP Bros. All rights reserved.
//

// FIREBASE DISABLED - ENTIRE FILE COMMENTED OUT
// This service is for remote Live Activity push-to-start via Firebase
// We're using local notifications only now

import Foundation
// import ActivityKit
// import FirebaseFirestore
// import FirebaseMessaging

/*
/// Manages push-to-start tokens for remote Live Activity delivery
/// This service handles registration with Apple's push-to-start system
/// and synchronizes tokens with Firebase for backend scheduling
@available(iOS 17.2, *)
@MainActor
class PushToStartManager: ObservableObject {
    static let shared = PushToStartManager()

    // MARK: - Published Properties
    @Published var isRegistered: Bool = false
    @Published var lastTokenUpdate: Date?
    @Published var registrationError: String?

    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private var tokenUpdateTask: Task<Void, Never>?
    private var activityUpdatesTask: Task<Void, Never>?
    private var userId: String {
        // Use device identifier or Firebase Auth UID
        // For now, using device identifier
        UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }

    // MARK: - Initialization
    private init() {}

    deinit {
        tokenUpdateTask?.cancel()
        activityUpdatesTask?.cancel()
    }

    // MARK: - Public Methods

    /// Start listening for push-to-start token updates
    func startTokenRegistration() {
        print("🚀 PushToStartManager: Starting token registration...")

        let authInfo = ActivityAuthorizationInfo()
        print("🔍 PushToStartManager: Activities enabled: \(authInfo.areActivitiesEnabled)")
        print("🔍 PushToStartManager: Frequent updates allowed: \(authInfo.frequentPushesEnabled)")

        guard authInfo.areActivitiesEnabled else {
            registrationError = "Live Activities are not enabled"
            print("❌ PushToStartManager: Live Activities not enabled in system settings")
            return
        }

        tokenUpdateTask?.cancel()

        tokenUpdateTask = Task {
            print("👂 PushToStartManager: Listening for push-to-start tokens...")

            // Listen for push-to-start token updates
            for await tokenData in Activity<PrayerCountdownAttributes>.pushToStartTokenUpdates {
                let tokenString = tokenData.map { String(format: "%02x", $0) }.joined()

                print("✅ PushToStartManager: Received push-to-start token: \(tokenString)")
                print("📝 PushToStartManager: Token length: \(tokenString.count) characters")

                await savePushToStartToken(tokenString)

                // Automatically sync all settings when token is received
                // This ensures Firestore has complete data (token + location + preferences)
                await syncAllSettings()

                await MainActor.run {
                    self.isRegistered = true
                    self.lastTokenUpdate = Date()
                    self.registrationError = nil
                }
            }
        }

        // Also start observing for remotely started activities
        startActivityUpdatesObservation()

        print("✅ PushToStartManager: Token registration started successfully")
        print("📱 PushToStartManager: Device ID for Firestore: \(userId)")
    }

    /// Observe for remotely started Live Activities (push-to-start)
    private func startActivityUpdatesObservation() {
        activityUpdatesTask?.cancel()

        activityUpdatesTask = Task {
            print("👁️ PushToStartManager: Observing for remotely started activities...")

            for await activityUpdate in Activity<PrayerCountdownAttributes>.activityUpdates {
                print("🎉 PushToStartManager: Activity update received!")
                print("   Activity ID: \(activityUpdate.id)")
                print("   Content State: \(activityUpdate.content.state)")

                // Check if this was remotely started
                let currentActivities = Activity<PrayerCountdownAttributes>.activities
                print("📊 PushToStartManager: Total active activities: \(currentActivities.count)")

                for activity in currentActivities {
                    print("   - \(activity.id): \(activity.content.state.prayerName)")
                }
            }
        }
    }

    /// Stop listening for token updates
    func stopTokenRegistration() {
        tokenUpdateTask?.cancel()
        tokenUpdateTask = nil
        isRegistered = false
        print("PushToStartManager: Stopped token registration")
    }

    /// Save user preferences to Firestore for backend scheduling
    func saveUserPreferences(
        latitude: Double,
        longitude: Double,
        timezone: String,
        liveActivityStartOffset: Int,
        enabledPrayers: [String],
        calculationMethod: String = "ISNA"
    ) async {
        print("💾 PushToStartManager: Saving user preferences to Firestore...")

        let userDoc = db.collection("users").document(userId)

        let preferences: [String: Any] = [
            "location": [
                "latitude": latitude,
                "longitude": longitude,
                "timezone": timezone
            ],
            "preferences": [
                "liveActivityStartOffset": liveActivityStartOffset,
                "enabledPrayers": enabledPrayers,
                "calculationMethod": calculationMethod
            ],
            "updatedAt": FieldValue.serverTimestamp()
        ]

        print("📝 Document path: users/\(userId)")
        print("📦 Data to save: \(preferences)")

        do {
            try await userDoc.setData(preferences, merge: true)
            print("✅ PushToStartManager: User preferences saved to Firestore successfully!")
        } catch {
            print("❌ PushToStartManager: FIRESTORE ERROR: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            await MainActor.run {
                self.registrationError = "Failed to save preferences: \(error.localizedDescription)"
            }
        }
    }

    /// Save FCM token for fallback notifications
    func saveFCMToken(_ token: String) async {
        let userDoc = db.collection("users").document(userId)

        do {
            try await userDoc.setData([
                "fcmToken": token,
                "fcmTokenUpdatedAt": FieldValue.serverTimestamp()
            ], merge: true)
            print("PushToStartManager: FCM token saved to Firestore")
        } catch {
            print("PushToStartManager: Error saving FCM token: \(error.localizedDescription)")
        }
    }

    /// Sync all current settings to Firestore
    func syncAllSettings() async {
        print("📊 PushToStartManager: Starting syncAllSettings...")

        // Get current location and preferences (using same keys as PrayerTimesFetcher)
        let latitude = UserDefaults.standard.double(forKey: "currentLat")
        let longitude = UserDefaults.standard.double(forKey: "currentLng")
        let timezone = TimeZone.current.identifier
        let liveActivityStartOffset = UserDefaults.standard.object(forKey: "liveActivityStartOffset") as? Int ?? 30
        let calculationMethodId = UserDefaults.standard.object(forKey: "selectedMethodId") as? Int ?? 7 // Default to TEHRAN (Jafari) for Shia

        print("📍 Location: lat=\(latitude), lng=\(longitude)")
        print("🕐 Timezone: \(timezone)")
        print("⏰ Live Activity offset: \(liveActivityStartOffset) minutes")
        print("📖 Calculation method ID: \(calculationMethodId)")

        // Skip if no location data yet
        guard latitude != 0 && longitude != 0 else {
            print("⚠️ PushToStartManager: No location data available yet, skipping sync")
            print("💡 Tip: Make sure the app has fetched prayer times first (needs location)")
            return
        }

        // Get enabled prayers for Live Activities (separate from notification settings)
        // CRITICAL: Respect prayer visibility (showAsr/showIsha) settings
        var enabledPrayers: [String] = []
        if UserDefaults.standard.object(forKey: "fajrLiveActivity") as? Bool ?? true {
            enabledPrayers.append("Fajr")
        }
        if UserDefaults.standard.object(forKey: "dhuhrLiveActivity") as? Bool ?? true {
            enabledPrayers.append("Dhuhr")
        }
        // Only add Asr if it's visible in app settings
        if UserDefaults.standard.bool(forKey: "showAsr") &&
           (UserDefaults.standard.object(forKey: "asrLiveActivity") as? Bool ?? true) {
            enabledPrayers.append("Asr")
        }
        if UserDefaults.standard.object(forKey: "maghribLiveActivity") as? Bool ?? true {
            enabledPrayers.append("Maghrib")
        }
        // Only add Isha if it's visible in app settings
        if UserDefaults.standard.bool(forKey: "showIsha") &&
           (UserDefaults.standard.object(forKey: "ishaLiveActivity") as? Bool ?? true) {
            enabledPrayers.append("Isha")
        }

        print("🕌 Enabled prayers: \(enabledPrayers)")
        print("👤 User ID: \(userId)")

        await saveUserPreferences(
            latitude: latitude,
            longitude: longitude,
            timezone: timezone,
            liveActivityStartOffset: liveActivityStartOffset,
            enabledPrayers: enabledPrayers,
            calculationMethod: String(calculationMethodId)
        )
    }

    // MARK: - Private Methods

    private func savePushToStartToken(_ token: String) async {
        let userDoc = db.collection("users").document(userId)

        do {
            try await userDoc.setData([
                "pushToStartToken": token,
                "tokenUpdatedAt": FieldValue.serverTimestamp(),
                "deviceInfo": [
                    "model": UIDevice.current.model,
                    "systemVersion": UIDevice.current.systemVersion,
                    "name": UIDevice.current.name
                ]
            ], merge: true)

            print("PushToStartManager: Push-to-start token saved to Firestore")
        } catch {
            print("PushToStartManager: Error saving token: \(error.localizedDescription)")
            await MainActor.run {
                self.registrationError = "Failed to save token: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Fallback for older iOS versions
class PushToStartManagerFallback {
    static let shared = PushToStartManagerFallback()

    func startTokenRegistration() {
        print("PushToStartManager: Push-to-start requires iOS 17.2+")
    }

    func stopTokenRegistration() {
        // No-op
    }
}
*/
