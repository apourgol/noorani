//
//  LiveActivityManager.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
//

// LIVE ACTIVITIES DISABLED - ENTIRE FILE COMMENTED OUT
// This service manages Live Activities which we've removed
// We're using local notifications only now

import Foundation
// import ActivityKit
import UserNotifications

/*
/// Manages Live Activities for prayer countdown timers
@available(iOS 16.1, *)
final class LiveActivityManager {

    // MARK: - Singleton
    static let shared = LiveActivityManager()

    private init() {}

    // MARK: - Properties

    /// Currently active prayer countdown activity
    private var currentActivity: Activity<PrayerCountdownAttributes>?

    /// Timer for scheduling Live Activity starts
    private var scheduledTimers: [Timer] = []

    // MARK: - Public Methods

    /// Schedule Live Activities for all upcoming prayers
    func scheduleAllLiveActivities(
        prayerTimes: [String: Date],
        tomorrowPrayerTimes: [String: Date] = [:]
    ) {
        guard UserDefaults.standard.bool(forKey: "liveActivitiesEnabled") else {
            print("LiveActivityManager: Live Activities disabled, skipping scheduling")
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("LiveActivityManager: Live Activities not authorized")
            return
        }

        // Cancel existing scheduled timers
        cancelAllScheduledTimers()

        let startOffset = UserDefaults.standard.object(forKey: "liveActivityStartOffset") as? Int ?? 30
        let calendar = Calendar.current
        let now = Date()

        // Schedule Live Activities for each prayer
        for (prayerName, prayerTime) in prayerTimes {
            // CRITICAL: Check if prayer is visible in app settings first
            guard isPrayerVisible(prayerName) else {
                print("LiveActivityManager: Skipping \(prayerName) - prayer is hidden in settings")
                continue
            }

            guard shouldScheduleLiveActivity(for: prayerName) else { continue }

            // Calculate when to start the Live Activity
            let activityStartTime = calendar.date(
                byAdding: .minute,
                value: -startOffset,
                to: prayerTime
            ) ?? prayerTime

            // Only schedule if start time is in the future
            if activityStartTime > now {
                scheduleActivityStart(
                    for: prayerName,
                    startAt: activityStartTime,
                    prayerTime: prayerTime
                )
            } else if prayerTime > now {
                // Prayer is coming up but start time has passed, start immediately
                startLiveActivity(for: prayerName, targetTime: prayerTime)
            }
        }

        print("LiveActivityManager: Scheduled Live Activities with \(startOffset)m offset")
    }

    /// Start a Live Activity for a specific prayer
    func startLiveActivity(for prayerName: String, targetTime: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("LiveActivityManager: Live Activities not authorized")
            return
        }

        // Prevent duplicate activities - check if one already exists
        let existingActivities = Activity<PrayerCountdownAttributes>.activities
        if !existingActivities.isEmpty {
            print("LiveActivityManager: Activity already running, ending existing first...")
            // End all existing activities synchronously before starting new one
            Task {
                for activity in existingActivities {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
        }

        // End any existing tracked activity
        endCurrentActivity()

        // Format prayer time
        let timeFormatter = DateFormatter()
        let timeFormat = UserDefaults.standard.string(forKey: "timeFormat") ?? "12"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        if timeFormat == "24" {
            timeFormatter.dateFormat = "HH:mm"
        } else {
            timeFormatter.dateFormat = "h:mm a"
        }
        let formattedTime = timeFormatter.string(from: targetTime)

        // Create attributes
        let attributes = PrayerCountdownAttributes(
            prayerIcon: PrayerCountdownAttributes.icon(for: prayerName),
            colorTheme: PrayerCountdownAttributes.colorTheme(for: prayerName),
            formattedPrayerTime: formattedTime,
            isExpirationWarning: false
        )

        // Create initial content state
        let remainingSeconds = Int(targetTime.timeIntervalSince(Date()))
        let initialState = PrayerCountdownAttributes.ContentState(
            prayerName: prayerName,
            targetTime: targetTime,
            remainingSeconds: max(0, remainingSeconds),
            showTimer: true,
            message: nil
        )

        // Configure activity content
        let content = ActivityContent(
            state: initialState,
            staleDate: targetTime.addingTimeInterval(60) // Stale 1 minute after prayer time
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: .token // Enable remote push-to-start from Cloud Functions
            )

            currentActivity = activity
            print("LiveActivityManager: Started Live Activity for \(prayerName) - ID: \(activity.id)")
            print("LiveActivityManager: Push updates ENABLED for remote control")

            // Schedule automatic end when prayer time arrives
            scheduleActivityEnd(at: targetTime)

        } catch {
            print("LiveActivityManager: Failed to start Live Activity - \(error.localizedDescription)")
        }
    }

    /// Update the current Live Activity's state
    func updateLiveActivity(newState: PrayerCountdownAttributes.ContentState) {
        guard let activity = currentActivity else {
            print("LiveActivityManager: No active Live Activity to update")
            return
        }

        let content = ActivityContent(
            state: newState,
            staleDate: newState.targetTime.addingTimeInterval(60)
        )

        Task {
            await activity.update(content)
            print("LiveActivityManager: Updated Live Activity state")
        }
    }

    /// End the current Live Activity
    func endCurrentActivity(dismissalPolicy: ActivityUIDismissalPolicy = .default) {
        guard let activity = currentActivity else { return }

        Task {
            await activity.end(nil, dismissalPolicy: dismissalPolicy)
            print("LiveActivityManager: Ended Live Activity - ID: \(activity.id)")
        }

        currentActivity = nil
    }

    /// End all Live Activities for the app
    func endAllActivities() {
        Task {
            for activity in Activity<PrayerCountdownAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            print("LiveActivityManager: Ended all Live Activities")
        }

        currentActivity = nil
        cancelAllScheduledTimers()
    }

    /// Cancel all scheduled Live Activity timers
    func cancelAllScheduledTimers() {
        scheduledTimers.forEach { $0.invalidate() }
        scheduledTimers.removeAll()
        print("LiveActivityManager: Cancelled all scheduled timers")
    }

    /// Check if Live Activities are available and authorized
    func checkAvailability() -> (available: Bool, authorized: Bool) {
        let authorized = ActivityAuthorizationInfo().areActivitiesEnabled
        return (available: true, authorized: authorized)
    }

    // MARK: - Private Methods

    private func isPrayerVisible(_ prayer: String) -> Bool {
        // Check if prayer is visible in user's prayer time settings
        // Respects showAsr and showIsha settings
        switch prayer.lowercased() {
        case "asr":
            return UserDefaults.standard.bool(forKey: "showAsr")
        case "isha":
            return UserDefaults.standard.bool(forKey: "showIsha")
        default:
            // All other prayers are always visible
            return true
        }
    }

    private func shouldScheduleLiveActivity(for prayer: String) -> Bool {
        // Check if Live Activities are enabled for this specific prayer
        // Uses separate settings from notifications for ultra customization
        let key = "\(prayer.lowercased())LiveActivity"

        let defaultValue: Bool
        switch prayer.lowercased() {
        case "fajr", "dhuhr", "asr", "maghrib", "isha":
            defaultValue = true
        default:
            defaultValue = false
        }

        return UserDefaults.standard.object(forKey: key) as? Bool ?? defaultValue
    }

    private func scheduleActivityStart(
        for prayerName: String,
        startAt: Date,
        prayerTime: Date
    ) {
        let timeInterval = startAt.timeIntervalSince(Date())
        guard timeInterval > 0 else { return }

        let timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            self?.startLiveActivity(for: prayerName, targetTime: prayerTime)
        }

        scheduledTimers.append(timer)
        print("LiveActivityManager: Scheduled \(prayerName) Live Activity to start at \(startAt)")
    }

    private func scheduleActivityEnd(at prayerTime: Date) {
        let timeInterval = prayerTime.timeIntervalSince(Date())
        guard timeInterval > 0 else { return }

        // Update activity to show "Prayer: Now" when time arrives
        let nowTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            self?.updateToNowState()
        }
        scheduledTimers.append(nowTimer)

        // End activity 3 minutes after prayer time with smooth dismissal
        let endTimer = Timer.scheduledTimer(withTimeInterval: timeInterval + 180, repeats: false) { [weak self] _ in
            self?.endCurrentActivity(dismissalPolicy: .default)
        }
        scheduledTimers.append(endTimer)
    }

    /// Update Live Activity to show "Prayer: Now" state
    private func updateToNowState() {
        guard let activity = currentActivity else {
            print("LiveActivityManager: No active Live Activity to update to Now state")
            return
        }

        // Get current state
        let currentState = activity.content.state

        // Create new state with "Now" message
        let nowState = PrayerCountdownAttributes.ContentState(
            prayerName: currentState.prayerName,
            targetTime: currentState.targetTime,
            remainingSeconds: 0,
            showTimer: false, // Hide timer, show "Now" message
            message: "Now"
        )

        let content = ActivityContent(
            state: nowState,
            staleDate: Date().addingTimeInterval(180) // Stale after 3 minutes
        )

        Task {
            await activity.update(content)
            print("LiveActivityManager: Updated to 'Now' state for \(currentState.prayerName)")
        }
    }
}

// MARK: - Fallback for older iOS versions
@available(iOS, deprecated: 16.1, message: "Use LiveActivityManager for iOS 16.1+")
final class LiveActivityManagerFallback {
    static let shared = LiveActivityManagerFallback()
    private init() {}

    func scheduleAllLiveActivities(prayerTimes: [String: Date], tomorrowPrayerTimes: [String: Date] = [:]) {
        print("LiveActivityManager: Live Activities not available on this iOS version")
    }

    func startLiveActivity(for prayerName: String, targetTime: Date) {
        print("LiveActivityManager: Live Activities not available on this iOS version")
    }

    func endAllActivities() {
        // No-op for older versions
    }

    func checkAvailability() -> (available: Bool, authorized: Bool) {
        return (available: false, authorized: false)
    }
}
*/
