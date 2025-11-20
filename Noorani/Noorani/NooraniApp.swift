//
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI
// FIREBASE DISABLED - Local notifications only
// import FirebaseCore
// import FirebaseMessaging
// import FirebaseAppCheck
import UserNotifications

// FIREBASE DISABLED
/*
// MARK: - App Check Provider Factory
class NooraniAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if DEBUG
        // Use debug provider for local testing (Xcode builds)
        // This allows Firestore writes during development
        return AppCheckDebugProvider(app: app)
        #else
        // Use App Attest for production (TestFlight/App Store)
        // This verifies the request comes from your legitimate app
        if #available(iOS 14.0, *) {
            return AppAttestProvider(app: app)
        } else {
            return DeviceCheckProvider(app: app)
        }
        #endif
    }
}
*/

// MARK: - App Delegate for Local Notifications Only
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    // FIREBASE DISABLED - MessagingDelegate removed

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Preload custom fonts to ensure they're available on first launch
        preloadCustomFonts()

        // FIREBASE DISABLED - All remote push/Live Activity code commented out
        /*
        // Configure App Check BEFORE Firebase initialization for security
        let providerFactory = NooraniAppCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)

        // Initialize Firebase
        FirebaseApp.configure()
        */

        // Set notification delegate for LOCAL notifications
        UNUserNotificationCenter.current().delegate = self

        // FIREBASE DISABLED - Remote notifications not needed for local notifications only
        /*
        // Set Firebase Messaging delegate
        Messaging.messaging().delegate = self

        // Register for remote notifications (required for push-to-start)
        application.registerForRemoteNotifications()

        // Start push-to-start token registration for Live Activities
        if #available(iOS 17.2, *) {
            Task { @MainActor in
                PushToStartManager.shared.startTokenRegistration()
            }
        }
        */

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

    // FIREBASE DISABLED - Remote notifications not needed for local notifications
    /*
    // MARK: - Remote Notification Registration

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Pass device token to Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken

        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("APNs device token: \(tokenString)")
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    */

    // FIREBASE DISABLED - MessagingDelegate not needed
    /*
    // MARK: - MessagingDelegate

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("Firebase registration token: \(token)")

        // Save FCM token to Firestore for backend notifications
        if #available(iOS 17.2, *) {
            Task { @MainActor in
                await PushToStartManager.shared.saveFCMToken(token)
            }
        }

        // Post notification for other parts of app that need FCM token
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: ["token": token]
        )
    }
    */

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
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .preferredColorScheme(.light)
        }
    }
}
