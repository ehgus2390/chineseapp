import {onSchedule} from "firebase-functions/v2/scheduler";
import {onDocumentCreated, onDocumentWritten} from "firebase-functions/v2/firestore";
import {initializeApp} from "firebase-admin/app";
import {FieldValue, FieldPath, getFirestore, Timestamp} from "firebase-admin/firestore";
import type {
  DocumentData,
  DocumentReference,
  GeoPoint,
  QueryDocumentSnapshot,
  Transaction,
} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

// B-step hardening: region/memory/timeout to control cost and latency.
export const expireMatchSessions = onSchedule(
  {
    schedule: "every 1 minutes",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async () => {
    // Only expire pending matches; queue docs are handled separately.
    const statuses = ["pending"] as const;
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
      const requeueIds = new Set<string>();
      for (const doc of snapshot.docs) {
        const data = doc.data() ?? {};
        const userA = (data.userA ?? "").toString();
        const userB = (data.userB ?? "").toString();
        batch.set(
          doc.ref,
          {
            status: "expired",
            updatedAt: FieldValue.serverTimestamp(),
          },
          {merge: true}
        );
        if (userA) requeueIds.add(userA);
        if (userB) requeueIds.add(userB);
      }
      await batch.commit();
      await Promise.all([...requeueIds].map((uid) => requeueUser(uid)));
    }
  }
);

export const onMatchSessionAccepted = onDocumentWritten(
  "match_sessions/{sessionId}",
  async (event) => {
    const beforeSnap = event.data?.before;
    const afterSnap = event.data?.after;
    if (!afterSnap || !afterSnap.exists) return;
    // Extract once to avoid redeclaration bugs.
    const beforeData = beforeSnap?.data() ?? {};
    const afterData = afterSnap.data() ?? {};
    const beforeStatus = beforeData.status?.toString();
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

    const userA = (afterData.userA ?? "").toString();
    const userB = (afterData.userB ?? "").toString();
    if (userA && userB) {
      await db
        .collection("users")
        .doc(userA)
        .collection("notifications")
        .add({
          type: "chat",
          fromUid: userB,
          refId: sessionId,
          seen: false,
          createdAt: FieldValue.serverTimestamp(),
        });
      await db
        .collection("users")
        .doc(userB)
        .collection("notifications")
        .add({
          type: "chat",
          fromUid: userA,
          refId: sessionId,
          seen: false,
          createdAt: FieldValue.serverTimestamp(),
        });
    }
  }
);

