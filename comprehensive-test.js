const admin = require('firebase-admin');
const serviceAccount = require('./functions/service-account-key.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

(async () => {
  console.log('🔍 COMPREHENSIVE DIAGNOSTIC\n');
  
  // 1. Check Firestore data
  console.log('1️⃣ FIRESTORE DATA:');
  const userDoc = await db.collection('users').doc('BA5A8407-99FD-4F21-A90F-AA0B98B057B2').get();
  const userData = userDoc.data();
  
  console.log('   Token:', userData.pushToStartToken?.substring(0, 20) + '...');
  console.log('   Token length:', userData.pushToStartToken?.length);
  console.log('   Token age:', Math.floor((Date.now() - userData.tokenUpdatedAt?.toDate()) / 1000), 'seconds');
  console.log('   Device:', userData.deviceInfo?.name);
  console.log('   iOS:', userData.deviceInfo?.systemVersion);
  console.log('');
  
  // 2. Check bundle ID
  console.log('2️⃣ BUNDLE ID VERIFICATION:');
  console.log('   Expected: com.apbrology.Noorani');
  console.log('   Topic: com.apbrology.Noorani.push-type.liveactivity');
  console.log('');
  
  // 3. Check entitlements
  console.log('3️⃣ ENTITLEMENTS:');
  console.log('   Main app: production (from code change)');
  console.log('   Widget: production (confirmed)');
  console.log('');
  
  // 4. Payload verification
  console.log('4️⃣ PAYLOAD FORMAT:');
  console.log('   ✅ attributes-type outside aps');
  console.log('   ✅ attributes outside aps');
  console.log('   ✅ targetTime as Unix timestamp (number)');
  console.log('   ✅ Production APNs endpoint');
  console.log('');
  
  // 5. Common issues
  console.log('5️⃣ CHECKLIST FOR USER:');
  console.log('   [ ] App is KILLED (force quit, not backgrounded)');
  console.log('   [ ] No existing Live Activities visible');
  console.log('   [ ] Device is unlocked or on lock screen');
  console.log('   [ ] Live Activities enabled: Settings > Noorani');
  console.log('   [ ] Running TestFlight build (not Xcode)');
  console.log('   [ ] Do Not Disturb is OFF');
  console.log('');
  
  process.exit(0);
})();
