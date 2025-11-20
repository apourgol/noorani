const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onRequest} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const axios = require("axios");
const http2 = require("http2");
const jwt = require("jsonwebtoken");
const fs = require("fs");
const path = require("path");

// Initialize Firebase Admin
initializeApp();
const db = getFirestore();

// APNs Configuration
const APNS_KEY_ID = "YR622WH8KX";
const APNS_TEAM_ID = "8C63825C8B";
const APNS_KEY_PATH = path.join(__dirname, "AuthKey_YR622WH8KX.p8");
// Production APNs server (for TestFlight and App Store builds)
const APNS_HOST = "api.push.apple.com";
const BUNDLE_ID = "com.apbrology.Noorani"; // Match Xcode bundle ID exactly

// Cache for JWT token
let cachedToken = null;
let tokenExpiry = 0;

/**
 * Generate JWT token for APNs authentication
 * @return {string} JWT token
 */
function generateAPNsToken() {
  const now = Math.floor(Date.now() / 1000);

  // Reuse cached token if still valid (tokens are valid for 1 hour)
  if (cachedToken && tokenExpiry > now + 60) {
    return cachedToken;
  }

  const privateKey = fs.readFileSync(APNS_KEY_PATH, "utf8");

  const token = jwt.sign(
      {
        iss: APNS_TEAM_ID,
        iat: now,
      },
      privateKey,
      {
        algorithm: "ES256",
        header: {
          alg: "ES256",
          kid: APNS_KEY_ID,
        },
      },
  );

  cachedToken = token;
  tokenExpiry = now + 3600; // Token valid for 1 hour

  return token;
}

// Scheduled function that runs every 3 minutes for better coverage
// Wider window (-2 to +5 min) ensures no prayers are missed
exports.schedulePrayerLiveActivities = onSchedule(
    {
      schedule: "every 3 minutes",
      timeoutSeconds: 60,
      memory: "256MiB",
    },
    async (event) => {
      console.log("Checking for upcoming prayers...");

      const usersRef = db.collection("users");

      try {
        const snapshot = await usersRef.get();
        console.log(`Found ${snapshot.size} users to check`);

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
            "Fajr", "Dhuhr", "Asr", "Maghrib", "Isha",
          ];
          const calculationMethod = preferences.calculationMethod ?
            parseInt(preferences.calculationMethod) : 7;

          // Skip if no location
          if (!location.latitude || !location.longitude) {
            console.log(`User ${doc.id} has no location data`);
            continue;
          }

          console.log(
              `User ${doc.id} using method: ${calculationMethod}`,
          );

          // Fetch TODAY's prayer times from Al-Adhan API
          const todayPrayerTimes = await fetchPrayerTimes(
              location.latitude,
              location.longitude,
              location.timezone || "America/Los_Angeles",
              calculationMethod,
              0, // today (offset = 0 days)
          );

          // Fetch TOMORROW's prayer times for prayers that may have passed
          const tomorrowPrayerTimes = await fetchPrayerTimes(
              location.latitude,
              location.longitude,
              location.timezone || "America/Los_Angeles",
              calculationMethod,
              1, // tomorrow (offset = 1 day)
          );

          if (!todayPrayerTimes || !tomorrowPrayerTimes) {
            console.log(`Failed to fetch prayer times for user ${doc.id}`);
            continue;
          }

          // Check each prayer
          console.log(`  Offset: ${startOffset} minutes`);
          console.log(`  Enabled prayers: ${enabledPrayers.join(", ")}`);

          const now = new Date();

          for (const prayer of enabledPrayers) {
            // Try today's prayer time first
            let prayerTime = todayPrayerTimes[prayer];
            let prayerDate = prayerTime ? new Date(prayerTime) : null;

            // If today's prayer has passed, use tomorrow's
            if (prayerDate && prayerDate < now) {
              console.log(
                  `  ${prayer}: Today's time passed, checking tomorrow...`,
              );
              prayerTime = tomorrowPrayerTimes[prayer];
              prayerDate = prayerTime ? new Date(prayerTime) : null;
            }

            if (!prayerDate) {
              console.log(`  ${prayer}: No time available`);
              continue;
            }

            const startTime = new Date(
                prayerDate.getTime() - startOffset * 60000,
            );

            // If we're within the window to start Live Activity
            // Window: -2 to +5 minutes (7-minute total window)
            // This accounts for:
            // 1. Function runs every 5 minutes
            // 2. Processing delays (multiple users in queue)
            // 3. Floating-point precision
            // 4. Clock skew between servers
            const diffMinutes = (startTime - now) / 60000;
            const prayerInMinutes = (prayerDate - now) / 60000;

            console.log(
                `  ${prayer}: In ${Math.round(prayerInMinutes)}min, ` +
            `start window in ${Math.round(diffMinutes)}min`,
            );

            // Send if within -2 to +5 minute window (wider for reliability)
            if (diffMinutes >= -2 && diffMinutes <= 5) {
              console.log(
                  `  ✅ Sending Live Activity for ${prayer} to ` +
                  `user ${doc.id}`,
              );

              await sendPushToStartLiveActivity(
                  userData.pushToStartToken,
                  prayer,
                  prayerDate,
                  getPrayerIcon(prayer),
              );
            } else if (diffMinutes < -2) {
              console.log(`  ⏭️  ${prayer}: Start window passed`);
            } else {
              console.log(`  ⏰ ${prayer}: Start window not reached yet`);
            }
          }
        }

        console.log("Finished checking all users");
      } catch (error) {
        console.error("Error in schedulePrayerLiveActivities:", error);
      }
    },
);

