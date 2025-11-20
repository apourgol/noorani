#!/usr/bin/env node
/**
 * Comprehensive Test Suite for Prayer Times Live Activity Automation
 *
 * This script validates:
 * 1. Firestore user data structure
 * 2. Prayer times API fetching
 * 3. Live Activity push delivery
 * 4. Scheduled function logic
 * 5. End-to-end automation flow
 */

const admin = require('firebase-admin');
const axios = require('axios');
const serviceAccount = require('./functions/service-account-key.json');

// Initialize Firebase Admin
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// Test configuration
const TEST_USER_ID = 'BA5A8407-99FD-4F21-A90F-AA0B98B057B2'; // Replace with your test device ID
const CLOUD_FUNCTION_URL = 'https://us-central1-noorani-8282d.cloudfunctions.net'; // Replace with your project

// Color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(emoji, message, color = colors.reset) {
  console.log(`${color}${emoji} ${message}${colors.reset}`);
}

function logSuccess(message) { log('✅', message, colors.green); }
function logError(message) { log('❌', message, colors.red); }
function logWarning(message) { log('⚠️', message, colors.yellow); }
function logInfo(message) { log('ℹ️', message, colors.cyan); }
function logSection(message) { console.log(`\n${colors.blue}━━━ ${message} ━━━${colors.reset}\n`); }

// Test results tracking
const results = {
  passed: 0,
  failed: 0,
  warnings: 0,
};

/**
 * Test 1: Validate Firestore User Data Structure
 */
async function testFirestoreData() {
  logSection('TEST 1: Firestore User Data Structure');

  try {
    const userDoc = await db.collection('users').doc(TEST_USER_ID).get();

    if (!userDoc.exists) {
      logError(`User ${TEST_USER_ID} not found in Firestore`);
      results.failed++;
      return false;
    }

    const userData = userDoc.data();
    logSuccess('User document found');

    // Validate push token
    if (!userData.pushToStartToken) {
      logError('Missing pushToStartToken');
      results.failed++;
      return false;
    }
    logSuccess(`Push token exists (${userData.pushToStartToken.substring(0, 20)}...)`);
    logInfo(`  Token length: ${userData.pushToStartToken.length} characters`);

    // Validate token age
    if (userData.tokenUpdatedAt) {
      const tokenAge = Math.floor((Date.now() - userData.tokenUpdatedAt.toDate()) / 1000);
      logInfo(`  Token age: ${tokenAge} seconds (${Math.floor(tokenAge / 60)} minutes)`);
      if (tokenAge > 86400) {
        logWarning('Token is over 24 hours old - may need refresh');
        results.warnings++;
      }
    }

    // Validate location
    if (!userData.location || !userData.location.latitude || !userData.location.longitude) {
      logError('Missing location data');
      results.failed++;
      return false;
    }
    logSuccess(`Location exists: ${userData.location.latitude}, ${userData.location.longitude}`);
    logInfo(`  Timezone: ${userData.location.timezone || 'Not set'}`);

    // Validate preferences
    const prefs = userData.preferences || {};
    logInfo(`  Live Activity offset: ${prefs.liveActivityStartOffset || 30} minutes`);
    logInfo(`  Enabled prayers: ${(prefs.enabledPrayers || ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']).join(', ')}`);
    logInfo(`  Calculation method: ${prefs.calculationMethod || 7}`);

    // Validate device info
    if (userData.deviceInfo) {
      logInfo(`  Device: ${userData.deviceInfo.name} (iOS ${userData.deviceInfo.systemVersion})`);
    }

    results.passed++;
    return true;
  } catch (error) {
    logError(`Firestore test failed: ${error.message}`);
    results.failed++;
    return false;
  }
}

/**
 * Test 2: Validate Prayer Times API
 */
