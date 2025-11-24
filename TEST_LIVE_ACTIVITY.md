# Live Activity Testing Guide

This guide explains how to truly test Live Activity delivery via APNs (not just the test function).

## Prerequisites

1. ✅ Firebase Cloud Functions deployed
2. ✅ App installed on physical device (Live Activities don't work in Simulator)
3. ✅ Live Activities enabled in app settings
4. ✅ Device has registered a push-to-start token

## Method 1: Direct APNs Test (Real Production Test)

This sends a real APNs payload directly to your device using the test script.

### Setup

```bash
cd /Users/neo/repos/noorani
npm install --prefix functions jsonwebtoken
```

### Run the Test

```bash
# Test with automatic user detection (finds first user with token)
node test-live-activity.js

# Test with specific user ID (device UUID)
node test-live-activity.js <USER_ID>
```

### What to Expect

1. Script fetches your device's push-to-start token from Firestore
2. Creates a Live Activity payload for **Midnight** (since it's always upcoming)
3. Sends real APNs HTTP/2 request with JWT authentication
4. You should see:
   - ✅ Success message with apns-id
   - 📱 Live Activity appears on your device's Lock Screen
   - 🔔 Notification sound plays
   - ⏱️ Countdown timer shows time until Midnight

### If It Doesn't Work

**Check Firestore Data:**
```bash
# View user data in Firestore
firebase firestore:get users/<USER_ID>

# Or use Firebase Console
# Navigate to Firestore > users collection
# Check that your device has:
#   - pushToStartToken (64-char hex string)
#   - location (lat/lng)
#   - preferences.enabledPrayers (array with "Midnight")
```

**Verify APNs Setup:**
```bash
# Make sure key file exists
ls -la functions/AuthKey_G6MKVPN5C3.p8

# Should show:
# -rw-r--r--  1 user  staff  227 Nov 17 22:00 AuthKey_G6MKVPN5C3.p8
```

**Check Device Token:**
1. Open Xcode Console
2. Run the app on your device
3. Look for logs:
   ```
   ✅ PushToStartManager: Received push-to-start token: <token>
   ```
4. Copy the token and verify it matches Firestore

**APNs Environment:**
- Development builds use: `api.sandbox.push.apple.com`
- Production builds use: `api.push.apple.com`
- Update `APNS_HOST` in test script if needed

## Method 2: Firebase Cloud Function Test

Use the existing Cloud Function to send a test.

### Run the Function

```bash
# Call the test endpoint
curl -X POST https://us-central1-<PROJECT_ID>.cloudfunctions.net/testPushToStart

# Or use Firebase Console:
# 1. Go to Functions
# 2. Find testPushToStart
# 3. Click "Test function"
# 4. Click "Run"
```

### Limitations

This method only confirms the function runs successfully, but doesn't guarantee APNs delivery because:
- No way to verify the payload reached APNs
- No apns-id returned for tracking
- Can't see APNs error responses

## Method 3: Wait for Scheduled Function

The Cloud Function runs every 5 minutes automatically.

### How It Works

1. Function queries Firestore for all users
2. For each user:
   - Fetches prayer times based on location
   - Finds next prayer within offset window (default 30 minutes)
   - Sends push-to-start payload via APNs
3. Live Activity appears on device

### Check Function Logs

```bash
# View real-time logs
firebase functions:log --only scheduleLiveActivities

# Or use Firebase Console:
# Functions > scheduleLiveActivities > Logs
```

### Force a Specific Prayer

If you want to test a specific prayer (like Midnight):

1. **Update User Preferences in Firestore:**
   ```javascript
   // Firebase Console > Firestore > users > [your-device-id]
   preferences: {
     liveActivityStartOffset: 180,  // 3 hours before prayer
     enabledPrayers: ["Midnight"]   // Only Midnight
   }
   ```

2. **Wait for next function run** (every 5 minutes)

3. **Or manually trigger function:**
   ```bash
   # Deploy with --only to trigger
   firebase deploy --only functions:scheduleLiveActivities
   ```

## Troubleshooting

### "No users found with push-to-start token"

**Solution:**
1. Open the app on your device
2. Navigate to Settings
3. Toggle Live Activities OFF then ON
4. Close the app completely
5. Reopen the app
6. Check Xcode Console for token registration logs
7. Verify Firestore shows the token

### "APNs error: 400 - BadDeviceToken"

**Possible Causes:**
- Token is from wrong environment (sandbox vs production)
- Token expired or was revoked
- App was deleted and reinstalled (token changed)

**Solution:**
1. Delete app from device
2. Clean build folder in Xcode
3. Rebuild and install
4. Check for new token in logs

### "APNs error: 403 - Forbidden"

**Possible Causes:**
- Invalid APNs key or certificate
- Wrong Bundle ID in request
- JWT token expired

**Solution:**
1. Verify `AuthKey_G6MKVPN5C3.p8` is valid
2. Check TEAM_ID and KEY_ID in script
3. Regenerate JWT token (script does this automatically)

### Live Activity Doesn't Appear

**Check:**
1. **Device Settings:**
   - Settings > Noorani > Live Activities = ON
   - Settings > Notifications > Noorani = Allowed

2. **App Settings:**
   - Open app > Settings > Live Activities = Enabled
   - Individual prayer toggles = ON

3. **System Requirements:**
   - iOS 16.1+ (for basic Live Activities)
   - iOS 17.2+ (for push-to-start)
   - Physical device (not Simulator)

4. **Active Live Activity:**
   - Only one Live Activity can be active at a time
   - If one is already showing, new one won't appear
   - Swipe to dismiss existing one first

### Sound Doesn't Play

**Check:**
1. Device is not in Silent mode
2. Volume is turned up
3. Do Not Disturb is off
4. Focus modes aren't blocking notifications

**Note:** The APNs payload includes `"sound": "default"` which should play the default notification sound when the Live Activity starts.

## Production Readiness Checklist

- [ ] Timezone bug fixed (city lookup works correctly)
- [ ] App startup is fast (no freezing)
- [ ] Midnight enabled for Live Activities
- [ ] Cloud Functions deployed successfully
- [ ] APNs key configured correctly
- [ ] Device token registered in Firestore
- [ ] Test script confirms APNs delivery
- [ ] Live Activity appears on Lock Screen
- [ ] Sound plays when Live Activity starts
- [ ] Countdown timer updates correctly
- [ ] All enabled prayers get Live Activities

## Getting User ID for Testing

```bash
# List all users with push-to-start tokens
firebase firestore:query users --where 'pushToStartToken' '>=' ''

# Or use Firebase Console > Firestore > users
# Look for documents with pushToStartToken field
# Document ID = User ID (device UUID)
```

## Next Steps

Once testing confirms Live Activities work:

1. ✅ Test with different prayers (Fajr, Dhuhr, Maghrib, Midnight)
2. ✅ Test in different timezones
3. ✅ Test with app in background
4. ✅ Test with app killed completely
5. ✅ Test on multiple devices
6. ✅ Monitor Cloud Function costs (runs every 5 min = ~8,640 invocations/month)
7. ✅ Set up monitoring/alerting for failures
8. ✅ Document for users in App Store description

## Cost Optimization

The Cloud Function runs every 5 minutes. To reduce costs:

**Option 1: Increase interval**
```javascript
// functions/index.js
exports.scheduleLiveActivities = functions.pubsub
  .schedule('every 15 minutes')  // Change from 'every 5 minutes'
  .onRun(async (context) => {
```

**Option 2: Run only during prayer times**
```javascript
// Only run during active hours (e.g., 4 AM - 11 PM)
exports.scheduleLiveActivities = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async (context) => {
    const hour = new Date().getHours();
    if (hour < 4 || hour > 23) {
      console.log('Outside active hours, skipping');
      return;
    }
    // ... rest of function
  });
```

**Option 3: On-demand triggers**
```javascript
// Instead of schedule, use Firestore triggers
// when user settings change
exports.onUserSettingsChange = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    // Recalculate and reschedule Live Activities
  });
```
