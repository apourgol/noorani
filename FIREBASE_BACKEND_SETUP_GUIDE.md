# Firebase Backend Setup Guide for Remote Push-to-Start Live Activities

This guide walks you through setting up Firebase Cloud Functions to automatically send push-to-start Live Activities to users before each prayer time. Even when the app is force-quit, users will receive countdown timers on their Lock Screen.

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Apple Developer Portal Setup](#apple-developer-portal-setup)
3. [Firebase Console Setup](#firebase-console-setup)
4. [Xcode Project Configuration](#xcode-project-configuration)
5. [Firebase Cloud Functions Setup](#firebase-cloud-functions-setup)
6. [Testing the Integration](#testing-the-integration)
7. [Monitoring and Debugging](#monitoring-and-debugging)

---

## Prerequisites

Before starting, ensure you have:
- Apple Developer account (paid membership)
- Firebase project created
- Node.js 18+ installed
- Firebase CLI installed (`npm install -g firebase-tools`)
- Xcode 15+ with the Noorani project

---

## 1. Apple Developer Portal Setup

### Create APNs Authentication Key

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Keys** in the left sidebar
4. Click the **+** button to create a new key
5. Enter key name: `Noorani APNs Key`
6. Check **Apple Push Notifications service (APNs)**
7. Click **Continue**, then **Register**
8. **IMPORTANT**: Download the key file (`.p8` file) immediately
   - You can only download this once!
   - Save it securely as `AuthKey_XXXXXXXXXX.p8`
9. Note down:
   - **Key ID**: The 10-character string (e.g., `ABC123DEFG`)
   - **Team ID**: Found in your Apple Developer account (top right corner)

### Enable Push Notifications Capability

1. Go to **Identifiers** in the portal
2. Find your App ID (e.g., `com.apbros.noorani`)
3. Click on it to edit
4. Scroll down to **Capabilities**
5. Ensure **Push Notifications** is checked
6. Click **Save**

---

## 2. Firebase Console Setup

### Add Firebase to Your Project (if not done)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Add an iOS app:
   - Click the iOS icon
   - Enter Bundle ID: `com.apbros.noorani`
   - Download `GoogleService-Info.plist`
   - Add it to your Xcode project

### Upload APNs Key to Firebase

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Click **Cloud Messaging** tab
3. Scroll to **Apple app configuration**
4. Click **Upload** under APNs Authentication Key
5. Upload your `.p8` file
6. Enter:
   - **Key ID**: From step 1
   - **Team ID**: Your Apple Developer Team ID
7. Click **Upload**

### Enable Firestore Database

1. In Firebase Console, click **Firestore Database**
2. Click **Create database**
3. Select **Start in test mode** (for development)
4. Choose a location (e.g., `us-central`)
5. Click **Enable**

### Set Firestore Security Rules

In Firestore, go to **Rules** tab and set:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      // For development without auth, use this instead:
      // allow read, write: if true;
    }
  }
}
```

---

## 3. Xcode Project Configuration

### Add App Groups Capability

1. Open your Xcode project
2. Select the **Noorani** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **App Groups**
6. Click **+** to add a new group
7. Enter: `group.com.apbros.noorani`
8. Make sure the checkbox is selected

### Add App Groups to Widget Extension

1. Select the **NooraniWidgetExtension** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Select the same group: `group.com.apbros.noorani`

### Update SharedDataManager

In `Noorani/Services/SharedDataManager.swift`, verify the App Group identifier matches:

```swift
private let appGroupIdentifier = "group.com.apbros.noorani"
```

### Add Firebase SDKs via Swift Package Manager

1. File → Add Package Dependencies
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Select packages:
   - FirebaseCore
   - FirebaseMessaging
   - FirebaseFirestore

### Enable Background Modes

1. Select **Noorani** target
2. Go to **Signing & Capabilities**
3. Add **Background Modes** capability
4. Enable:
   - **Background fetch**
   - **Remote notifications**

---

## 4. Firebase Cloud Functions Setup

### Initialize Firebase Functions

Open Terminal and navigate to your project root:

```bash
cd /Users/neo/repos/noorani
mkdir firebase-backend
cd firebase-backend
firebase login
firebase init functions
```

When prompted:
- Select your Firebase project
- Choose **JavaScript** or **TypeScript**
- Say **Yes** to ESLint
- Say **Yes** to install dependencies

### Install Required Packages

```bash
cd functions
npm install axios apn firebase-admin node-schedule
```

### Create the Cloud Function

Replace `functions/index.js` with:

```javascript
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const apn = require("apn");

admin.initializeApp();

// APNs Configuration
const apnProvider = new apn.Provider({
  token: {
    key: "./AuthKey_XXXXXXXXXX.p8", // Place your .p8 file in functions folder
    keyId: "YOUR_KEY_ID",
    teamId: "YOUR_TEAM_ID",
  },
  production: false, // Set to true for production
});

// Scheduled function that runs every 5 minutes
exports.schedulePrayerLiveActivities = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(async (context) => {
    console.log("Checking for upcoming prayers...");

    const db = admin.firestore();
    const usersRef = db.collection("users");

    try {
      const snapshot = await usersRef.get();

      for (const doc of snapshot.docs) {
        const userData = doc.data();

        // Skip if no push-to-start token
        if (!userData.pushToStartToken) {
          console.log(`User ${doc.id} has no push-to-start token`);
          continue;
        }

        // Get user preferences
        const location = userData.location || {};
        const preferences = userData.preferences || {};
        const startOffset = preferences.liveActivityStartOffset || 30;
        const enabledPrayers = preferences.enabledPrayers || [
          "Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"
        ];

        // Fetch prayer times from Al-Adhan API
        const prayerTimes = await fetchPrayerTimes(
          location.latitude,
          location.longitude,
          location.timezone
        );

        if (!prayerTimes) {
          console.log(`Failed to fetch prayer times for user ${doc.id}`);
          continue;
        }

        // Check each prayer
        for (const prayer of enabledPrayers) {
          const prayerTime = prayerTimes[prayer];
          if (!prayerTime) continue;

          const now = new Date();
          const prayerDate = new Date(prayerTime);
          const startTime = new Date(prayerDate.getTime() - startOffset * 60000);

          // If we're within the window to start Live Activity (within 1 minute of start time)
          const diffMinutes = (startTime - now) / 60000;

          if (diffMinutes >= 0 && diffMinutes <= 1) {
            console.log(`Sending Live Activity for ${prayer} to user ${doc.id}`);

            await sendPushToStartLiveActivity(
              userData.pushToStartToken,
              prayer,
              prayerDate,
              getPrayerIcon(prayer)
            );
          }
        }
      }
    } catch (error) {
      console.error("Error in schedulePrayerLiveActivities:", error);
    }
  });

// Fetch prayer times from Al-Adhan API
async function fetchPrayerTimes(latitude, longitude, timezone) {
  try {
    const today = new Date();
    const dateStr = `${today.getDate()}-${today.getMonth() + 1}-${today.getFullYear()}`;

    const response = await axios.get(
      `https://api.aladhan.com/v1/timings/${dateStr}`,
      {
        params: {
          latitude: latitude,
          longitude: longitude,
          method: 2, // ISNA
          timezone: timezone,
        },
      }
    );

    if (response.data.code === 200) {
      const timings = response.data.data.timings;

      // Convert string times to Date objects
      const prayerTimes = {};
      const baseDate = today.toDateString();

      for (const [name, time] of Object.entries(timings)) {
        const [hours, minutes] = time.split(":").map(Number);
        const prayerDate = new Date(baseDate);
        prayerDate.setHours(hours, minutes, 0, 0);
        prayerTimes[name] = prayerDate.toISOString();
      }

      return prayerTimes;
    }
  } catch (error) {
    console.error("Error fetching prayer times:", error);
  }
  return null;
}

// Send push-to-start Live Activity
async function sendPushToStartLiveActivity(token, prayerName, prayerTime, icon) {
  const notification = new apn.Notification();

  // Required for Live Activities
  notification.pushType = "liveactivity";
  notification.topic = "com.apbros.noorani.push-type.liveactivity";
  notification.priority = 10;

  // Live Activity content
  notification.aps = {
    timestamp: Math.floor(Date.now() / 1000),
    event: "start",
    "content-state": {
      prayerName: prayerName,
      targetTime: prayerTime,
      remainingSeconds: Math.floor((new Date(prayerTime) - new Date()) / 1000),
      showTimer: true,
      message: null,
    },
    "attributes-type": "PrayerCountdownAttributes",
    attributes: {
      prayerIcon: icon,
      colorTheme: getColorTheme(prayerName),
      formattedPrayerTime: formatTime(prayerTime),
      isExpirationWarning: false,
    },
  };

  try {
    const result = await apnProvider.send(notification, token);
    console.log("Push-to-start result:", result);
    return result;
  } catch (error) {
    console.error("Error sending push-to-start:", error);
    throw error;
  }
}

function getPrayerIcon(prayerName) {
  const icons = {
    Fajr: "sunrise.fill",
    Sunrise: "sun.horizon.fill",
    Dhuhr: "sun.max.fill",
    Asr: "sun.min.fill",
    Maghrib: "moon.fill",
    Isha: "moon.stars.fill",
  };
  return icons[prayerName] || "clock.fill";
}

function getColorTheme(prayerName) {
  const themes = {
    Fajr: "dawn",
    Dhuhr: "noon",
    Asr: "afternoon",
    Maghrib: "evening",
    Isha: "night",
  };
  return themes[prayerName] || "default";
}

function formatTime(isoString) {
  const date = new Date(isoString);
  return date.toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  });
}
```

### Add Your APNs Key File

1. Copy your `.p8` file to the `functions/` directory
2. Update the `key` path in `apnProvider` configuration
3. Update `keyId` and `teamId` with your values

### Deploy Functions

```bash
cd /Users/neo/repos/noorani/firebase-backend/functions
firebase deploy --only functions
```

---

## 5. Testing the Integration

### Verify Firestore Data

1. Open your app on a device
2. Go to Settings → Notifications
3. Enable Live Activities
4. Check Firebase Console → Firestore
5. You should see a document in `users` collection with:
   - `pushToStartToken`
   - `fcmToken`
   - `location`
   - `preferences`

### Test Cloud Function Manually

In Firebase Console:
1. Go to **Functions**
2. Find `schedulePrayerLiveActivities`
3. Click **Logs** to see execution logs

Or test locally:
```bash
cd functions
npm run serve
# This runs the functions locally
```

### Verify APNs Connection

Check Firebase Console logs for:
- "Sending Live Activity for [Prayer] to user..."
- "Push-to-start result: ..."

---

## 6. Monitoring and Debugging

### Common Issues

**No push-to-start token in Firestore:**
- Ensure iOS 17.2+ on device
- Verify Live Activities are enabled in Settings
- Check that `PushToStartManager` is starting in AppDelegate

**APNs errors:**
- Verify `.p8` file is correct
- Check Key ID and Team ID match
- Ensure production flag matches your environment

**Function not triggering:**
- Check Pub/Sub schedule is running
- Verify Firestore has user data
- Check function logs for errors

### Useful Commands

```bash
# View function logs
firebase functions:log

# Deploy only functions
firebase deploy --only functions

# Test locally
cd functions && npm run serve
```

---

## 7. Production Considerations

### Switch to Production APNs

In `functions/index.js`:
```javascript
const apnProvider = new apn.Provider({
  // ...
  production: true, // Change to true for App Store
});
```

### Upgrade Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Require authentication
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Enable Firebase Authentication

If you want user accounts:
1. Enable Authentication in Firebase Console
2. Add sign-in method (Apple Sign In recommended)
3. Update app to use Firebase Auth UID instead of device ID

### Cost Optimization

- Functions run every 5 minutes = 288 invocations/day
- Use Blaze (pay-as-you-go) plan for Functions
- Monitor usage in Firebase Console

---

## Summary

You now have:
1. APNs key configured for push notifications
2. Firebase project with Messaging and Firestore
3. iOS app registering push-to-start tokens
4. Cloud Function checking prayer times every 5 minutes
5. Automatic Live Activity pushes to users

When a user enables Live Activities, their token and preferences are saved to Firestore. The Cloud Function periodically checks all users, fetches their prayer times, and sends push-to-start notifications at the configured offset before each prayer.

Even if the app is force-quit, users will receive Live Activity countdown timers on their Lock Screen and Dynamic Island!
