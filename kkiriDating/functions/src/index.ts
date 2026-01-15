// Firebase Functions: scheduled maintenance for match session expiry.
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore, Timestamp } from 'firebase-admin/firestore';

initializeApp();
const db = getFirestore();

export const expireMatchSessions = onSchedule('every 1 minutes', async () => {
  const statuses = ['searching', 'consent', 'waiting'] as const;
  const now = Timestamp.now();

  // Process in chunks to keep batch sizes safe.
  while (true) {
    const snapshot = await db
      .collection('match_sessions')
      .where('mode', '==', 'auto')
      .where('status', 'in', statuses as unknown as string[])
      .where('expiresAt', '<=', now)
      .orderBy('expiresAt')
      .limit(200)
      .get();

    if (snapshot.empty) {
      break;
    }

    const batch = db.batch();
    for (const doc of snapshot.docs) {
      batch.set(
        doc.ref,
        {
          status: 'cancelled',
          cancelledBy: 'system',
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }
    await batch.commit();
  }
});
