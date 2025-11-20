# Remote Push-to-Start Live Activities Setup Guide

## Overview

This guide covers setting up **remote push-to-start Live Activities** for Noorani prayer times. This allows Live Activities to start automatically even when the app is force-quit.

**Requirements:**
- iOS 17.2+ for push-to-start (iOS 16.1+ for local start only)
- Firebase Cloud Functions (or custom backend server)
- Firestore for user data storage
- APNs key from Apple Developer Portal

---

## Architecture

```
User Device                    Firebase Backend              Aladhan API
    │                               │                            │
    ├─ Registers push-to-start ────►│                            │
    │   token for Live Activity     │                            │
    │                               │                            │
    ├─ Saves preferences to ───────►│ Firestore                  │
    │   Firestore                   │ (tokens, settings)         │
    │                               │                            │
    │                               │◄─── Cloud Function ────────┤
    │                               │     fetches prayer times   │
    │                               │                            │
    │◄───── FCM sends push ─────────┤                            │
    │       to start Live Activity  │                            │
    │                               │                            │
    │   Live Activity appears       │                            │
    │   on Lock Screen!             │                            │
```

---

## STEP 1: Apple Developer Portal Setup

### 1.1 Create APNs Key

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Keys** in the sidebar
4. Click the **+** button to create a new key
5. Enter a name: `Noorani APNs Key`
6. Check **Apple Push Notifications service (APNs)**
7. Click **Continue** then **Register**
8. **IMPORTANT**: Download the `.p8` file immediately (you can only download once!)
9. Note your **Key ID** (shown on the key page)
10. Note your **Team ID** (top right of developer portal)

### 1.2 Save These Values

```
Key ID: XXXXXXXXXX (10 characters)
Team ID: YYYYYYYYYY (10 characters)
.p8 File: AuthKey_XXXXXXXXXX.p8
```

---

## STEP 2: Firebase Console Setup

### 2.1 Upload APNs Key to Firebase

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your **Noorani** project
3. Click the **gear icon** > **Project Settings**
4. Go to **Cloud Messaging** tab
5. Scroll to **Apple app configuration**
6. Click **Upload** under APNs Authentication Key
7. Upload your `.p8` file
8. Enter your **Key ID** and **Team ID**
9. Click **Upload**

### 2.2 Enable Firebase Services

In Firebase Console:
1. **Firestore Database**: Create a database (start in test mode)
2. **Cloud Functions**: Enable (requires Blaze plan)
3. **Authentication**: Enable Anonymous auth (optional, for user identification)

---

## STEP 3: iOS App Code - Push Token Registration

### 3.1 Update PrayerCountdownAttributes for Codable

The attributes need to match exactly what you send from the server. Already done!

### 3.2 Create Push Token Manager

Create a new file to handle push-to-start token registration:

