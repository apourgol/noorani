const admin = require('firebase-admin');
const serviceAccount = require('./functions/service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function updateOffset() {
  const userId = '124AEBF9-27B7-41F0-B648-8E93CFEC99D9';
  
  // Current time: ~10:27 AM EST
  // Dhuhr at: 11:54 AM EST (in ~87 minutes)
  // To trigger in next run, set offset to: 87 - 2 = 85 minutes
  
  await db.collection('users').doc(userId).update({
    'preferences.liveActivityStartOffset': 85
  });
  
  console.log('✅ Updated offset to 85 minutes for user 124AEBF9...');
  console.log('⏰ Dhuhr at 11:54 AM - 85 min = trigger at ~10:29 AM');
  console.log('📱 Next function run (~10:29) will send the Live Activity!');
  console.log('🎯 New window: -1 to +3 minutes (was 0 to 1)');
  
  process.exit(0);
}

updateOffset().catch(console.error);
