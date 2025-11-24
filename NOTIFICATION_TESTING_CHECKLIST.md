# Notification System - Production Testing Checklist

## 🎯 Testing Goal
Ensure notifications are **production-ready** with:
- ✅ Smart rescheduling (only when needed)
- ✅ No unnecessary API calls
- ✅ No data loss or corrupted state
- ✅ Proper persistence across app restarts
- ✅ Correct behavior for all edge cases

---

## 📋 Test Scenarios

### ✅ CATEGORY 1: First Launch / Fresh Install

#### Test 1.1: First App Launch
**Steps:**
1. Delete app from device/simulator
2. Reinstall and launch app
3. Grant location permission
4. Grant notification permission

**Expected Results:**
- ✅ Console shows: `"📅 RESCHEDULE REASON: First time scheduling"`
- ✅ Fetches 30 days of prayer times
- ✅ Schedules ~90 notifications (3 prayers × 30 days)
- ✅ Debug view shows:
  - Total: ~90-95 notifications
  - Fajr: ~30 notifications
  - Coverage: 28-30 days
  - Last scheduled location saved
  - Last scheduled method ID saved

**Pass/Fail:** ___________

---

### ✅ CATEGORY 2: App Reopening (Same Location)

#### Test 2.1: Reopen App After 1 Hour (Same Location)
**Steps:**
1. Complete Test 1.1
2. Close app
3. Wait 1 hour
4. Reopen app

**Expected Results:**
- ✅ Console shows: `"✅ Notifications still valid, no rescheduling needed"`
- ✅ Console shows: `"Location unchanged"`, `"Days remaining: X"`
- ❌ Does NOT fetch new prayer times
- ❌ Does NOT reschedule notifications
- ✅ Debug view still shows same ~90 notifications

**Pass/Fail:** ___________

#### Test 2.2: Reopen App After 1 Day (Same Location)
**Steps:**
1. Complete Test 1.1
2. Close app
3. Wait 24 hours (or change system date +1 day)
4. Reopen app

**Expected Results:**
- ✅ Console shows: `"✅ Notifications still valid, no rescheduling needed"`
- ✅ Days remaining decreases by 1
- ❌ Does NOT reschedule
- ✅ Notifications still valid

**Pass/Fail:** ___________

#### Test 2.3: Reopen App After 20 Days (Same Location)
**Steps:**
1. Complete Test 1.1
2. Close app
3. Change system date +20 days
4. Reopen app

**Expected Results:**
- ✅ Console shows: `"✅ Notifications still valid, no rescheduling needed"`
- ✅ Days remaining: ~8-10 days
- ❌ Does NOT reschedule (still > 7 days)

**Pass/Fail:** ___________

#### Test 2.4: Reopen App After 24 Days (Same Location) - TRIGGERS RESCHEDULE
**Steps:**
1. Complete Test 1.1
2. Close app
3. Change system date +24 days
4. Reopen app

**Expected Results:**
- ✅ Console shows: `"⏰ RESCHEDULE REASON: Notifications expiring soon"`
- ✅ Console shows: `"Days remaining: X"` (where X < 7)
- ✅ Fetches new 30 days
- ✅ Reschedules notifications
- ✅ Debug view shows new coverage extending 30 days from current date

**Pass/Fail:** ___________

---

### ✅ CATEGORY 3: Location Changes

#### Test 3.1: Minor Location Change (< 5km)
**Steps:**
1. Complete Test 1.1 at Location A
2. Close app
3. Change location by ~2km (e.g., move ~0.02 degrees)
4. Reopen app

**Expected Results:**
- ✅ Console shows: `"✅ Notifications still valid, no rescheduling needed"`
- ✅ Console shows location difference: `"(lat: 0.02, lng: 0.02)"`
- ❌ Does NOT reschedule (below 5km threshold)

**Pass/Fail:** ___________

#### Test 3.2: Significant Location Change (> 5km) - TRIGGERS RESCHEDULE
**Steps:**
1. Complete Test 1.1 at Location A (e.g., New York: 40.7128, -74.0060)
2. Close app
3. Change location to Location B significantly (e.g., Boston: 42.3601, -71.0589)
   - Difference: ~2.5 degrees ≈ 300km
4. Reopen app

**Expected Results:**
- ✅ Console shows: `"📍 RESCHEDULE REASON: Location changed"`
- ✅ Console shows: `"Previous: (40.7128, -74.0060)"`
- ✅ Console shows: `"Current: (42.3601, -71.0589)"`
- ✅ Console shows: `"Difference: (lat: 2.5, lng: 3.5)"`
- ✅ Fetches new 30 days for new location
- ✅ Reschedules notifications
- ✅ Debug view shows new location saved
- ✅ Prayer times reflect new location

**Pass/Fail:** ___________

#### Test 3.3: Location Change Across Timezone
**Steps:**
1. Complete Test 1.1 at New York (EST: UTC-5)
2. Close app
3. Change location to Los Angeles (PST: UTC-8)
4. Reopen app