```swift
// Services/PushToStartManager.swift

import Foundation
import ActivityKit
import FirebaseFirestore

@available(iOS 17.2, *)
final class PushToStartManager {
    static let shared = PushToStartManager()
    private let db = Firestore.firestore()

    private init() {}

    /// Register for push-to-start tokens
    func registerForPushToStart() async {
        // Check if Live Activities are enabled
        guard UserDefaults.standard.bool(forKey: "liveActivitiesEnabled") else {
            print("PushToStartManager: Live Activities disabled")
            return
        }

        // Register for push-to-start token updates
        for await tokenData in Activity<PrayerCountdownAttributes>.pushToStartTokenUpdates {
            let token = tokenData.map { String(format: "%02x", $0) }.joined()
            print("PushToStartManager: Received push-to-start token: \(token)")

            // Save token to Firestore
            await saveTokenToFirestore(token)
        }
    }

    private func saveTokenToFirestore(_ token: String) async {
        // Get or create device ID
        let deviceId = getDeviceId()

        // Get user preferences
        let notificationOffset = UserDefaults.standard.integer(forKey: "notificationOffset")
        let liveActivityOffset = UserDefaults.standard.object(forKey: "liveActivityStartOffset") as? Int ?? 30

        // Get enabled prayers
        var enabledPrayers: [String] = []
        let prayers = ["fajr", "sunrise", "dhuhr", "asr", "sunset", "maghrib", "isha", "midnight"]
        for prayer in prayers {
            if UserDefaults.standard.object(forKey: "\(prayer)Notification") as? Bool ?? false {
                enabledPrayers.append(prayer.capitalized)
            }
        }

        // Get location
        let latitude = UserDefaults.standard.double(forKey: "currentLat")
        let longitude = UserDefaults.standard.double(forKey: "currentLng")
        let methodId = UserDefaults.standard.integer(forKey: "selectedMethodId")

        let userData: [String: Any] = [
            "pushToStartToken": token,
            "fcmToken": "", // Will be set separately
            "deviceId": deviceId,
            "liveActivityOffset": liveActivityOffset,
            "notificationOffset": notificationOffset,
            "enabledPrayers": enabledPrayers,
            "latitude": latitude,
            "longitude": longitude,
            "calculationMethodId": methodId,
            "timeFormat": UserDefaults.standard.string(forKey: "timeFormat") ?? "12",
            "lastUpdated": FieldValue.serverTimestamp(),
            "platform": "iOS",
            "osVersion": UIDevice.current.systemVersion
        ]

        do {
            try await db.collection("users").document(deviceId).setData(userData, merge: true)
            print("PushToStartManager: Saved token to Firestore")
        } catch {
            print("PushToStartManager: Error saving to Firestore: \(error)")
        }
    }

    private func getDeviceId() -> String {
        if let existingId = UserDefaults.standard.string(forKey: "deviceId") {
            return existingId
        }

        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "deviceId")
        return newId
    }

    /// Save FCM token
    func saveFCMToken(_ token: String) async {
        let deviceId = getDeviceId()

        do {
            try await db.collection("users").document(deviceId).setData([
                "fcmToken": token,
                "lastUpdated": FieldValue.serverTimestamp()
            ], merge: true)
            print("PushToStartManager: Saved FCM token to Firestore")
        } catch {
            print("PushToStartManager: Error saving FCM token: \(error)")
        }
    }

    /// Update user preferences in Firestore
    func updatePreferences() async {
        let deviceId = getDeviceId()

        var enabledPrayers: [String] = []
        let prayers = ["fajr", "sunrise", "dhuhr", "asr", "sunset", "maghrib", "isha", "midnight"]
        for prayer in prayers {
            if UserDefaults.standard.object(forKey: "\(prayer)Notification") as? Bool ?? false {
                enabledPrayers.append(prayer.capitalized)
            }
        }

        let preferences: [String: Any] = [
            "liveActivityOffset": UserDefaults.standard.object(forKey: "liveActivityStartOffset") as? Int ?? 30,
            "notificationOffset": UserDefaults.standard.integer(forKey: "notificationOffset"),
            "enabledPrayers": enabledPrayers,
            "latitude": UserDefaults.standard.double(forKey: "currentLat"),
            "longitude": UserDefaults.standard.double(forKey: "currentLng"),
            "calculationMethodId": UserDefaults.standard.integer(forKey: "selectedMethodId"),
            "timeFormat": UserDefaults.standard.string(forKey: "timeFormat") ?? "12",
            "liveActivitiesEnabled": UserDefaults.standard.bool(forKey: "liveActivitiesEnabled"),
            "notificationsEnabled": UserDefaults.standard.bool(forKey: "notificationsEnabled"),
            "lastUpdated": FieldValue.serverTimestamp()
        ]

        do {
            try await db.collection("users").document(deviceId).setData(preferences, merge: true)
            print("PushToStartManager: Updated preferences in Firestore")
        } catch {
            print("PushToStartManager: Error updating preferences: \(error)")
        }
    }
}
```

### 3.3 Update AppDelegate for FCM Token

