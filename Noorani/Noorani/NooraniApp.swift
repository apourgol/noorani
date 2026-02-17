//
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI
import UserNotifications
import BackgroundTasks

// MARK: - App Delegate for Local Notifications
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Preload custom fonts to ensure they're available on first launch
        preloadCustomFonts()

        // Set notification delegate for LOCAL notifications
        UNUserNotificationCenter.current().delegate = self

        // Register background tasks for Live Activity triggering
        Task { @MainActor in
            BackgroundTaskManager.shared.registerBackgroundTasks()
        }

        return true
    }

    // MARK: - Font Preloading
    /// Preload custom fonts on app startup to ensure they're available immediately
    /// This fixes the issue where Uthman Taha font doesn't load on first app download
    private func preloadCustomFonts() {
        // Force load all custom fonts by instantiating them
        // This ensures iOS registers them in memory before they're used
        let fontsToPreload = [
            "KFGQPC Uthman Taha Naskh Bold",
            "Nunito-SemiBold",
            "Nunito-Light",
            "Nunito-Regular"
        ]

        for fontName in fontsToPreload {
            // Calling UIFont with the font name forces iOS to load it
            let _ = UIFont(name: fontName, size: 16)
        }

        print("✅ Custom fonts preloaded successfully")
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .badge, .sound])
    }

    // Handle notification tap actions
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        // Handle notification action based on prayer type
        if let prayerName = userInfo["prayerName"] as? String {
            print("User tapped notification for: \(prayerName)")
            // Post notification to open specific prayer view if needed
            NotificationCenter.default.post(
                name: Notification.Name("OpenPrayerNotification"),
                object: nil,
                userInfo: ["prayerName": prayerName]
            )
        }

        completionHandler()
    }
}

@main
struct NooraniApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .preferredColorScheme(.light)
        }
    }
}