export const onAutoMatchSessionSearching = onDocumentWritten(
  {
    document: "match_sessions/{sessionId}",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (event) => {
    const beforeSnap = event.data?.before;
    const afterSnap = event.data?.after;
    if (!afterSnap || !afterSnap.exists) return;
    // Extract once to avoid redeclaration bugs.
    const beforeData = beforeSnap?.data() ?? {};
    const afterData = afterSnap.data() ?? {};

    const sessionId = event.params.sessionId as string;
    if (!sessionId.startsWith("queue_")) {
      console.log("auto-match skip: not queue doc", {sessionId});
      return;
    }

    const afterStatus = afterData.status?.toString();
    const beforeStatus = beforeData.status?.toString();
    const mode = afterData.mode?.toString();

    console.log("auto-match entry", {
      sessionId,
      mode,
      beforeStatus,
      afterStatus,
    });

    // Only react to auto queue sessions transitioning into searching.
    // If pairing never creates a pending {uidA}_{uidB} doc, the UI never sees match found.
    if (mode !== "auto") {
      console.log("auto-match skip: mode not auto", {sessionId, mode});
      return;
    }
    if (afterStatus !== "searching") {
      console.log("auto-match skip: status not searching", {
        sessionId,
        afterStatus,
      });
      return;
    }
    if (beforeStatus === "searching") {
      console.log("auto-match skip: already searching", {sessionId});
      return;
    }

    const userA = (afterData.userA ?? "").toString();
    if (!userA) {
      console.log("auto-match skip: missing userA", {sessionId});
      return;
    }

    console.log("auto-match attempt start", {userA});

    const candidates = await db
      .collection("match_sessions")
      .where("mode", "==", "auto")
      .where("status", "==", "searching")
      .limit(20)
      .get();

    let matched = false;
    for (const doc of candidates.docs) {
      if (doc.id === afterSnap.id) continue;
      if (!doc.id.startsWith("queue_")) continue;
      if (matched) break;
      matched = await tryPairQueues(afterSnap.ref, doc.ref, userA);
    }

    if (!matched) {
      console.log("auto-match: no eligible partner");
    } else {
      console.log("auto-match: paired successfully", {userA});
    }
  },
);

export const cleanupQueueDocs = onSchedule(
  {
    schedule: "every 1 minutes",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async () => {
    const prefixStart = "queue_";
    const prefixEnd = "queue_~";

    let lastDoc: QueryDocumentSnapshot<DocumentData> | null = null;
    while (true) {
      let query = db
        .collection("match_sessions")
        .orderBy(FieldPath.documentId())
        .where(FieldPath.documentId(), ">=", prefixStart)
        .where(FieldPath.documentId(), "<", prefixEnd)
        .limit(200);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();

      if (snapshot.empty) break;

      const batch = db.batch();
      for (const doc of snapshot.docs) {
        const data = doc.data() ?? {};
        const updates: Record<string, unknown> = {};

        if ("userB" in data) updates.userB = FieldValue.delete();
        if ("participants" in data) updates.participants = FieldValue.delete();
        if ("ready" in data) updates.ready = FieldValue.delete();
        if ("cancelledBy" in data) updates.cancelledBy = FieldValue.delete();
        if ("connectedAt" in data) updates.connectedAt = FieldValue.delete();

        if (Object.keys(updates).length > 0) {
          batch.set(doc.ref, updates, {merge: true});
        }
      }

      await batch.commit();
      lastDoc = snapshot.docs[snapshot.docs.length - 1];
    }
  },
);

async function tryPairQueues(
  queueARef: DocumentReference<DocumentData>,
  queueBRef: DocumentReference<DocumentData>,
  initiatedBy: string,
): Promise<boolean> {
  const expiresAt = Timestamp.fromMillis(Date.now() + 10 * 1000);
  let paired = false;

  await db.runTransaction(async (tx) => {
    const [queueASnap, queueBSnap] = await Promise.all([
      tx.get(queueARef),
      tx.get(queueBRef),
    ]);
    if (!queueASnap.exists || !queueBSnap.exists) return;

    const queueAData = queueASnap.data() ?? {};
    const queueBData = queueBSnap.data() ?? {};
    if (queueAData.status?.toString() !== "searching") return;
    if (queueBData.status?.toString() !== "searching") return;
    if (queueAData.mode?.toString() !== "auto") return;
    if (queueBData.mode?.toString() !== "auto") return;
    if (!queueASnap.id.startsWith("queue_")) return;
    if (!queueBSnap.id.startsWith("queue_")) return;

    const userA = (queueAData.userA ?? "").toString();
    const userB = (queueBData.userA ?? "").toString();
    if (!userA || !userB || userA === userB) return;

    // Avoid false positives if legacy queue docs stored non-string userB.
    const queueAUserB =
      typeof queueAData.userB === "string" ? queueAData.userB : "";
    const queueBUserB =
      typeof queueBData.userB === "string" ? queueBData.userB : "";
    if (queueAUserB.trim().length > 0 || queueBUserB.trim().length > 0) return;

    const hydratedA = await hydrateQueueUser(tx, userA, queueAData);
    const hydratedB = await hydrateQueueUser(tx, userB, queueBData);
    if (!hydratedA || !hydratedB) return;

    if (!hasCommonInterest(hydratedA.interests, hydratedB.interests)) return;
    const distanceKm = distanceBetweenKm(hydratedA.location, hydratedB.location);
    if (distanceKm == null) return;
    const maxDistance = Math.min(hydratedA.radiusKm, hydratedB.radiusKm);
    if (distanceKm > maxDistance) return;

    const ids = [userA, userB].sort();
    const pairSessionId = `${ids[0]}_${ids[1]}`;
    const pairRef = db.collection("match_sessions").doc(pairSessionId);
    const pairSnap = await tx.get(pairRef);
    if (pairSnap.exists) return;

    const notifARef = db
      .collection("users")
      .doc(ids[0])
      .collection("notifications")
      .doc();
    const notifBRef = db
      .collection("users")
      .doc(ids[1])
      .collection("notifications")
      .doc();

    tx.set(pairRef, {
      userA: ids[0],
      userB: ids[1],
      mode: "auto",
      status: "pending",
      initiatedBy,
      chatRoomId: null,
      createdAt: FieldValue.serverTimestamp(),
      respondedAt: null,
      expiresAt,
      updatedAt: FieldValue.serverTimestamp(),
    });

    tx.set(notifARef, {
      type: "match",
      fromUid: ids[1],
      refId: pairSessionId,
      seen: false,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.set(notifBRef, {
      type: "match",
      fromUid: ids[0],
      refId: pairSessionId,
      seen: false,
      createdAt: FieldValue.serverTimestamp(),
    });

    tx.set(
      queueARef,
      {status: "expired", updatedAt: FieldValue.serverTimestamp()},
      {merge: true},
    );
    tx.set(
      queueBRef,
      {status: "expired", updatedAt: FieldValue.serverTimestamp()},
      {merge: true},
    );
    paired = true;
  });

  return paired;
}

export const onMatchSessionRejectedOrExpired = onDocumentWritten(
  {
    document: "match_sessions/{sessionId}",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (event) => {
    const beforeSnap = event.data?.before;
    const afterSnap = event.data?.after;
    if (!afterSnap || !afterSnap.exists) return;
    // Extract once to avoid redeclaration bugs.
    const beforeData = beforeSnap?.data() ?? {};
    const afterData = afterSnap.data() ?? {};

    const sessionId = event.params.sessionId as string;
    if (sessionId.startsWith("queue_")) return;

    const afterStatus = afterData.status?.toString();
    const beforeStatus = beforeData.status?.toString();
    if (afterStatus !== "expired" && afterStatus !== "rejected") return;
    if (beforeStatus === afterStatus) return;

    const userA = (afterData.userA ?? "").toString();
    const userB = (afterData.userB ?? "").toString();
    await requeueUser(userA);
    await requeueUser(userB);
  },
);

async function hydrateQueueUser(
  tx: Transaction,
  userId: string,
  queueData: DocumentData,
): Promise<{
  interests: string[];
  location: GeoPoint;
  radiusKm: number;
} | null> {
  let interests = (queueData.interests ?? []) as unknown[];
  let location = queueData.location as GeoPoint | undefined;
  let radiusKm = Number(queueData.radiusKm);

  if (
    !Array.isArray(interests) ||
    interests.length === 0 ||
    !location ||
    !Number.isFinite(radiusKm) ||
    radiusKm <= 0
  ) {
    const userSnap = await tx.get(db.collection("users").doc(userId));
    const userData = userSnap.data() ?? {};
    interests = (userData.interests ?? []) as unknown[];
    location = userData.location as GeoPoint | undefined;
    const fallbackRadius = Number(userData.distanceKm);
    radiusKm = Number.isFinite(fallbackRadius) && fallbackRadius > 0
      ? fallbackRadius
      : radiusKm;

    const normalizedInterests = normalizeInterests(interests);
    if (
      normalizedInterests.length > 0 &&
      location &&
      Number.isFinite(radiusKm) &&
      radiusKm > 0
    ) {
      tx.set(
        db.collection("match_sessions").doc(`queue_${userId}`),
        {
          interests: normalizedInterests,
          location,
          radiusKm,
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    }
  }

  const normalizedInterests = normalizeInterests(interests);
  if (
    normalizedInterests.length === 0 ||
    !location ||
    !Number.isFinite(radiusKm) ||
    radiusKm <= 0
  ) {
    return null;
  }

  return {
    interests: normalizedInterests,
    location,
    radiusKm,
  };
}

function hasCommonInterest(a: string[], b: string[]): boolean {
  if (a.length === 0 || b.length === 0) return false;
  const set = new Set(a);
  return b.some((interest) => set.has(interest));
}

function distanceBetweenKm(
  a: GeoPoint,
  b: GeoPoint,
): number | null {
  if (!a || !b) return null;
  const toRad = (value: number) => (value * Math.PI) / 180;
  const radius = 6371;
  const dLat = toRad(b.latitude - a.latitude);
  const dLon = toRad(b.longitude - a.longitude);
  const lat1 = toRad(a.latitude);
  const lat2 = toRad(b.latitude);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
  return radius * 2 * Math.asin(Math.sqrt(h));
}

function normalizeInterests(input: unknown[]): string[] {
  return input
    .map((item) => (typeof item === "string" ? item : item?.toString()))
    .filter((value): value is string => typeof value === "string" && value.length > 0);
}

async function requeueUser(userId: string): Promise<void> {
  if (!userId) return;
  const userSnap = await db.collection("users").doc(userId).get();
  const userData = userSnap.data() ?? {};
  const interests = normalizeInterests(
    (userData.interests ?? []) as unknown[],
  );
  const location = userData.location as GeoPoint | undefined;
  const radiusKm = Number(userData.distanceKm);
  if (!location || interests.length === 0 || !Number.isFinite(radiusKm) || radiusKm <= 0) {
    return;
  }
  await db.collection("match_sessions").doc(`queue_${userId}`).set(
    {
      userA: userId,
      interests,
      location,
      radiusKm,
      mode: "auto",
      status: "searching",
      createdAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromMillis(Date.now() + 5 * 60 * 1000),
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
}

export const onMatchSessionAcceptedNotification = onDocumentWritten(
  {
    document: "match_sessions/{sessionId}",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (event) => {
    const beforeSnap = event.data?.before;
    const afterSnap = event.data?.after;
    if (!afterSnap || !afterSnap.exists) return;
    // Extract once to avoid redeclaration bugs.
    const beforeData = beforeSnap?.data() ?? {};
    const afterData = afterSnap.data() ?? {};
    const beforeStatus = beforeData.status?.toString();
    const afterStatus = afterData.status?.toString();
    if (beforeStatus === "accepted" || afterStatus !== "accepted") return;

    const sessionId = event.params.sessionId as string;
    const chatRoomId = afterData.chatRoomId?.toString() || sessionId;

    // Idempotency: mark notified.accepted once to prevent duplicates.
    const shouldSend = await markMatchAcceptedNotified(sessionId);
    if (!shouldSend) return;

    const recipients = getParticipants(afterData);
    const records = await resolveDeviceTokens(recipients);
    if (records.length === 0) return;

    await sendMulticast(records, {
      notification: {
        title: "💞 매칭이 완료됐어요",
        body: "지금 대화를 시작해보세요",
      },
      data: {        type: "match_accepted",
        sessionId,
        chatRoomId,
      },
    });
  }
);

export const onChatMessageCreatedNotification = onDocumentCreated(
  {
    document: "chat_rooms/{roomId}/messages/{messageId}",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (event) => {
    const messageSnap = event.data;
    if (!messageSnap?.exists) return;
    const roomId = event.params.roomId as string;
    const messageId = event.params.messageId as string;
    const messageData = messageSnap.data() ?? {};

    if (messageData.notified === true) return;

    // Idempotency: mark notified once per message before sending.
    const shouldSend = await markMessageNotified(roomId, messageId);
    if (!shouldSend) return;

    const senderId = (messageData.senderId ?? "").toString();
    if (!senderId) return;

    const roomSnap = await db.collection("chat_rooms").doc(roomId).get();
    const roomData = roomSnap.data() ?? {};
    const participants = (roomData.participants ?? []) as unknown[];
    const recipients = participants
      .map((id) => id?.toString())
      .filter((id) => id && id !== senderId) as string[];
    if (recipients.length === 0) return;

    const records = await resolveDeviceTokens(recipients);
    if (records.length === 0) return;

    await sendMulticast(records, {
      notification: {
        title: "💬 새 메시지",
        body: "메시지가 도착했어요",
      },
      data: {        type: "new_message",
        roomId,
        messageId,
        senderId,
      },
    });
  }
);

async function markMatchAcceptedNotified(sessionId: string): Promise<boolean> {
  const sessionRef = db.collection("match_sessions").doc(sessionId);
  let shouldSend = false;
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(sessionRef);
    if (!snap.exists) return;
    const data = snap.data() ?? {};
    const notified = (data.notified ?? {}) as Record<string, unknown>;
    if (notified.accepted === true) return;
    tx.set(
      sessionRef,
      {
        notified: {
          ...notified,
          accepted: true,
          acceptedAt: FieldValue.serverTimestamp(),
        },
      },
      {merge: true}
    );
    shouldSend = true;
  });
  return shouldSend;
}

async function markMessageNotified(
  roomId: string,
  messageId: string,
): Promise<boolean> {
  const messageRef = db
    .collection("chat_rooms")
    .doc(roomId)
    .collection("messages")
    .doc(messageId);
  let shouldSend = false;
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(messageRef);
    if (!snap.exists) return;
    const data = snap.data() ?? {};
    if (data.notified === true) return;
    tx.set(
      messageRef,
      {
        notified: true,
        notifiedAt: FieldValue.serverTimestamp(),
      },
      {merge: true}
    );
    shouldSend = true;
  });
  return shouldSend;
}

function getParticipants(data: Record<string, unknown>): string[] {
  const userA = (data.userA ?? "").toString();
  const userB = (data.userB ?? "").toString();
  return [userA, userB].filter((id) => id.trim().length > 0);
}

type TokenRecord = {
  token: string;
  deviceRef: DocumentReference;
};

async function resolveDeviceTokens(userIds: string[]): Promise<TokenRecord[]> {
  const tokenSets = await Promise.all(
    userIds.map(async (uid) => {
      const userSnap = await db.collection("users").doc(uid).get();
      const userData = userSnap.data() ?? {};
      if (userData.notificationsEnabled === false) return [] as TokenRecord[];

      const devicesSnap = await db
        .collection("users")
        .doc(uid)
        .collection("devices")
        .where("enabled", "==", true)
        .get();
      return devicesSnap.docs
        .map((doc) => {
          const data = doc.data() ?? {};
          const token = data.token?.toString() ?? "";
          if (!token) return null;
          return {token, deviceRef: doc.ref} as TokenRecord;
        })
        .filter((record): record is TokenRecord => record !== null);
    })
  );
  return tokenSets.flat();
}

async function sendMulticast(
  records: TokenRecord[],
  message: {
    notification: {title: string; body: string};
    data: Record<string, string>;
  },
): Promise<void> {
  const tokens = records.map((r) => r.token);
  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: message.notification,
    data: message.data,
  });

  const invalidRefs: DocumentReference[] = [];
  response.responses.forEach((res, index) => {
    if (res.success) return;
    const code = res.error?.code ?? "";
    if (
      code === "messaging/invalid-registration-token" ||
      code === "messaging/registration-token-not-registered"
    ) {
      invalidRefs.push(records[index].deviceRef);
    }
  });

  if (invalidRefs.length > 0) {
    const batch = db.batch();
    for (const ref of invalidRefs) {
      batch.set(ref, {enabled: false, updatedAt: FieldValue.serverTimestamp()}, {merge: true});
    }
    await batch.commit();
  }
}