Update your `NooraniApp.swift`:

```swift
// In AppDelegate class, add:

import FirebaseMessaging

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("FCM Token: \(token)")

        // Save to Firestore
        if #available(iOS 17.2, *) {
            Task {
                await PushToStartManager.shared.saveFCMToken(token)
            }
        }
    }
}

// In application(_:didFinishLaunchingWithOptions:):
func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    FirebaseApp.configure()

    // Set FCM delegate
    Messaging.messaging().delegate = self

    // Set notification delegate
    UNUserNotificationCenter.current().delegate = self

    // Register for remote notifications
    application.registerForRemoteNotifications()

    // Start push-to-start token registration
    if #available(iOS 17.2, *) {
        Task {
            await PushToStartManager.shared.registerForPushToStart()
        }
    }

    return true
}
```

---

## STEP 4: Firebase Cloud Functions (Backend)

### 4.1 Initialize Cloud Functions

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Cloud Functions in your project directory
cd /path/to/your/project
firebase init functions

# Select JavaScript or TypeScript
# Select your Firebase project
```

### 4.2 Cloud Function Code

Create `functions/index.js`:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();
const db = admin.firestore();

// Run every minute to check for upcoming prayers
exports.schedulePrayerActivities = functions.pubsub
  .schedule('every 1 minutes')
  .onRun(async (context) => {
    const now = new Date();
    const usersSnapshot = await db.collection('users').get();

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();

      if (!userData.liveActivitiesEnabled || !userData.pushToStartToken) {
        continue;
      }

      // Fetch prayer times for this user
      const prayerTimes = await fetchPrayerTimes(
        userData.latitude,
        userData.longitude,
        userData.calculationMethodId
      );

      // Check if any prayer is coming up within the user's offset window
      for (const [prayerName, prayerTime] of Object.entries(prayerTimes)) {
        if (!userData.enabledPrayers.includes(prayerName)) {
          continue;
        }

        const minutesUntilPrayer = (prayerTime - now) / (1000 * 60);
        const targetOffset = userData.liveActivityOffset || 30;

        // Start Live Activity when we're within 1 minute of the offset time
        if (minutesUntilPrayer > 0 &&
            minutesUntilPrayer <= targetOffset &&
            minutesUntilPrayer > targetOffset - 1) {

          await startLiveActivity(userData, prayerName, prayerTime);
        }
      }
    }

    return null;
  });

async function fetchPrayerTimes(latitude, longitude, methodId) {
  const today = new Date();
  const dateStr = `${today.getDate().toString().padStart(2, '0')}-${(today.getMonth() + 1).toString().padStart(2, '0')}-${today.getFullYear()}`;

  const url = `https://api.aladhan.com/v1/timings/${dateStr}?latitude=${latitude}&longitude=${longitude}&method=${methodId}&iso8601=true`;

  const response = await axios.get(url);
  const timings = response.data.data.timings;

  const prayerTimes = {};
  const relevantPrayers = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Sunset', 'Maghrib', 'Isha', 'Midnight'];

  for (const prayer of relevantPrayers) {
    if (timings[prayer]) {
      prayerTimes[prayer] = new Date(timings[prayer]);
    }
  }

  return prayerTimes;
}