/**
 * Fetch prayer times from Al-Adhan API
 * @param {number} latitude - The latitude coordinate
 * @param {number} longitude - The longitude coordinate
 * @param {string} timezone - The timezone string (IANA format)
 * @param {number} method - Calculation method ID (default: 7)
 * @param {number} dayOffset - Number of days from today (0=today, 1=tomorrow)
 * @return {Object|null} Prayer times object or null if failed
 */
async function fetchPrayerTimes(
    latitude,
    longitude,
    timezone,
    method = 7,
    dayOffset = 0,
) {
  try {
    // Calculate the target date (today + offset)
    const targetDate = new Date();
    targetDate.setDate(targetDate.getDate() + dayOffset);

    const dateStr = `${targetDate.getDate()}-${
      targetDate.getMonth() + 1}-${targetDate.getFullYear()}`;

    console.log(
        `Fetching times for ${dateStr}: method=${method}, ` +
        `lat=${latitude}, lng=${longitude}, tz=${timezone}`,
    );

    const response = await axios.get(
        `https://api.aladhan.com/v1/timings/${dateStr}`,
        {
          params: {
            latitude: latitude,
            longitude: longitude,
            method: method,
            timezone: timezone, // CRITICAL: API returns times in this timezone
          },
        },
    );

    if (response.data.code === 200) {
      const timings = response.data.data.timings;
      const date = response.data.data.date;

      console.log(
          `  API returned date: ${date.readable} (${date.gregorian.date})`,
      );

      // TIMEZONE FIX: Use the API's timestamp which is already timezone-aware
      // The API returns timestamps that account for the requested timezone
      const prayerTimes = {};

      // Get the date components from the API response
      const dateComponents = date.gregorian.date.split("-");
      const day = parseInt(dateComponents[0]);
      const month = parseInt(dateComponents[1]) - 1; // JS months are 0-indexed
      const year = parseInt(dateComponents[2]);

      for (const [name, time] of Object.entries(timings)) {
        // Remove timezone abbreviation if present (e.g., "05:42 (EST)")
        const cleanTime = time.split(" ")[0];
        const [hours, minutes] = cleanTime.split(":").map(Number);

        // CRITICAL FIX: API returns times in user's LOCAL timezone
        // We need to convert local time TO UTC for storage
        // Example: 11:54 EST = 11:54 + 5 hours = 16:54 UTC
        const utcOffsetMinutes = getTimezoneOffset(timezone);

        // Create date in UTC by ADDING the offset to local time
        // (converting from local timezone to UTC)
        const prayerDate = new Date(
            Date.UTC(year, month, day, hours, minutes),
        );
        const utcDate = new Date(
            prayerDate.getTime() + utcOffsetMinutes * 60000,
        );

        prayerTimes[name] = utcDate.toISOString();
      }

      return prayerTimes;
    }
  } catch (error) {
    console.error("Error fetching prayer times:", error);
  }
  return null;
}

/**
 * Get approximate UTC offset for common timezones
 * @param {string} timezone - IANA timezone identifier
 * @return {number} Offset in minutes from UTC
 */