async function testPrayerTimesAPI() {
  logSection('TEST 2: Prayer Times API Fetching');

  try {
    const userDoc = await db.collection('users').doc(TEST_USER_ID).get();
    const userData = userDoc.data();
    const location = userData.location || {};
    const method = userData.preferences?.calculationMethod || 7;

    const today = new Date();
    const dateStr = `${today.getDate()}-${today.getMonth() + 1}-${today.getFullYear()}`;

    logInfo(`Fetching prayer times for ${dateStr}`);
    logInfo(`  Location: ${location.latitude}, ${location.longitude}`);
    logInfo(`  Method: ${method}`);
    logInfo(`  Timezone: ${location.timezone || 'America/Los_Angeles'}`);

    const response = await axios.get(
      `https://api.aladhan.com/v1/timings/${dateStr}`,
      {
        params: {
          latitude: location.latitude,
          longitude: location.longitude,
          method: method,
          timezone: location.timezone || 'America/Los_Angeles',
        },
      }
    );

    if (response.data.code !== 200) {
      logError(`API returned error code: ${response.data.code}`);
      results.failed++;
      return false;
    }

    const timings = response.data.data.timings;
    logSuccess('Prayer times fetched successfully');

    const prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    for (const prayer of prayers) {
      if (timings[prayer]) {
        logInfo(`  ${prayer}: ${timings[prayer]}`);
      } else {
        logWarning(`  ${prayer}: Not available`);
        results.warnings++;
      }
    }

    results.passed++;
    return true;
  } catch (error) {
    logError(`Prayer times API test failed: ${error.message}`);
    results.failed++;
    return false;
  }
}

/**
 * Test 3: Check Scheduled Function Logic
 */
async function testScheduledLogic() {
  logSection('TEST 3: Scheduled Function Logic Simulation');

  try {
    const userDoc = await db.collection('users').doc(TEST_USER_ID).get();
    const userData = userDoc.data();
    const location = userData.location || {};
    const prefs = userData.preferences || {};
    const startOffset = prefs.liveActivityStartOffset || 30;
    const enabledPrayers = prefs.enabledPrayers || ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    const method = prefs.calculationMethod || 7;

    logInfo(`Simulating scheduled function logic:`);
    logInfo(`  Start offset: ${startOffset} minutes before prayer`);
    logInfo(`  Enabled prayers: ${enabledPrayers.join(', ')}`);

    // Fetch today's prayer times
    const today = new Date();
    const dateStr = `${today.getDate()}-${today.getMonth() + 1}-${today.getFullYear()}`;

    const response = await axios.get(
      `https://api.aladhan.com/v1/timings/${dateStr}`,
      {
        params: {
          latitude: location.latitude,
          longitude: location.longitude,
          method: method,
          timezone: location.timezone || 'America/Los_Angeles',
        },
      }
    );

    const timings = response.data.data.timings;
    const now = new Date();

    let foundUpcoming = false;

    for (const prayer of enabledPrayers) {
      if (!timings[prayer]) continue;

      const cleanTime = timings[prayer].split(' ')[0];
      const [hours, minutes] = cleanTime.split(':').map(Number);

      const prayerDate = new Date(
        today.getFullYear(),
        today.getMonth(),
        today.getDate(),
        hours,
        minutes
      );

      if (prayerDate < now) {
        logInfo(`  ${prayer}: Already passed (${cleanTime})`);
        continue;
      }

      const startTime = new Date(prayerDate.getTime() - startOffset * 60000);
      const diffMinutes = Math.round((startTime - now) / 60000);
      const prayerInMinutes = Math.round((prayerDate - now) / 60000);

      logInfo(`  ${prayer}: In ${prayerInMinutes}min, start window in ${diffMinutes}min`);

      // Check if within the 4-minute window
      if (diffMinutes >= -1 && diffMinutes <= 3) {
        logSuccess(`    ✓ WOULD SEND NOW (within window)`);
        foundUpcoming = true;
      } else if (diffMinutes < -1) {
        logWarning(`    Start window passed`);
      } else {
        logInfo(`    Start window not reached yet`);
        foundUpcoming = true;
      }
    }

    if (!foundUpcoming) {
      logWarning('No upcoming prayers found for today');
      results.warnings++;
    }

    results.passed++;
    return true;
  } catch (error) {
    logError(`Scheduled logic test failed: ${error.message}`);
    results.failed++;
    return false;
  }
}