async function startLiveActivity(userData, prayerName, prayerTime) {
  const prayerIcons = {
    'Fajr': 'sunrise.fill',
    'Sunrise': 'sun.horizon.fill',
    'Dhuhr': 'sun.max.fill',
    'Asr': 'sun.min.fill',
    'Sunset': 'sunset.fill',
    'Maghrib': 'moon.fill',
    'Isha': 'moon.stars.fill',
    'Midnight': 'moon.zzz.fill'
  };

  // Format prayer time
  const timeFormat = userData.timeFormat === '24' ? 'HH:mm' : 'h:mm a';
  const formattedTime = formatTime(prayerTime, timeFormat);

  const message = {
    token: userData.fcmToken,
    apns: {
      live_activity_token: userData.pushToStartToken,
      headers: {
        'apns-priority': '10',
        'apns-push-type': 'liveactivity'
      },
      payload: {
        aps: {
          timestamp: Math.floor(Date.now() / 1000),
          event: 'start',
          'content-state': {
            prayerName: prayerName,
            targetTime: prayerTime.toISOString(),
            remainingSeconds: Math.floor((prayerTime - new Date()) / 1000),
            showTimer: true,
            message: null
          },
          'attributes-type': 'PrayerCountdownAttributes',
          attributes: {
            prayerIcon: prayerIcons[prayerName] || 'clock.fill',
            colorTheme: prayerName.toLowerCase(),
            formattedPrayerTime: formattedTime,
            isExpirationWarning: false
          },
          alert: {
            title: `${prayerName} Prayer`,
            body: `Prayer time at ${formattedTime}`
          }
        }
      }
    }
  };

  try {
    await admin.messaging().send(message);
    console.log(`Started Live Activity for ${userData.deviceId}: ${prayerName}`);

    // Log this to avoid duplicate starts
    await db.collection('activityLogs').add({
      deviceId: userData.deviceId,
      prayerName: prayerName,
      prayerTime: prayerTime,
      startedAt: admin.firestore.FieldValue.serverTimestamp()
    });
  } catch (error) {
    console.error(`Error starting Live Activity: ${error}`);
  }
}

function formatTime(date, format) {
  if (format === 'HH:mm') {
    return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
  } else {
    let hours = date.getHours();
    const minutes = date.getMinutes().toString().padStart(2, '0');
    const ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12;
    hours = hours ? hours : 12;
    return `${hours}:${minutes} ${ampm}`;
  }
}
```

### 4.3 Deploy Cloud Functions

```bash
cd functions
npm install axios
firebase deploy --only functions
```

---

## STEP 5: Update iOS App to Sync Preferences

When user changes settings, sync to Firestore:

In `NotificationsViewModel.swift`, add after saving settings:

```swift
// After saveSettings(), add:
if #available(iOS 17.2, *) {
    Task {
        await PushToStartManager.shared.updatePreferences()
    }
}
```

---

## STEP 6: Firestore Security Rules

In Firebase Console > Firestore > Rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if true; // For development
      // For production, use proper authentication
    }
    match /activityLogs/{logId} {
      allow read, write: if true;
    }
  }
}
```

---

## STEP 7: Testing

1. **Build and run app** on physical device
2. **Enable notifications** and **Live Activities** in settings
3. **Grant notification permissions**
4. **Check Firestore** - you should see your device document with tokens
5. **Wait for Cloud Function** to run (every minute)
6. **Force quit the app**
7. **When prayer time approaches** (within your offset), Live Activity should start remotely!

---

## Troubleshooting

### Tokens not saving to Firestore:
- Check Firebase SDK is properly initialized
- Verify Firestore database exists
- Check network connectivity

### Live Activity not starting:
- iOS 17.2+ required for push-to-start
- Verify APNs key is uploaded correctly
- Check Cloud Functions logs in Firebase Console
- Ensure push-to-start token is valid

### Cloud Function errors:
- Check Firebase Console > Functions > Logs
- Verify Aladhan API is accessible
- Check FCM token and push-to-start token are present

---

## Costs

**Firebase Blaze Plan (pay-as-you-go):**
- Cloud Functions: First 2M invocations/month free
- Firestore: 50K reads/day free, 20K writes/day free
- FCM: Free

For a typical user checking every minute: ~43,200 function invocations/month per user. Still well within free tier for small user base.

---

## Summary

You now have:
1. **APNs key** configured in Firebase
2. **Push-to-start token registration** in iOS app
3. **User preferences synced** to Firestore
4. **Cloud Function** that checks prayer times and triggers Live Activities
5. **Automatic remote start** even when app is force-quit!

The system is fully automated - user just enables Live Activities and they appear automatically!
