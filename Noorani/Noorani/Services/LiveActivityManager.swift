//
//  LiveActivityManager.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
//

import Foundation
import ActivityKit

/// Manages Live Activities for prayer countdown timers
/// Rebuilt following LivePolls best practices with App Group storage
@available(iOS 16.1, *)
@MainActor
final class LiveActivityManager: ObservableObject {

    // MARK: - Singleton
    static let shared = LiveActivityManager()

    // MARK: - Published State
    @Published private(set) var currentActivity: Activity<PrayerCountdownAttributes>?
    @Published private(set) var isActivityActive: Bool = false

    // MARK: - App Group Storage (Critical for widget/background sync)
    private let appGroupId = "group.com.apbros.noorani"
    private var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupId) ?? UserDefaults.standard
    }

    // MARK: - Debouncing
    private var lastStartAttempt: Date?
    private let debounceInterval: TimeInterval = 3.0

    // MARK: - Retry Logic
    private var retryCount = 0
    private let maxRetries = 3

    // MARK: - Timer Update Task
    private var updateTask: Task<Void, Never>?
    private var targetTimeTask: Task<Void, Never>?

    private init() {
        reuseExistingActivityIfAvailable()
        cleanupOldDismissals()
    }

    /// Clear all dismissals - call when user opens app to allow Live Activities to restart
    func clearAllDismissals() {
        for key in sharedDefaults.dictionaryRepresentation().keys {
            if key.hasPrefix("dismissed_") {
                sharedDefaults.removeObject(forKey: key)
            }
        }
        print("🧹 Cleared all dismissals - Live Activities can restart")
    }

    /// Clear dismissal for a specific prayer
    func clearDismissal(for prayerName: String, targetTime: Date) {
        let prayerId = generatePrayerId(prayerName: prayerName, targetTime: targetTime)
        sharedDefaults.removeObject(forKey: "dismissed_\(prayerId)")
        print("🧹 Cleared dismissal for \(prayerName)")
    }

    // MARK: - Authorization

    /// Check if Live Activities are authorized
    func checkAuthorization() -> Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    // MARK: - Start Activity

    /// Start a Live Activity for a specific prayer
    /// - Parameters:
    ///   - prayerName: Name of the prayer (e.g., "Fajr", "Dhuhr")
    ///   - targetTime: The time when the prayer starts
    func startLiveActivity(for prayerName: String, targetTime: Date) {
        // 1. Authorization check
        guard checkAuthorization() else {
            print("❌ Live Activities not authorized")
            return
        }

        // 2. Debounce rapid requests
        if let lastAttempt = lastStartAttempt,
           Date().timeIntervalSince(lastAttempt) < debounceInterval {
            print("⏭️ Debounced: Too soon after last request")
            return
        }
        lastStartAttempt = Date()

        // 3. Generate unique prayer ID
        let prayerId = generatePrayerId(prayerName: prayerName, targetTime: targetTime)

        // 4. Check for existing activity (LivePolls pattern)
        if let existing = Activity<PrayerCountdownAttributes>.activities.first(where: {
            $0.attributes.prayerId == prayerId
        }) {
            print("♻️ Reusing existing activity for \(prayerName)")
            currentActivity = existing
            isActivityActive = true
            return
        }

        // 5. Check user dismissal (using App Group!)
        if sharedDefaults.bool(forKey: "dismissed_\(prayerId)") {
            print("⏭️ User dismissed this prayer, respecting dismissal")
            return
        }

        // 6. End any current activity for different prayer
        if currentActivity != nil {
            endCurrentActivity()
        }

        // 7. Create activity with 8-hour stale date (LivePolls pattern)
        let attributes = PrayerCountdownAttributes(prayerId: prayerId)

        // Note: remainingSeconds kept for backwards compatibility but native timer handles display
        let remainingSeconds = max(0, Int(targetTime.timeIntervalSinceNow))
        let contentState = PrayerCountdownAttributes.ContentState(
            prayerName: prayerName,
            targetTime: targetTime,
            formattedTime: formatTime(targetTime),
            remainingSeconds: remainingSeconds,
            updatedAt: Date()
        )

        let staleDate = Calendar.current.date(byAdding: .hour, value: 8, to: Date())!
        let content = ActivityContent(state: contentState, staleDate: staleDate)

        do {
            let activity = try Activity<PrayerCountdownAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil  // Local only
            )

            currentActivity = activity
            isActivityActive = true
            retryCount = 0

            // Monitor for dismissal
            monitorActivityDismissal(activity: activity, prayerId: prayerId)

            // Schedule periodic updates and target time update
            scheduleUpdates(for: activity, targetTime: targetTime)

            print("✅ Started Live Activity for \(prayerName)")

        } catch {
            print("❌ Failed to start Live Activity: \(error)")
            handleStartFailure(prayerName: prayerName, targetTime: targetTime)
        }
    }

    /// Start with retry logic for reliability
    func startLiveActivityWithRetry(for prayerName: String, targetTime: Date) {
        retryCount = 0
        attemptStart(prayerName: prayerName, targetTime: targetTime)
    }

    private func attemptStart(prayerName: String, targetTime: Date) {
        startLiveActivity(for: prayerName, targetTime: targetTime)

        // If still no activity after start attempt, retry
        if currentActivity == nil && retryCount < maxRetries {
            retryCount += 1
            let delay = pow(2.0, Double(retryCount - 1))  // 1s, 2s, 4s

            Task {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await MainActor.run {
                    print("🔄 Retry attempt \(self.retryCount) for \(prayerName)")
                    self.attemptStart(prayerName: prayerName, targetTime: targetTime)
                }
            }
        }
    }

    private func handleStartFailure(prayerName: String, targetTime: Date) {
        if retryCount < maxRetries {
            retryCount += 1
            let delay = pow(2.0, Double(retryCount - 1))

            Task {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await MainActor.run {
                    print("🔄 Auto-retry \(self.retryCount) after failure")
                    self.startLiveActivity(for: prayerName, targetTime: targetTime)
                }
            }
        } else {
            print("❌ Failed to start Live Activity after \(maxRetries) attempts")
        }
    }

    // MARK: - Activity Management

    /// End the current Live Activity (called manually or when starting new activity)
    func endCurrentActivity() {
        guard let activity = currentActivity else { return }

        // Cancel update tasks
        updateTask?.cancel()
        targetTimeTask?.cancel()

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            print("✅ Ended Live Activity")
        }

        currentActivity = nil
        isActivityActive = false
    }

    /// End all Live Activities for the app
    func endAllActivities() {
        // Cancel update tasks
        updateTask?.cancel()
        targetTimeTask?.cancel()

        Task {
            for activity in Activity<PrayerCountdownAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            print("✅ Ended all Live Activities")
        }

        currentActivity = nil
        isActivityActive = false
    }

    // MARK: - Private Helpers

    /// Generate unique prayer ID from name and date
    private func generatePrayerId(prayerName: String, targetTime: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return "\(prayerName.lowercased())_\(dateFormatter.string(from: targetTime))"
    }

    /// Format time for display
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let timeFormat = sharedDefaults.string(forKey: "timeFormat") ?? "12"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        if timeFormat == "24" {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "h:mm a"
        }

        return formatter.string(from: date)
    }

    /// Check for existing activity on init
    private func reuseExistingActivityIfAvailable() {
        if let existing = Activity<PrayerCountdownAttributes>.activities.first {
            currentActivity = existing
            isActivityActive = true
            print("♻️ Reused existing activity on init")
        }
    }

    /// Monitor activity for user dismissal
    private func monitorActivityDismissal(activity: Activity<PrayerCountdownAttributes>, prayerId: String) {
        Task {
            for await state in activity.activityStateUpdates {
                if state == .dismissed {
                    // Use App Group storage for dismissal tracking
                    sharedDefaults.set(true, forKey: "dismissed_\(prayerId)")

                    await MainActor.run {
                        currentActivity = nil
                        isActivityActive = false
                    }
                    print("👤 User dismissed activity, recorded in App Group")
                    break
                }
            }
        }
    }


    /// Schedule periodic updates to keep the countdown fresh
    private func scheduleUpdates(for activity: Activity<PrayerCountdownAttributes>, targetTime: Date) {
        // Cancel any existing update tasks
        updateTask?.cancel()
        targetTimeTask?.cancel()

        // Schedule an update at targetTime to freeze at 00:00
        let timeUntilTarget = targetTime.timeIntervalSinceNow
        if timeUntilTarget > 0 {
            targetTimeTask = Task {
                // Wait until target time
                try? await Task.sleep(nanoseconds: UInt64(timeUntilTarget * 1_000_000_000))
                guard !Task.isCancelled else { return }

                // Update with a PAST targetTime so timer shows 00:00
                await MainActor.run {
                    freezeActivityAtZero(for: activity)
                    print("⏰ Timer reached 00:00 - frozen!")
                }
            }
        }

        // Periodic updates every 30 seconds
        updateTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    guard let current = self.currentActivity else { return }
                    // Only update if time hasn't passed yet
                    if current.content.state.targetTime.timeIntervalSinceNow > 0 {
                        self.refreshActivityContent(for: activity)
                    }
                }
            }
        }
    }

    /// Freeze the activity at 00:00 by setting targetTime to past
    private func freezeActivityAtZero(for activity: Activity<PrayerCountdownAttributes>) {
        // Set targetTime to 1 hour ago - this ensures the widget shows 00:00
        let pastTime = Date().addingTimeInterval(-3600)

        let frozenState = PrayerCountdownAttributes.ContentState(
            prayerName: activity.content.state.prayerName,
            targetTime: pastTime,  // PAST time = widget shows 00:00
            formattedTime: activity.content.state.formattedTime,
            remainingSeconds: 0,
            updatedAt: Date()
        )

        let content = ActivityContent(state: frozenState, staleDate: Date().addingTimeInterval(3600))

        Task {
            await activity.update(content)
            print("✅ Activity frozen at 00:00")
        }
    }

    /// Refresh the activity content (normal update while counting down)
    private func refreshActivityContent(for activity: Activity<PrayerCountdownAttributes>) {
        let targetTime = activity.content.state.targetTime
        let remainingSeconds = max(0, Int(targetTime.timeIntervalSinceNow))

        let newState = PrayerCountdownAttributes.ContentState(
            prayerName: activity.content.state.prayerName,
            targetTime: targetTime,
            formattedTime: activity.content.state.formattedTime,
            remainingSeconds: remainingSeconds,
            updatedAt: Date()
        )

        let content = ActivityContent(state: newState, staleDate: Date().addingTimeInterval(3600))

        Task {
            await activity.update(content)
        }
    }

    /// Clean dismissals older than 24 hours
    private func cleanupOldDismissals() {
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        for key in sharedDefaults.dictionaryRepresentation().keys {
            if key.hasPrefix("dismissed_") {
                // Extract date from prayerId (format: dismissed_fajr_2025-02-16)
                let components = key.components(separatedBy: "_")
                if components.count >= 3 {
                    let dateStr = components[2]
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    if let date = formatter.date(from: dateStr),
                       date < oneDayAgo {
                        sharedDefaults.removeObject(forKey: key)
                        print("🧹 Cleaned old dismissal: \(key)")
                    }
                }
            }
        }
    }
}

// MARK: - Fallback for iOS < 16.1
final class LiveActivityManagerFallback {
    static let shared = LiveActivityManagerFallback()
    private init() {}

    func startLiveActivity(for prayerName: String, targetTime: Date) {
        print("⚠️ Live Activities not available on this iOS version")
    }

    func startLiveActivityWithRetry(for prayerName: String, targetTime: Date) {
        print("⚠️ Live Activities not available on this iOS version")
    }

    func endAllActivities() {
        // No-op for older versions
    }

    func endCurrentActivity() {
        // No-op for older versions
    }

    func checkAuthorization() -> Bool {
        return false
    }
}