/**
 * Test 4: Test Live Activity Push (via Cloud Function)
 */
async function testLiveActivityPush() {
  logSection('TEST 4: Live Activity Push Delivery');

  try {
    logInfo(`Calling testPushToStart endpoint for user ${TEST_USER_ID}`);

    const response = await axios.get(
      `${CLOUD_FUNCTION_URL}/testPushToStart`,
      {
        params: { userId: TEST_USER_ID },
        timeout: 10000,
      }
    );

    if (response.data.success) {
      logSuccess('Test push sent successfully');
      logInfo(`  Token used: ${response.data.tokenUsed}`);
      logInfo(`  Check your device for Live Activity!`);
      results.passed++;
      return true;
    } else {
      logError(`Test push failed: ${JSON.stringify(response.data)}`);
      results.failed++;
      return false;
    }
  } catch (error) {
    if (error.response) {
      logError(`Cloud Function error: ${error.response.status} - ${JSON.stringify(error.response.data)}`);
    } else {
      logError(`Test push failed: ${error.message}`);
    }
    results.failed++;
    return false;
  }
}

/**
 * Test 5: Validate User Data via Cloud Function
 */
async function testCheckUserData() {
  logSection('TEST 5: Cloud Function User Data Check');

  try {
    const response = await axios.get(
      `${CLOUD_FUNCTION_URL}/checkUserData`,
      {
        params: { userId: TEST_USER_ID },
        timeout: 10000,
      }
    );

    const data = response.data;

    logInfo('Cloud Function returned:');
    logInfo(`  Has push token: ${data.hasPushToken}`);
    logInfo(`  Token length: ${data.tokenLength}`);
    logInfo(`  Has location: ${data.hasLocation}`);
    logInfo(`  Location: ${JSON.stringify(data.location)}`);
    logInfo(`  Preferences: ${JSON.stringify(data.preferences)}`);

    if (data.hasPushToken && data.hasLocation) {
      logSuccess('User data is complete and ready for automation');
      results.passed++;
      return true;
    } else {
      logError('User data is incomplete');
      results.failed++;
      return false;
    }
  } catch (error) {
    logError(`Check user data failed: ${error.message}`);
    results.failed++;
    return false;
  }
}

/**
 * Run all tests
 */
async function runAllTests() {
  console.log(`\n${colors.blue}╔════════════════════════════════════════════════════════════╗`);
  console.log(`║  Prayer Times Live Activity - Automation Test Suite   ║`);
  console.log(`╚════════════════════════════════════════════════════════════╝${colors.reset}\n`);

  logInfo(`Test User ID: ${TEST_USER_ID}`);
  logInfo(`Cloud Functions URL: ${CLOUD_FUNCTION_URL}`);

  // Run tests sequentially
  await testFirestoreData();
  await testPrayerTimesAPI();
  await testScheduledLogic();
  await testCheckUserData();
  await testLiveActivityPush();

  // Print summary
  logSection('TEST SUMMARY');

  console.log(`${colors.green}✅ Passed: ${results.passed}${colors.reset}`);
  console.log(`${colors.red}❌ Failed: ${results.failed}${colors.reset}`);
  console.log(`${colors.yellow}⚠️  Warnings: ${results.warnings}${colors.reset}`);

  const total = results.passed + results.failed;
  const successRate = Math.round((results.passed / total) * 100);

  console.log(`\nSuccess Rate: ${successRate}%\n`);

  if (results.failed === 0) {
    logSuccess('All tests passed! ✨ Automation is ready for deployment.');
    console.log('\nNext steps:');
    console.log('1. Archive and upload to TestFlight');
    console.log('2. Deploy Cloud Functions: cd functions && firebase deploy --only functions');
    console.log('3. Monitor logs: firebase functions:log --only schedulePrayerLiveActivities');
    process.exit(0);
  } else {
    logError('Some tests failed. Please fix issues before deployment.');
    process.exit(1);
  }
}

// Run tests
runAllTests().catch((error) => {
  logError(`Fatal error: ${error.message}`);
  console.error(error);
  process.exit(1);
});
