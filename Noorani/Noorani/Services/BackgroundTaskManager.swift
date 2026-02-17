//
//  BackgroundTaskManager.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
//

import Foundation
import BackgroundTasks
import ActivityKit

@MainActor
class BackgroundTaskManager: ObservableObject {
    static let shared = BackgroundTaskManager()

    // Background task identifier
    private let taskIdentifier = "com.apbros.noorani.prayercheck"

    private init() {}

    // MARK: - Registration

    /// Register background task handlers (call from app launch)
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { task in
            Task { @MainActor in
                await self.handleBackgroundTask(task as! BGAppRefreshTask)
            }
        }

        print("✅ Background tasks registered")
    }

    // MARK: - Scheduling

    /// Schedule next background task check
    func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)

        // Schedule to run in 15 minutes (iOS will decide actual timing)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Background task scheduled for prayer check")
        } catch {
            // This error is normal on simulator - background tasks only work on real devices
            #if targetEnvironment(simulator)
            print("ℹ️ Background task not available on simulator (expected)")
            #else
            print("❌ Failed to schedule background task: \(error)")
            #endif
        }
    }

    // MARK: - Task Execution

    /// Handle background task execution
    private func handleBackgroundTask(_ task: BGAppRefreshTask) async {
        print("🔄 Background task executing - checking prayer times...")

        // Schedule next task
        scheduleBackgroundTask()

        // Check if we should trigger Live Activity
        await checkAndTriggerLiveActivity()

        // Mark task as complete
        task.setTaskCompleted(success: true)
    }

    // MARK: - Live Activity Logic

    /// The 5 actual prayer times (NOT sunrise, sunset, or midnight)
    private let actualPrayers = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]

    /// Check prayer times and trigger Live Activity if needed
    func checkAndTriggerLiveActivity() async {
        guard #available(iOS 16.1, *) else { return }

        let dataManager = SharedDataManager.shared

        // Get next prayer info from SharedDataManager
        guard let nextPrayerName = dataManager.getNextPrayerName(),
              let nextPrayerTime = dataManager.getNextPrayerTime() else {
            print("⚠️ [Background] No next prayer time available in SharedDataManager")
            return
        }

        // Only process actual prayers (Fajr, Dhuhr, Asr, Maghrib, Isha)
        // Skip sunrise, sunset, midnight as these are not prayer times
        guard actualPrayers.contains(nextPrayerName) else {
            print("⏭️ [Background] \(nextPrayerName) is not a prayer time, skipping")
            return
        }

        // Use SharedDataManager to check all conditions
        guard dataManager.shouldStartLiveActivity(prayerName: nextPrayerName, targetTime: nextPrayerTime) else {
            let timeUntilPrayer = nextPrayerTime.timeIntervalSince(Date())
            let minutesUntil = Int(timeUntilPrayer / 60)
            let offsetMinutes = dataManager.getPrayerLiveActivityOffset(prayer: nextPrayerName)

            if !dataManager.isLiveActivitiesEnabled() {
                print("⏭️ [Background] Live Activities disabled globally")
            } else if !dataManager.isPrayerLiveActivityEnabled(prayer: nextPrayerName) {
                print("⏭️ [Background] Live Activity disabled for \(nextPrayerName)")
            } else {
                print("⏭️ [Background] \(nextPrayerName) not within window (\(minutesUntil)m until prayer, window is \(offsetMinutes)m)")
            }
            return
        }

        // Check if activity already exists to prevent duplicate
        let existingActivities = Activity<PrayerCountdownAttributes>.activities
        let prayerId = "\(nextPrayerName.lowercased())_\(formatDateForId(nextPrayerTime))"

        let alreadyRunning = existingActivities.contains { activity in
            activity.attributes.prayerId == prayerId
        }

        if alreadyRunning {
            print("✅ [Background] Activity already running for \(nextPrayerName)")
        } else {
            let offsetMinutes = dataManager.getPrayerLiveActivityOffset(prayer: nextPrayerName)
            print("✅ [Background] Starting Live Activity for \(nextPrayerName) (within \(offsetMinutes)m window)")
            LiveActivityManager.shared.startLiveActivity(
                for: nextPrayerName,
                targetTime: nextPrayerTime
            )
        }
    }

    // MARK: - Helpers

    private func formatDateForId(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
