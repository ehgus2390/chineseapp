"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.expireMatchSessions = void 0;
// Firebase Functions: scheduled maintenance for match   expiry.
const scheduler_1 = require("firebase-functions/v2/scheduler");
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
(0, app_1.initializeApp)();
const db = (0, firestore_1.getFirestore)();
exports.expireMatchSessions = (0, scheduler_1.onSchedule)('every 1 minutes', async () => {
    const statuses = ['searching', 'consent', 'waiting'];
    const now = firestore_1.Timestamp.now();
    // Process in chunks to keep batch sizes safe.
    while (true) {
        const snapshot = await db
            .collection('match_sessions')
            .where('mode', '==', 'auto')
            .where('status', 'in', statuses)
            .where('expiresAt', '<=', now)
            .orderBy('expiresAt')
            .limit(200)
            .get();
        if (snapshot.empty) {
            break;
        }
        const batch = db.batch();
        for (const doc of snapshot.docs) {
            batch.set(doc.ref, {
                status: 'cancelled',
                cancelledBy: 'system',
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
            }, { merge: true });
        }
        await batch.commit();
    }
});
//# sourceMappingURL=index.js.map