function getTimezoneOffset(timezone) {
  // Common US timezones and their UTC offsets (in minutes)
  // Note: These are standard time offsets (not accounting for DST)
  const timezoneOffsets = {
    "America/New_York": -300, // EST: UTC-5
    "America/Chicago": -360, // CST: UTC-6
    "America/Denver": -420, // MST: UTC-7
    "America/Los_Angeles": -480, // PST: UTC-8
    "America/Phoenix": -420, // MST (no DST): UTC-7
    "America/Toronto": -300, // EST: UTC-5
    // Add more as needed
  };

  // Use Intl API for accurate dynamic timezone offset calculation
  try {
    const now = new Date();
    // Get the UTC offset in minutes for the given timezone
    // This uses the Intl API which properly handles DST
    const formatter = new Intl.DateTimeFormat("en-US", {
      timeZone: timezone,
      timeZoneName: "shortOffset",
    });
    const parts = formatter.formatToParts(now);
    const offsetPart = parts.find((part) => part.type === "timeZoneName");

    if (offsetPart && offsetPart.value) {
      // Parse offset like "GMT-5" or "GMT+5:30"
      const match = offsetPart.value.match(/GMT([+-])(\d+)(?::(\d+))?/);
      if (match) {
        const sign = match[1] === "+" ? 1 : -1;
        const hours = parseInt(match[2], 10);
        const minutes = match[3] ? parseInt(match[3], 10) : 0;
        const offset = sign * (hours * 60 + minutes);
        console.log(`  Timezone offset for ${timezone}: ${offset} minutes`);
        return offset;
      }
    }

    // Fallback to static offsets if parsing fails
    console.log(`  Using fallback offset for ${timezone}`);
    return timezoneOffsets[timezone] || 0;
  } catch (error) {
    console.log(`  Using fallback offset for ${timezone}`);
    return timezoneOffsets[timezone] || 0;
  }
}

/**
 * Send push-to-start Live Activity using native HTTP/2
 * @param {string} deviceToken - The device push token
 * @param {string} prayerName - The name of the prayer
 * @param {Date} prayerTime - The prayer time as Date object
 * @param {string} icon - The icon name for the prayer
 * @return {Promise} The result of the push notification
 */
async function sendPushToStartLiveActivity(
    deviceToken, prayerName, prayerTime, icon) {
  return new Promise((resolve, reject) => {
    const apnsToken = generateAPNsToken();

    const now = new Date();
    const targetTimeUnix = Math.floor(prayerTime.getTime() / 1000);
    const remainingSeconds = Math.floor((prayerTime - now) / 1000);

    // DEBUG: Log exact times being sent
    console.log(`📤 PAYLOAD DEBUG:`);
    console.log(
        `   Current time: ${now.toISOString()} ` +
        `(${now.toLocaleString("en-US", {timeZone: "America/New_York"})} EST)`,
    );
    const prayerTimeEST = prayerTime.toLocaleString(
        "en-US", {timeZone: "America/New_York"},
    );
    console.log(
        `   Prayer time: ${prayerTime.toISOString()} (${prayerTimeEST} EST)`,
    );
    console.log(`   targetTime (Unix): ${targetTimeUnix}`);
    console.log(
        `   remainingSeconds: ${remainingSeconds} ` +
        `(${Math.floor(remainingSeconds / 60)} minutes)`,
    );
    const targetAsDate = new Date(targetTimeUnix * 1000).toISOString();
    console.log(`   targetTime as Date: ${targetAsDate}`);

    // Live Activity payload - CORRECT FORMAT FOR PUSH-TO-START
    // attributes-type and attributes MUST be outside aps object!
    const payload = {
      "aps": {
        "timestamp": Math.floor(Date.now() / 1000),
        "event": "start",
        "sound": "default", // Play default notification sound when LA starts
        "content-state": {
          "prayerName": prayerName,
          "targetTime": targetTimeUnix,
          "remainingSeconds": remainingSeconds,
          "showTimer": true,
          "message": null,
        },
      },
      "attributes-type": "PrayerCountdownAttributes",
      "attributes": {
        "prayerIcon": icon,
        "colorTheme": getColorTheme(prayerName),
        "formattedPrayerTime": formatTime(prayerTime.toISOString()),
        "isExpirationWarning": false,
      },
    };

    console.log(`📤 Full payload: ${JSON.stringify(payload, null, 2)}`);

    const payloadString = JSON.stringify(payload);

    // Create HTTP/2 client
    const client = http2.connect(`https://${APNS_HOST}`);

    client.on("error", (err) => {
      console.error("HTTP/2 connection error:", err);
      reject(err);
    });

    const req = client.request({
      ":method": "POST",
      ":path": `/3/device/${deviceToken}`,
      "authorization": `bearer ${apnsToken}`,
      "apns-topic": `${BUNDLE_ID}.push-type.liveactivity`,
      "apns-push-type": "liveactivity",
      "apns-priority": "10",
      "content-type": "application/json",
      "content-length": Buffer.byteLength(payloadString),
    });

    let responseData = "";

    req.on("response", (headers) => {
      const status = headers[":status"];
      console.log(`APNs response status: ${status}`);

      if (status === 200) {
        console.log("Push-to-start sent successfully");
      } else {
        console.error(`APNs error status: ${status}`);
      }
    });

    req.on("data", (chunk) => {
      responseData += chunk;
    });

    req.on("end", () => {
      client.close();

      if (responseData) {
        try {
          const response = JSON.parse(responseData);
          console.log("APNs response:", response);
          if (response.reason) {
            reject(new Error(`APNs error: ${response.reason}`));
          } else {
            resolve(response);
          }
        } catch (e) {
          resolve({status: "sent", data: responseData});
        }
      } else {
        resolve({status: "sent"});
      }
    });

    req.on("error", (err) => {
      console.error("Request error:", err);
      client.close();
      reject(err);
    });

    req.write(payloadString);
    req.end();
  });
}

