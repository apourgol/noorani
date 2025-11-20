const admin = require('firebase-admin');
const serviceAccount = require('./functions/service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkAndUpdate() {
  const userId = 'BA5A8407-99FD-4F21-A90F-AA0B98B057B2';
  
  console.log('📱 Checking current token status...\n');
  
  const userDoc = await db.collection('users').doc(userId).get();
  const userData = userDoc.data();
  
  console.log('Token length:', userData.pushToStartToken?.length || 'none');
  console.log('Token updated:', userData.tokenUpdatedAt?.toDate()?.toISOString() || 'never');
  console.log('Device:', userData.deviceInfo?.name || 'unknown');
  
  console.log('\n💡 After regenerating token (kill app, reopen from TestFlight):');
  console.log('   1. Wait 10 seconds');
  console.log('   2. Run this script again to verify new token timestamp');
  console.log('   3. Then I\'ll trigger another test');
  
  process.exit(0);
}

checkAndUpdate().catch(console.error);