**Expected Results:**
- ✅ Reschedules due to location change
- ✅ Prayer times reflect new timezone
- ✅ Notifications scheduled with correct timezone

**Pass/Fail:** ___________

---

### ✅ CATEGORY 4: Calculation Method Changes

#### Test 4.1: Change Calculation Method - TRIGGERS RESCHEDULE
**Steps:**
1. Complete Test 1.1 with method "TEHRAN" (ID: 7)
2. Go to Settings → Prayer Time Calculation
3. Change method to "ISNA" (ID: 2)
4. Go back to home screen

**Expected Results:**
- ✅ Console shows: `"🔢 RESCHEDULE REASON: Calculation method changed"`
- ✅ Console shows: `"Previous method ID: 7"`
- ✅ Console shows: `"Current method ID: 2"`
- ✅ Fetches new 30 days with new method
- ✅ Reschedules notifications
- ✅ Prayer times reflect new calculation method
- ✅ Debug view shows new method ID

**Pass/Fail:** ___________

---

### ✅ CATEGORY 5: Notification Enable/Disable

#### Test 5.1: Disable Notifications
**Steps:**
1. Complete Test 1.1
2. Verify ~90 notifications scheduled
3. Go to Settings → Notifications
4. Toggle "Enable Notifications" OFF
5. Check Debug view

**Expected Results:**
- ✅ Toggle stays OFF when closing and reopening settings
- ✅ Debug view shows: 0 notifications
- ✅ UserDefaults saved: `notificationsEnabled = false`

**Pass/Fail:** ___________

#### Test 5.2: Re-enable Notifications
**Steps:**
1. Complete Test 5.1
2. Toggle "Enable Notifications" ON
3. Go back to home screen
4. Check Debug view

**Expected Results:**
- ✅ Reschedules 30 days of notifications
- ✅ Debug view shows: ~90 notifications
- ✅ Toggle stays ON when closing and reopening

**Pass/Fail:** ___________

#### Test 5.3: Disable Notifications, Close App, Reopen
**Steps:**
1. Complete Test 5.1 (notifications disabled)
2. Force close app
3. Reopen app
4. Go to Settings → Notifications

**Expected Results:**
- ✅ Toggle still shows OFF
- ✅ Debug view shows: 0 notifications
- ✅ No rescheduling happens on app open

**Pass/Fail:** ___________

---

### ✅ CATEGORY 6: Per-Prayer Notification Settings

#### Test 6.1: Default Prayer Settings (Asr & Isha OFF)
**Steps:**
1. Fresh install
2. Enable notifications
3. Check Debug view

**Expected Results:**
- ✅ Fajr notifications: ~30 ✅
- ✅ Dhuhr notifications: ~30 ✅
- ❌ Asr notifications: 0 (OFF by default)
- ✅ Maghrib notifications: ~30 ✅
- ❌ Isha notifications: 0 (OFF by default)
- ✅ Total: ~90 notifications

**Pass/Fail:** ___________

#### Test 6.2: Enable All 5 Prayers
**Steps:**
1. Complete Test 6.1
2. Go to Settings → Notifications
3. Enable Asr Start Notification
4. Enable Isha Start Notification
5. Go back to home screen

**Expected Results:**
- ✅ Reschedules with all 5 prayers
- ✅ Debug view shows:
  - Fajr: ~30
  - Dhuhr: ~30
  - Asr: ~30
  - Maghrib: ~30
  - Isha: ~30
- ✅ Total: ~150 notifications
- ⚠️ Coverage might be ~12-20 days (limited by 61 notification cap)

**Pass/Fail:** ___________

#### Test 6.3: Disable Specific Prayer
**Steps:**
1. Complete Test 6.1
2. Disable Fajr Start Notification
3. Go back to home screen

**Expected Results:**
- ✅ Reschedules without Fajr
- ✅ Fajr notifications: 0
- ✅ Dhuhr + Maghrib still scheduled: ~60 total

**Pass/Fail:** ___________

---

### ✅ CATEGORY 7: System Permission Changes

#### Test 7.1: Revoke Notification Permission
**Steps:**
1. Complete Test 1.1 (notifications enabled and scheduled)
2. Go to iOS Settings → Noorani
3. Disable Notifications
4. Return to app
5. Go to Settings → Notifications

**Expected Results:**
- ✅ Toggle automatically switches to OFF
- ✅ Saved preference updates to disabled
- ⚠️ Shows alert prompting user to re-enable in Settings

**Pass/Fail:** ___________

#### Test 7.2: Re-grant Notification Permission
**Steps:**
1. Complete Test 7.1
2. Go to iOS Settings → Noorani
3. Enable Notifications
4. Return to app
5. Toggle "Enable Notifications" ON in app

**Expected Results:**
- ✅ Reschedules notifications
- ✅ ~90 notifications scheduled

**Pass/Fail:** ___________

---

### ✅ CATEGORY 8: Edge Cases & Error Handling

#### Test 8.1: No Internet Connection on First Launch
**Steps:**
1. Fresh install
2. Turn off WiFi and cellular data
3. Launch app
4. Grant permissions

