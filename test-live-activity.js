#!/usr/bin/env node
/**
 * Test Live Activity Push-to-Start with Real APNs
 *
 * This script sends a real APNs payload to your device to test Live Activity delivery.
 * Unlike the Firebase function that runs on a schedule, this sends immediately.
 */

const admin = require('firebase-admin');
const jwt = require('jsonwebtoken');
const http2 = require('http2');
const fs = require('fs');

// Initialize Firebase Admin
const serviceAccount = require('./functions/service-account-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// APNs Configuration
const TEAM_ID = '8C63825C8B';
const KEY_ID = 'YR622WH8KX';
const BUNDLE_ID = 'com.apbrology.Noorani';
const APNS_HOST = 'api.push.apple.com'; // Production APNs (for TestFlight/App Store)
const KEY_PATH = './functions/AuthKey_YR622WH8KX.p8';

/**
 * Generate JWT token for APNs authentication
 */
function generateAPNsToken() {
  const authKey = fs.readFileSync(KEY_PATH, 'utf8');

  const token = jwt.sign(
    {
      iss: TEAM_ID,
      iat: Math.floor(Date.now() / 1000)
    },
    authKey,
    {
      algorithm: 'ES256',
      header: {
        alg: 'ES256',
        kid: KEY_ID
      }
    }
  );

  return token;
}

/**
 * Send Live Activity push notification via APNs using HTTP/2
 */
function sendLiveActivityPush(deviceToken, payload) {
  return new Promise((resolve, reject) => {
    const authToken = generateAPNsToken();

    console.log('📤 Sending APNs request...');
    console.log('   Host:', APNS_HOST);
    console.log('   Topic:', `${BUNDLE_ID}.push-type.liveactivity`);
    console.log('   Device Token:', deviceToken.substring(0, 16) + '...');

    // Create HTTP/2 client
    const client = http2.connect(`https://${APNS_HOST}`);

    client.on('error', (err) => {
      console.log('❌ Connection error:', err.message);
      client.close();
      reject(err);
    });

    const headers = {
      ':method': 'POST',
      ':path': `/3/device/${deviceToken}`,
      'apns-topic': `${BUNDLE_ID}.push-type.liveactivity`,
      'apns-push-type': 'liveactivity',
      'apns-priority': '10',
      'authorization': `bearer ${authToken}`,
      'content-type': 'application/json'
    };

    const req = client.request(headers);

    req.on('response', (headers) => {
      const status = headers[':status'];
      const apnsId = headers['apns-id'];

      let data = '';

      req.on('data', (chunk) => {
        data += chunk;
      });

      req.on('end', () => {
        client.close();

        if (status === 200) {
          console.log('✅ APNs push sent successfully!');
          console.log('   apns-id:', apnsId);
          resolve({ success: true, apnsId: apnsId });
        } else {
          console.log('❌ APNs push failed!');
          console.log('   Status:', status);
          console.log('   Response:', data);
          reject(new Error(`APNs error: ${status} - ${data}`));
        }
      });
    });

    req.on('error', (err) => {
      console.log('❌ Request error:', err.message);
      client.close();
      reject(err);
    });

    req.write(JSON.stringify(payload));
    req.end();
  });
}

/**
 * Main test function
 */
async function testLiveActivity(userId = null, prayerName = 'Fajr', hoursFromNow = 6) {
  try {
    console.log('🧪 Starting Live Activity Push Test...\n');

    // Get user data from Firestore
    let userDoc;
    if (userId) {
      console.log(`🔍 Looking for user: ${userId}`);
      userDoc = await db.collection('users').doc(userId).get();
    } else {
      console.log('🔍 Finding first user with push-to-start token...');
      const snapshot = await db.collection('users')
        .where('pushToStartToken', '!=', null)
        .limit(1)
        .get();

      if (snapshot.empty) {
        throw new Error('No users found with push-to-start token!');
      }

      userDoc = snapshot.docs[0];
    }

    if (!userDoc.exists) {
      throw new Error('User not found!');
    }

    const userData = userDoc.data();
    console.log('✅ Found user:', userDoc.id);
    console.log('   Device:', userData.deviceInfo?.name || 'Unknown');
    console.log('   Token updated:', userData.tokenUpdatedAt?.toDate().toISOString() || 'Unknown');

    // Check if user has required data
    if (!userData.pushToStartToken) {
      throw new Error('User has no push-to-start token! Make sure the app registered.');
    }

    if (!userData.location) {
      throw new Error('User has no location data! Open the app to set location.');
    }

    console.log('\n📍 Location:', userData.location.latitude, userData.location.longitude);
    console.log('🕌 Enabled prayers:', userData.preferences?.enabledPrayers || []);

    // Create test Live Activity payload for specified prayer
    const now = new Date();
    const targetTime = new Date(now.getTime() + (hoursFromNow * 60 * 60 * 1000));

    const targetTimestamp = Math.floor(targetTime.getTime() / 1000);
    const remainingSeconds = Math.floor((targetTime - now) / 1000);

    // Format time for display
    const timeFormatter = new Intl.DateTimeFormat('en-US', {
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    });
    const formattedTime = timeFormatter.format(targetTime);

    // Prayer icons and colors
    const prayerConfig = {
      'Fajr': { icon: 'sunrise.fill', color: '#FF6B6B' },
      'Dhuhr': { icon: 'sun.max.fill', color: '#FFD93D' },
      'Asr': { icon: 'sun.min.fill', color: '#FFA500' },
      'Maghrib': { icon: 'moon.fill', color: '#6C5CE7' },
      'Isha': { icon: 'moon.stars.fill', color: '#4A5568' }
    };

    const config = prayerConfig[prayerName] || prayerConfig['Fajr'];

    console.log('\n⏰ Creating Live Activity for:');
    console.log('   Prayer:', prayerName);
    console.log('   Target Time:', targetTime.toISOString());
    console.log('   Formatted Time:', formattedTime);
    console.log('   Hours from now:', hoursFromNow);
    console.log('   Remaining:', Math.floor(remainingSeconds / 3600), 'hours', Math.floor((remainingSeconds % 3600) / 60), 'minutes');

    // CRITICAL: attributes-type and attributes must be OUTSIDE aps object!
    const payload = {
      "aps": {
        "timestamp": targetTimestamp,
        "event": "start",
        "sound": "default",
        "content-state": {
          "prayerName": prayerName,
          "targetTime": targetTimestamp,
          "remainingSeconds": remainingSeconds,
          "showTimer": true,
          "message": null
        }
      },
      "attributes-type": "PrayerCountdownAttributes",
      "attributes": {
        "prayerIcon": config.icon,
        "colorTheme": config.color,
        "formattedPrayerTime": formattedTime,
        "isExpirationWarning": false
      }
    };

    console.log('\n📦 Payload:');
    console.log(JSON.stringify(payload, null, 2));

    // Send the push
    console.log('\n🚀 Sending Live Activity push...');
    await sendLiveActivityPush(userData.pushToStartToken, payload);

    console.log('\n✅ Test completed successfully!');
    console.log('📱 Check your device for the Live Activity on:');
    console.log('   - Lock Screen');
    console.log('   - Dynamic Island (if iPhone 14 Pro or newer)');
    console.log('\n💡 If you don\'t see it:');
    console.log('   1. Make sure Live Activities are enabled in Settings > Noorani');
    console.log('   2. Check that the app has permission for Live Activities');
    console.log('   3. Verify you\'re using the correct device (check device name above)');
    console.log('   4. Try killing and reopening the app to refresh the token');

  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
    console.error('\nTroubleshooting:');
    console.error('  1. Make sure Firebase Admin SDK is initialized');
    console.error('  2. Verify service-account-key.json exists');
    console.error('  3. Check that AuthKey_G6MKVPN5C3.p8 exists');
    console.error('  4. Ensure the app has registered for Live Activities');
    console.error('  5. Check Firestore for user data');
    process.exit(1);
  }

  process.exit(0);
}

// Run the test
// Usage: node test-live-activity.js [userId] [prayer] [hours]
// Examples:
//   node test-live-activity.js
//   node test-live-activity.js ABC123
//   node test-live-activity.js ABC123 Fajr 6
//   node test-live-activity.js null Maghrib 2

const userId = process.argv[2] === 'null' ? null : process.argv[2];
const prayerName = process.argv[3] || 'Fajr';
const hoursFromNow = parseFloat(process.argv[4]) || 6;

console.log('📋 Test Parameters:');
if (userId) {
  console.log(`   User ID: ${userId}`);
} else {
  console.log('   User ID: Auto-detect (first user with token)');
}
console.log(`   Prayer: ${prayerName}`);
console.log(`   Hours from now: ${hoursFromNow}\n`);

testLiveActivity(userId, prayerName, hoursFromNow);