/**
 * Get the icon name for a prayer
 * @param {string} prayerName - The name of the prayer
 * @return {string} The icon name
 */
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

/**
 * Get the color theme for a prayer
 * @param {string} prayerName - The name of the prayer
 * @return {string} The color theme name
 */
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

/**
 * Format an ISO time string to a readable time
 * @param {string} isoString - The ISO formatted time string
 * @return {string} The formatted time string
 */
function formatTime(isoString) {
  const date = new Date(isoString);
  return date.toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  });
}

// HTTP endpoint to manually test push-to-start (for debugging)
exports.testPushToStart = onRequest(
    {
      timeoutSeconds: 60,
      memory: "256MiB",
    },
    async (req, res) => {
      const userId = req.query.userId;

      if (!userId) {
        res.status(400).json({error: "userId query parameter required"});
        return;
      }

      console.log(`Testing push-to-start for user: ${userId}`);

      try {
        const userDoc = await db.collection("users").doc(userId).get();

        if (!userDoc.exists) {
          res.status(404).json({error: "User not found"});
          return;
        }

        const userData = userDoc.data();
        console.log("User data:", JSON.stringify(userData, null, 2));

        if (!userData.pushToStartToken) {
          res.status(400).json({error: "User has no push-to-start token"});
          return;
        }

        // Send test Live Activity for Maghrib in 30 minutes
        const testPrayerTime = new Date(Date.now() + 30 * 60000);
        const result = await sendPushToStartLiveActivity(
            userData.pushToStartToken,
            "Maghrib",
            testPrayerTime,
            "moon.fill",
        );

        res.json({
          success: true,
          message: "Test push-to-start sent",
          tokenUsed: userData.pushToStartToken.substring(0, 20) + "...",
          result: result,
        });
      } catch (error) {
        console.error("Test push-to-start error:", error);
        res.status(500).json({error: error.message});
      }
    },
);

// HTTP endpoint to check Firestore data structure
exports.checkUserData = onRequest(
    async (req, res) => {
      const userId = req.query.userId;

      if (!userId) {
        res.status(400).json({error: "userId query parameter required"});
        return;
      }

      try {
        const userDoc = await db.collection("users").doc(userId).get();

        if (!userDoc.exists) {
          res.status(404).json({error: "User not found"});
          return;
        }

        const userData = userDoc.data();

        res.json({
          userId: userId,
          hasPushToken: !!userData.pushToStartToken,
          tokenLength: userData.pushToStartToken ?
            userData.pushToStartToken.length : 0,
          hasLocation: !!(userData.location &&
            userData.location.latitude &&
            userData.location.longitude),
          location: userData.location || {},
          preferences: userData.preferences || {},
          lastUpdated: userData.lastUpdated || "N/A",
        });
      } catch (error) {
        res.status(500).json({error: error.message});
      }
    },
);
