const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.cleanUpPendingUsers = functions.https.onRequest(async (req, res) => {
    try {
        const currentTime = Date.now();
        const cutoffTime = currentTime - 2 * 60 * 1000; // 2 minutes ago
        
        const snapshot = await admin.firestore().collection('pending_users').get();
        
        let deleteCount = 0;
        
        snapshot.forEach(async (doc) => {
            const userData = doc.data();
            const registrationTime = userData.registrationTime.toMillis(); // Assuming registrationTime is a Firestore Timestamp
            
            if (registrationTime < cutoffTime) {
                await admin.firestore().collection('pending_users').doc(doc.id).delete();
                deleteCount++;
            }
        });
        
        res.status(200).send(`Deleted ${deleteCount} old pending users.`);
    } catch (error) {
        console.error("Error cleaning up pending users:", error);
        res.status(500).send("Internal Server Error");
    }
});
