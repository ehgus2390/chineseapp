import {onSchedule} from "firebase-functions/v2/scheduler";
import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore, Timestamp} from "firebase-admin/firestore";

initializeApp();
const db = getFirestore();

// B-step hardening: region/memory/timeout to control cost and latency.
export const expireMatchSessions = onSchedule(
  {
    schedule: "every 1 minutes",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async () => {
    // Expire both pending/searching auto sessions to avoid idle buildup.
    const statuses = ["pending", "searching"] as const;
    const now = Timestamp.now();

    // Batch + loop avoids unbounded reads and keeps costs predictable.
    while (true) {
      const snapshot = await db
        .collection("match_sessions")
        .where("mode", "==", "auto")
        .where("status", "in", statuses as unknown as string[])
        .where("expiresAt", "<=", now)
        .orderBy("expiresAt")
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
            status: "expired",
            updatedAt: FieldValue.serverTimestamp(),
          },
          {merge: true}
        );
      }
      await batch.commit();
    }
  }
);

export const onMatchSessionAccepted = onDocumentWritten(
  "match_sessions/{sessionId}",
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    if (!after || !after.exists) return;

    const beforeStatus = before?.data()?.status?.toString();
    const afterData = after.data() ?? {};
    const afterStatus = afterData.status?.toString();
    if (beforeStatus === "accepted" || afterStatus !== "accepted") return;

    const sessionId = event.params.sessionId as string;
    const sessionRef = db.collection("match_sessions").doc(sessionId);
    const roomRef = db.collection("chat_rooms").doc(sessionId);

    await db.runTransaction(async (tx) => {
      const sessionSnap = await tx.get(sessionRef);
      if (!sessionSnap.exists) return;
      const data = sessionSnap.data() ?? {};
      if (data.status?.toString() !== "accepted") return;
      if (data.chatRoomId != null) return;

      const userA = (data.userA ?? "").toString();
      const userB = (data.userB ?? "").toString();
      const participants = [userA, userB].filter((id) => id.trim().length > 0);
      if (participants.length < 2) return;
      const mode = data.mode?.toString() ?? null;

      const roomSnap = await tx.get(roomRef);
      if (!roomSnap.exists) {
        tx.set(
          roomRef,
          {
            participants,
            sessionId,
            mode,
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
            lastMessage: null,
            lastMessageAt: null,
            isActive: true,
          },
          {merge: true}
        );
      }
      // Idempotent: always link the session to the room if accepted.
      tx.set(
        sessionRef,
        {
          chatRoomId: sessionId,
          respondedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true}
      );
    });
  }
);