**Expected Results:**
- ✅ App doesn't crash
- ✅ Shows prayer times for current day (if possible)
- ✅ Console shows: `"❌ FAILED to fetch 30 days of prayer times"`
- ⚠️ Fallback to daily scheduling (today + tomorrow's Fajr)
- ✅ When internet restored and app reopened, reschedules 30 days

**Pass/Fail:** ___________

#### Test 8.2: Invalid Location (0.0, 0.0)
**Steps:**
1. Fresh install
2. Deny location permission
3. Launch app (location defaults to 0.0, 0.0)

**Expected Results:**
- ✅ Console shows: `"❌ No location for month fetch"`
- ✅ Returns empty dictionary
- ✅ Falls back to daily scheduling
- ⚠️ Shows user prompt to enable location

**Pass/Fail:** ___________

#### Test 8.3: App Crash During Notification Scheduling
**Steps:**
1. Complete Test 1.1
2. During notification scheduling, force kill app (simulate crash)
3. Reopen app

**Expected Results:**
- ✅ App recovers gracefully
- ✅ Checks if rescheduling needed
- ✅ If incomplete, reschedules
- ✅ No corrupted state

**Pass/Fail:** ___________

#### Test 8.4: Change Location While Notifications Scheduling
**Steps:**
1. Start app at Location A
2. While scheduling is in progress (first 5 seconds), change to Location B
3. Wait for scheduling to complete

**Expected Results:**
- ✅ Completes scheduling for Location A
- ✅ On next app open, detects location change
- ✅ Reschedules for Location B

**Pass/Fail:** ___________

---

### ✅ CATEGORY 9: Long-term Stability

#### Test 9.1: Run App for 30 Days Continuously
**Steps:**
1. Complete Test 1.1
2. Set system date +1 day, reopen app (repeat 30 times)

**Expected Results:**
- ✅ No rescheduling for first 23 days
- ✅ Reschedules when < 7 days remain
- ✅ After reschedule, has another 30 days
- ✅ No memory leaks
- ✅ No notification duplication

**Pass/Fail:** ___________

#### Test 9.2: Multiple Location Changes in One Day
**Steps:**
1. Complete Test 1.1 at Location A
2. Change to Location B (> 5km) → Triggers reschedule
3. Immediately change to Location C (> 5km from B) → Triggers another reschedule
4. Change to Location D (> 5km from C) → Triggers another reschedule

**Expected Results:**
- ✅ Each location change triggers reschedule
- ✅ Final notifications reflect Location D
- ✅ No stale notifications from A, B, C
- ✅ App remains responsive

**Pass/Fail:** ___________

---

### ✅ CATEGORY 10: Background & Foreground Transitions

#### Test 10.1: Background App for 1 Hour
**Steps:**
1. Complete Test 1.1
2. Send app to background (don't force close)
3. Wait 1 hour
4. Bring app to foreground

**Expected Results:**
- ✅ No rescheduling (notifications still valid)
- ✅ App resumes normally

**Pass/Fail:** ___________

#### Test 10.2: Background App Across Midnight
**Steps:**
1. Complete Test 1.1 at 11:00 PM
2. Send app to background
3. Wait until 12:30 AM (cross midnight)
4. Bring app to foreground

**Expected Results:**
- ✅ No rescheduling (notifications still valid)
- ✅ Current prayer times update to new day
- ✅ Scheduled notifications unchanged

**Pass/Fail:** ___________

---

## 🏁 Final Production Checks

### ✅ Performance
- [ ] App launches < 3 seconds
- [ ] Notification scheduling doesn't block UI
- [ ] No unnecessary API calls
- [ ] Memory usage stable over time

### ✅ Data Integrity
- [ ] UserDefaults properly saved
- [ ] No data loss on crash
- [ ] No duplicate notifications
- [ ] Notification IDs unique

### ✅ User Experience
- [ ] Clear console logs for debugging
- [ ] Debug view shows accurate info
- [ ] Toggles persist correctly
- [ ] No unexpected behavior

### ✅ Edge Cases Covered
- [ ] All 10 categories tested
- [ ] No crashes in any scenario
- [ ] Graceful error handling
- [ ] Recovery from failures

---

## 📊 Test Results Summary

**Total Tests:** 32
**Passed:** _____
**Failed:** _____
**Production Ready:** YES / NO

**Critical Issues Found:**
1.
2.
3.

**Minor Issues Found:**
1.
2.
3.

**Tested By:** _________________
**Date:** _________________
**Build Version:** _________________

---

## 🚀 Production Deployment Checklist

Before deploying to production:
- [ ] All tests pass
- [ ] No critical issues
- [ ] Performance acceptable
- [ ] Error handling robust
- [ ] Logs cleaned up (remove excessive debug logs)
- [ ] User-facing error messages clear
- [ ] Analytics tracking added (optional)
- [ ] Crash reporting configured (optional)

**Deployment Approved By:** _________________
**Date:** _________________
