# Noorani Live Activity & Notification Setup Guide

## Overview

This guide covers the complete setup for prayer time notifications and Live Activities in the Noorani app. The implementation includes:

- **Local Notifications** for prayer time reminders (5-60 minutes before)
- **Expiration Notifications** when prayer time is ending
- **Live Activities** with Dynamic Island countdown timers
- **Firebase Core** for analytics (optional)

---

## Phase 1: Firebase SDK Setup (Swift Package Manager)

### Add Firebase to your project:

1. In Xcode, go to **File > Add Package Dependencies**
2. Enter the Firebase iOS SDK URL:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
3. Select version **11.0.0** or later
4. Choose these packages:
   - **FirebaseCore** (required)
   - **FirebaseAnalytics** (optional, for analytics)
   - **FirebaseCrashlytics** (optional, for crash reporting)

5. Click **Add Package**

### Verify GoogleService-Info.plist

Your `GoogleService-Info.plist` is already in place at:
```
Noorani/Noorani/GoogleService-Info.plist
```

Ensure it's added to the main app target.

---

## Phase 2: Widget Extension Setup (Required for Live Activities)

### Step 1: Create Widget Extension Target

1. In Xcode, go to **File > New > Target**
2. Search for **"Widget Extension"**
3. Configure:
   - **Product Name:** `NooraniWidgetExtension`
   - **Team:** Your development team
   - **Bundle Identifier:** `com.apbrology.Noorani.NooraniWidgetExtension`
   - **Include Live Activity:** ✅ Check this box
   - **Include Configuration App Intent:** ❌ Uncheck (not needed)

4. Click **Finish**
5. When prompted "Activate scheme?", click **Activate**

### Step 2: Configure Widget Target

1. Select the `NooraniWidgetExtension` target
2. Go to **General** tab:
   - **Deployment Target:** iOS 16.1 or later
   - **Supports Live Activities:** Yes (should be automatic)

3. Go to **Build Phases** tab:
   - Ensure `ActivityKit.framework` is linked

### Step 3: Share PrayerCountdownAttributes

The `PrayerCountdownAttributes.swift` model needs to be accessible by both the main app and widget extension.

**Option A: Add to both targets**
1. Select `Noorani/Models/PrayerCountdownAttributes.swift` in Project Navigator
2. In the File Inspector (right panel), under **Target Membership**:
   - ✅ Noorani
   - ✅ NooraniWidgetExtension

**Option B: Create App Group (Recommended for complex sharing)**
1. Go to main app target > **Signing & Capabilities**
2. Click **+ Capability** > **App Groups**
3. Add: `group.com.apbrology.Noorani`
4. Repeat for Widget Extension target

### Step 4: Add Widget Extension Files

The following files are already created in `/Noorani/NooraniWidgetExtension/`:

1. **NooraniWidgetBundle.swift** - Widget bundle entry point
2. **PrayerCountdownLiveActivity.swift** - Live Activity UI (Lock Screen + Dynamic Island)

Copy these files into your new Widget Extension target:
1. Right-click on the NooraniWidgetExtension group in Xcode
2. **Add Files to "NooraniWidgetExtension"**
3. Select both Swift files
4. Ensure target membership is set to NooraniWidgetExtension only

### Step 5: Delete Auto-Generated Files

Xcode creates template files that we don't need:
- Delete any auto-generated `*Widget.swift` or `*WidgetBundle.swift` files
- Keep only our custom files

### Step 6: Build & Test

1. Select the **NooraniWidgetExtension** scheme
2. Build (⌘B) to check for errors
3. Switch back to **Noorani** scheme
4. Run on device (Live Activities require physical device)

---

## Phase 3: Notification Capabilities

### Already Configured:

1. **Info.plist** - `NSSupportsLiveActivities = YES` ✅
2. **Entitlements** - `aps-environment = development` ✅
3. **Push Notification Capability** - Added in project ✅

### Verify in Xcode:

1. Select Noorani target
2. Go to **Signing & Capabilities**
3. Confirm these capabilities exist:
   - **Push Notifications**
   - **Background Modes** (optional, for background refresh)

---

## Architecture Overview

### Files Created/Modified:

```
Noorani/
├── NooraniApp.swift                    # Firebase init + UNUserNotificationCenterDelegate
├── Info.plist                          # Live Activity support flags
├── Services/
│   ├── NotificationScheduler.swift     # Schedules local notifications
│   └── LiveActivityManager.swift       # Manages Live Activity lifecycle
├── Models/
│   └── PrayerCountdownAttributes.swift # ActivityKit model (shared)
├── Settings/
│   ├── NotificationsViewModel.swift    # Enhanced with scheduling
│   ├── NotificationsView.swift         # UI with Live Activity settings
│   └── SettingsView.swift             # Uncommented notifications row
└── Model/
    └── PrayerTimesFetcher.swift       # Auto-schedules on data fetch

NooraniWidgetExtension/
├── NooraniWidgetBundle.swift          # Widget entry point
└── PrayerCountdownLiveActivity.swift  # Lock Screen + Dynamic Island UI
```

### Data Flow:

```
User enables notifications
        ↓
NotificationsViewModel.toggleNotifications()
        ↓
Requests permission via NotificationScheduler
        ↓
PrayerTimesFetcher fetches prayer times
        ↓
Automatically calls:
  - NotificationScheduler.scheduleAllNotifications()
  - LiveActivityManager.scheduleAllLiveActivities()
        ↓
Notifications scheduled at (prayerTime - userOffset)
Live Activities start at (prayerTime - liveActivityOffset)
```

---

## Testing

### Test Notifications:

1. Enable notifications in Settings
2. Set offset to 1-2 minutes for quick testing
3. Wait for next prayer time - offset
4. Notification should appear with prayer name and time

### Test Live Activities:

1. Enable Live Activities in Settings
2. Set start offset to 5-10 minutes for testing
3. Live Activity will appear:
   - **Dynamic Island** (iPhone 14 Pro+)
   - **Lock Screen** banner with countdown timer
4. Timer automatically updates every second
5. Activity ends after prayer time

### Debug Commands:

```swift
// List pending notifications (add to any view for debugging)
NotificationScheduler.shared.getPendingNotifications { requests in
    for request in requests {
        print("Scheduled: \(request.identifier)")
    }
}

// Check Live Activity status
if #available(iOS 16.1, *) {
    let (available, authorized) = LiveActivityManager.shared.checkAvailability()
    print("Live Activities: available=\(available), authorized=\(authorized)")
}
```

---

## User Settings

Users can customize:

1. **Notification Offset**: 0-60 minutes before prayer (5-minute increments)
2. **Expiration Offset**: 0-60 minutes before prayer ends
3. **Per-Prayer Toggles**: Enable/disable for each prayer individually
4. **Live Activity Offset**: 15-60 minutes before prayer to start countdown
5. **Live Activity Enable/Disable**: Master toggle

---

## Design Features

### Lock Screen View:
- Golden gradient timer (#fab555 → #d4892e)
- Prayer icon with name
- Large countdown timer with shadow
- Cream background (#feecd3)
- Prayer time display

### Dynamic Island:
- **Expanded**: Full countdown with gradient, prayer info
- **Compact Leading**: Prayer icon in gold
- **Compact Trailing**: Timer in gold
- **Minimal**: Just the prayer icon

### Color Palette:
- Primary Gold: `#fab555`
- Dark Gold: `#d4892e`
- Cream: `#feecd3`
- Background: White with cream overlay

---

## Important Notes

1. **Device Required**: Live Activities only work on physical devices
2. **iOS Version**: Live Activities require iOS 16.1+, Dynamic Island requires iPhone 14 Pro+
3. **No Server Needed**: Everything runs locally on-device
4. **Battery Efficient**: Uses system scheduling, no background polling
5. **Timezone Aware**: Uses prayer times from API with correct timezone

---

## Troubleshooting

### Notifications not appearing:
- Check notification permissions in iOS Settings
- Verify `notificationsEnabled` is true in UserDefaults
- Check prayer times are being fetched successfully
- Look for scheduling logs in console

### Live Activities not starting:
- Verify iOS 16.1+ on device
- Check `ActivityAuthorizationInfo().areActivitiesEnabled`
- Ensure Widget Extension is properly configured
- Test with simulator first (limited support)

### Firebase not initializing:
- Confirm `GoogleService-Info.plist` is in project
- Verify Firebase SDK is added via SPM
- Check for initialization logs on app launch

---

## Next Steps

After completing this setup:

1. **Add Custom Sounds**: Create custom notification sounds for different prayers
2. **Background Refresh**: Fetch prayer times daily in background
3. **Push-to-Start**: Add APNs support for remote Live Activity triggers
4. **Widgets**: Add home screen widgets for prayer times
5. **Complications**: Add Apple Watch complications

---

## Credits

Implementation follows patterns from LivePolls project while adapting to Noorani's unique prayer time use case with beautiful golden theme colors.

**Built with:**
- SwiftUI
- ActivityKit
- UserNotifications
- Firebase SDK
