import {onSchedule} from "firebase-functions/v2/scheduler";
import {onCall, HttpsError} from "firebase-functions/v2/https";
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
import {getAuth} from "firebase-admin/auth";
import {getStorage} from "firebase-admin/storage";

initializeApp();
const db = getFirestore();
const messaging = getMessaging();
const auth = getAuth();
const storage = getStorage();
const SERVER_WRITER = "server";
const LOCATION_EPS = 1e-6;
const MODERATION_LEVEL_ONE_THRESHOLD = 3;
const MODERATION_LEVEL_TWO_THRESHOLD = 6;
const MATCH_LIMIT_MINUTES = 10;

// Cleanup abandoned unverified email users.
const DRY_RUN = true; // Set to false to perform deletions.
const MAX_DELETIONS_PER_RUN = 200;
const EMAIL_VERIFY_AGE_HOURS = 48;

export const cleanupUnverifiedEmailUsers = onSchedule(
  {
    schedule: "every 6 hours",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async () => {
    const lockRef = db.collection("_ops").doc("cleanup_unverified_email_users");
    const now = Date.now();
    const lockAcquired = await db.runTransaction(async (tx) => {
      const snap = await tx.get(lockRef);
      const data = snap.data() ?? {};
      const lastRun = (data.lastRunAt as Timestamp | undefined)?.toMillis() ?? 0;
      // Prevent overlapping runs (6h schedule).
      if (now - lastRun < 5 * 60 * 60 * 1000) return false;
      tx.set(lockRef, {lastRunAt: FieldValue.serverTimestamp()}, {merge: true});
      return true;
    });
    if (!lockAcquired) {
      console.log("cleanupUnverifiedEmailUsers: skipped (lock)");
      return;
    }

    const thresholdMs = EMAIL_VERIFY_AGE_HOURS * 60 * 60 * 1000;
    let pageToken: string | undefined;
    let scanned = 0;
    let candidates = 0;
    let deleted = 0;
    let skipped = 0;

    while (true) {
      const result = await auth.listUsers(1000, pageToken);
      pageToken = result.pageToken;
      for (const user of result.users) {
        scanned += 1;
        if (deleted >= MAX_DELETIONS_PER_RUN) break;
        if (user.emailVerified) {
          skipped += 1;
          continue;
        }
        const providers = user.providerData.map((p) => p.providerId);
        if (!providers.includes("password")) {
          skipped += 1;
          continue;
        }
        const createdAtMs = Date.parse(user.metadata.creationTime);
        if (!Number.isFinite(createdAtMs) || now - createdAtMs < thresholdMs) {
          skipped += 1;
          continue;
        }

        const userDoc = await db.collection("users").doc(user.uid).get();
        const userData = userDoc.data() ?? {};
        if (userData.verifiedAt != null || userData.profileCompleted === true) {
          skipped += 1;
          continue;
        }

        candidates += 1;
        if (DRY_RUN) {
          console.log("DRY_RUN: delete candidate", {uid: user.uid});
          continue;
        }

        try {
          await auth.deleteUser(user.uid);
          deleted += 1;
        } catch (e) {
          console.log("cleanupUnverifiedEmailUsers: auth delete failed", {
            uid: user.uid,
            error: e,
          });
          continue;
        }

        // Best-effort Firestore + Storage cleanup.
        try {
          if (userDoc.exists) {
            await userDoc.ref.delete();
          }
        } catch (e) {
          console.log("cleanupUnverifiedEmailUsers: firestore delete failed", {
            uid: user.uid,
            error: e,
          });
        }
        try {
          await deleteStorageFolder(`users/${user.uid}/`);
        } catch (e) {
          console.log("cleanupUnverifiedEmailUsers: storage delete failed", {
            uid: user.uid,
            error: e,
          });
        }
      }

      if (!pageToken || deleted >= MAX_DELETIONS_PER_RUN) {
        break;
      }
    }

    console.log("cleanupUnverifiedEmailUsers: summary", {
      scanned,
      candidates,
      deleted,
      skipped,
      dryRun: DRY_RUN,
    });
  }
);

export const verifyProtectionPurchase = onCall(
  {
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (request) => {
    const authUid = request.auth?.uid;
    const isAdmin = request.auth?.token?.admin === true;
    const data = request.data ?? {};
    const uid = (data.uid ?? "").toString();
    const tier = (data.tier ?? "").toString();
    const orderId = (data.orderId ?? "").toString();
    const source = (data.source ?? "").toString();
    const expiresAtRaw = data.expiresAt;

    if (!uid || !orderId || !tier || !source) {
      throw new HttpsError("invalid-argument", "Missing required fields.");
    }
    if (!authUid || (!isAdmin && uid !== authUid)) {
      throw new HttpsError("permission-denied", "Not authorized.");
    }
    if (tier !== "basic" && tier !== "plus") {
      throw new HttpsError("invalid-argument", "Invalid tier.");
    }
    if (source !== "promo") {
      throw new HttpsError(
        "failed-precondition",
        "Verification not configured for this source.",
      );
    }

    const expiresAtMs = parseExpiryMillis(expiresAtRaw);
    if (!Number.isFinite(expiresAtMs)) {
      throw new HttpsError("invalid-argument", "Invalid expiresAt.");
    }
    const nowMs = Date.now();
    const isExpired = expiresAtMs <= nowMs;

    const entitlementRef = db.collection("user_entitlements").doc(uid);
    const opKey = `verifyProtectionPurchase:${orderId}`;

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(entitlementRef);
      const current = snap.data() ?? {};
      if (current.protection?.orderId === orderId) return;
      if (current.serverMeta?.lastOp === opKey) return;

      const startedAt =
        current.protection?.startedAt ?? FieldValue.serverTimestamp();
      const protection = {
        active: !isExpired,
        tier,
        startedAt,
        expiresAt: Timestamp.fromMillis(expiresAtMs),
        source,
        orderId,
        lastVerifiedAt: FieldValue.serverTimestamp(),
      };

      tx.set(
        entitlementRef,
        {
          protection,
          updatedAt: FieldValue.serverTimestamp(),
          serverMeta: {
            lastOp: opKey,
            lastWriter: SERVER_WRITER,
            updatedAt: FieldValue.serverTimestamp(),
            source: SERVER_WRITER,
          },
        },
        {merge: true},
      );
    });

    return {ok: true};
  },
);

export const adminUpdateModeration = onCall(
  {
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (request) => {
    const isAdmin = request.auth?.token?.admin === true;
    const adminUid = request.auth?.uid ?? "";
    if (!isAdmin) {
      throw new HttpsError("permission-denied", "Admin only.");
    }
    const data = request.data ?? {};
    const uid = (data.uid ?? "").toString();
    const reason = (data.reason ?? "").toString();
    const newLevelRaw = data.newLevel;
    const newLevel =
      typeof newLevelRaw === "number" ? Math.max(0, Math.min(2, newLevelRaw)) : null;
    if (!uid) {
      throw new HttpsError("invalid-argument", "Missing uid.");
    }

    const moderationUpdates = (data.moderation ?? {}) as Record<
      string,
      unknown
    >;
    const entUpdates = (data.entitlements ?? {}) as Record<string, unknown>;
    const protectionBan = (entUpdates.protectionBan ?? {}) as Record<
      string,
      unknown
    >;

    const moderationRef = db.collection("user_moderation").doc(uid);
    const entRef = db.collection("user_entitlements").doc(uid);
    const opKey = `adminUpdateModeration:${uid}:${Date.now()}`;

    await db.runTransaction(async (tx) => {
      const [modSnap, entSnap] = await Promise.all([
        tx.get(moderationRef),
        tx.get(entRef),
      ]);
      const currentMod = modSnap.data() ?? {};
      const currentEnt = entSnap.data() ?? {};

      const nextProtectionEligible =
        moderationUpdates.protectionEligible ?? currentMod.protectionEligible;
      const nextHardFlags = {
        ...(currentMod.hardFlags ?? {}),
        ...(moderationUpdates.hardFlags ?? {}),
      } as Record<string, boolean>;

      const currentBan =
        (currentEnt.protectionBan ?? {}) as Record<string, unknown>;
      const nextBanActive =
        protectionBan.active ?? currentBan.active ?? false;
      const nextBanReason =
        (protectionBan.reason ?? currentBan.reason ?? "").toString();
      const untilRaw = protectionBan.until ?? currentBan.until ?? null;
      const untilMs = parseExpiryMillis(untilRaw);
      const nextBanUntil = Number.isFinite(untilMs)
        ? Timestamp.fromMillis(untilMs)
        : null;

      const modChanged =
        (newLevel != null && Number(currentMod.level ?? 0) !== newLevel) ||
        nextProtectionEligible !== currentMod.protectionEligible ||
        JSON.stringify(nextHardFlags) !== JSON.stringify(currentMod.hardFlags);
      const banChanged =
        nextBanActive !== currentBan.active ||
        nextBanReason !== (currentBan.reason ?? "") ||
        JSON.stringify(nextBanUntil) !== JSON.stringify(currentBan.until ?? null);

      if (!modChanged && !banChanged) return;

      if (modChanged) {
        const nextLevel = newLevel ?? Number(currentMod.level ?? 0);
        tx.set(
          moderationRef,
          {
            level: nextLevel,
            protectionEligible: nextProtectionEligible ?? true,
            hardFlags: nextHardFlags,
            updatedAt: FieldValue.serverTimestamp(),
            serverMeta: {
              lastOp: opKey,
              lastWriter: SERVER_WRITER,
              updatedAt: FieldValue.serverTimestamp(),
              source: SERVER_WRITER,
            },
          },
          {merge: true},
        );

        const actionRef = db.collection("_ops").doc("admin_actions").collection("items").doc();
        tx.set(actionRef, {
          adminUid,
          targetUid: uid,
          actionType: "update_moderation",
          before: {
            level: Number(currentMod.level ?? 0),
            protectionEligible: currentMod.protectionEligible ?? true,
            hardFlags: currentMod.hardFlags ?? {},
          },
          after: {
            level: nextLevel,
            protectionEligible: nextProtectionEligible ?? true,
            hardFlags: nextHardFlags,
          },
          reason,
          createdAt: FieldValue.serverTimestamp(),
        });
      }

      if (banChanged) {
        tx.set(
          entRef,
          {
            protectionBan: {
              active: nextBanActive === true,
              reason: nextBanReason,
              until: nextBanUntil,
            },
            updatedAt: FieldValue.serverTimestamp(),
            serverMeta: {
              lastOp: opKey,
              lastWriter: SERVER_WRITER,
              updatedAt: FieldValue.serverTimestamp(),
              source: SERVER_WRITER,
            },
          },
          {merge: true},
        );
      }
    });

    return {ok: true};
  },
);

export const adminSetBan = onCall(
  {
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (request) => {
    const isAdmin = request.auth?.token?.admin === true;
    const adminUid = request.auth?.uid ?? "";
    if (!isAdmin) {
      throw new HttpsError("permission-denied", "Admin only.");
    }
    const data = request.data ?? {};
    const uid = (data.uid ?? "").toString();
    const reason = (data.reason ?? "").toString();
    const banRaw = data.banUntil;
    if (!uid) {
      throw new HttpsError("invalid-argument", "Missing uid.");
    }

    const moderationRef = db.collection("user_moderation").doc(uid);
    const entRef = db.collection("user_entitlements").doc(uid);
    const queueRef = db.collection("match_sessions").doc(`queue_${uid}`);
    const opKey = `adminSetBan:${uid}:${Date.now()}`;
    const untilMs = parseExpiryMillis(banRaw);
    const nextBanActive = banRaw != null && Number.isFinite(untilMs);
    const nextBanUntil = Number.isFinite(untilMs)
      ? Timestamp.fromMillis(untilMs)
      : null;

    await db.runTransaction(async (tx) => {
      const [modSnap, entSnap, queueSnap] = await Promise.all([
        tx.get(moderationRef),
        tx.get(entRef),
        tx.get(queueRef),
      ]);
      const currentMod = modSnap.data() ?? {};
      const currentEnt = entSnap.data() ?? {};
      const currentBan = (currentEnt.protectionBan ?? {}) as Record<string, unknown>;

      const changed =
        (currentBan.active === true) !== nextBanActive ||
        (currentBan.reason ?? "").toString() !== reason ||
        JSON.stringify(currentBan.until ?? null) !== JSON.stringify(nextBanUntil);

      if (!changed) return;

      tx.set(
        entRef,
        {
          protectionBan: {
            active: nextBanActive,
            reason,
            until: nextBanUntil,
          },
          updatedAt: FieldValue.serverTimestamp(),
          serverMeta: {
            lastOp: opKey,
            lastWriter: SERVER_WRITER,
            updatedAt: FieldValue.serverTimestamp(),
            source: SERVER_WRITER,
          },
        },
        {merge: true},
      );

      if (nextBanActive) {
        tx.set(
          moderationRef,
          {
            level: 2,
            updatedAt: FieldValue.serverTimestamp(),
            serverMeta: {
              lastOp: opKey,
              lastWriter: SERVER_WRITER,
              updatedAt: FieldValue.serverTimestamp(),
              source: SERVER_WRITER,
            },
          },
          {merge: true},
        );
      }

      if (queueSnap.exists) {
        const queueData = queueSnap.data() ?? {};
        if ((queueData.status ?? "").toString() == "searching") {
          tx.set(
            queueRef,
            {
              status: "idle",
              updatedAt: FieldValue.serverTimestamp(),
              serverMeta: {
                lastOp: opKey,
                lastWriter: SERVER_WRITER,
                updatedAt: FieldValue.serverTimestamp(),
                source: SERVER_WRITER,
              },
            },
            {merge: true},
          );
        }
      }

      const actionRef = db.collection("_ops").doc("admin_actions").collection("items").doc();
      tx.set(actionRef, {
        adminUid,
        targetUid: uid,
        actionType: nextBanActive ? "set_ban" : "clear_ban",
        before: {
          protectionBan: currentBan,
          moderationLevel: Number(currentMod.level ?? 0),
        },
        after: {
          protectionBan: {
            active: nextBanActive,
            reason,
            until: nextBanUntil,
          },
          moderationLevel: nextBanActive ? 2 : Number(currentMod.level ?? 0),
        },
        reason,
        createdAt: FieldValue.serverTimestamp(),
      });
    });

    return {ok: true};
  },
);

export const onReportCreated = onDocumentCreated(
  {
    document: "reports/{reportId}",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (event) => {
    const reportSnap = event.data;
    if (!reportSnap?.exists) return;
    const reportId = event.params.reportId as string;
    const reportData = reportSnap.data() ?? {};
    const reportedUid = (reportData.reportedUid ?? "").toString();
    const reason = (reportData.reason ?? "unknown").toString();
    if (!reportedUid) return;

    const ref = db.collection("user_moderation").doc(reportedUid);
    const opKey = `onReportCreated:${reportId}`;

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const current = snap.data() ?? {};
      if (current.serverMeta?.lastOp === opKey) return;

      const totalReports = Number(current.totalReports ?? 0) + 1;
      const reasonCounts = {
        ...(current.reasonCounts ?? {}),
      } as Record<string, number>;
      reasonCounts[reason] = Number(reasonCounts[reason] ?? 0) + 1;
      const protectionEligible =
        (current.protectionEligible ?? true) as boolean;
      const hardFlags =
        (current.hardFlags ?? {
          severe: false,
          spam: false,
          sexual: false,
          violence: false,
        }) as Record<string, boolean>;

      const level =
        totalReports >= MODERATION_LEVEL_TWO_THRESHOLD
          ? 2
          : totalReports >= MODERATION_LEVEL_ONE_THRESHOLD
          ? 1
          : 0;

      tx.set(
        ref,
        {
          reportedUid,
          totalReports,
          reasonCounts,
          protectionEligible,
          hardFlags,
          level,
          lastReportAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          serverMeta: {
            lastOp: opKey,
            lastWriter: SERVER_WRITER,
            updatedAt: FieldValue.serverTimestamp(),
            source: SERVER_WRITER,
          },
        },
        {merge: true},
      );
    });
  },
);

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
    const minuteKey = formatMinuteKey(new Date());

    // Batch + loop avoids unbounded reads and keeps costs predictable.
    while (true) {
      const snapshot = await db
        .collection("match_sessions")
        .where("mode", "==", "auto")
        .where("status", "in", statuses as unknown as string[])
        .where("expiresAt", "<=", now)
        .orderBy("expiresAt")
        .limit(50)
        .get();

      if (snapshot.empty) {
        break;
      }

      // Process per-doc with strong idempotency lock to avoid repeat writes.
      for (const doc of snapshot.docs) {
        const data = doc.data() ?? {};
        if (data.status?.toString() !== "pending") continue;
        const expiresAt = data.expiresAt as Timestamp | undefined;
        if (!expiresAt || expiresAt.toMillis() > now.toMillis()) continue;
        const opKey = minuteKey;
        await db.runTransaction(async (tx) => {
          const snap = await tx.get(doc.ref);
          if (!snap.exists) return;
          const current = snap.data() ?? {};
          if (current.status?.toString() !== "pending") return;
          const currentExpiresAt = current.expiresAt as Timestamp | undefined;
          if (!currentExpiresAt || currentExpiresAt.toMillis() > now.toMillis()) {
            return;
          }
          const locked = await acquireOpLock(tx, doc.ref, opKey);
          if (!locked) return;
          tx.set(
            doc.ref,
            {
              status: "expired",
              respondedAt: FieldValue.serverTimestamp(),
              updatedAt: FieldValue.serverTimestamp(),
              serverMeta: {
                lastOp: opKey,
                lastWriter: SERVER_WRITER,
                updatedAt: FieldValue.serverTimestamp(),
                source: SERVER_WRITER,
              },
            },
            {merge: true},
          );
        });
      }
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
    if (afterData.serverMeta?.source === SERVER_WRITER) return;
    const beforeStatus = beforeData.status?.toString();
    const afterStatus = afterData.status?.toString();
    const responses = (afterData.responses ?? {}) as Record<string, unknown>;
    const userA = (afterData.userA ?? "").toString();
    const userB = (afterData.userB ?? "").toString();
    const beforeResponses = (beforeData.responses ?? {}) as Record<string, unknown>;
    const responsesChanged =
      JSON.stringify(beforeResponses) !== JSON.stringify(responses);
    const beforeHash = stableHash({
      status: beforeStatus,
      responses: beforeResponses,
      chatRoomId: beforeData.chatRoomId ?? null,
    });
    const afterHash = stableHash({
      status: afterStatus,
      responses,
      chatRoomId: afterData.chatRoomId ?? null,
    });
    if (beforeHash === afterHash) return;
    const bothAccepted =
      responses[userA]?.toString() === "accepted" &&
      responses[userB]?.toString() === "accepted";
    const shouldAccept = afterStatus === "pending" && bothAccepted;
    // Guard: ignore writes with no relevant change.
    if (beforeStatus === afterStatus && !responsesChanged) return;
    if (beforeStatus === "accepted") return;
    if (afterStatus !== "accepted" && !shouldAccept) return;

    const sessionId = event.params.sessionId as string;
    const sessionRef = db.collection("match_sessions").doc(sessionId);
    const roomRef = db.collection("chat_rooms").doc(sessionId);
    const opKey = `onMatchSessionAccepted:${sessionId}:${afterStatus}:${JSON.stringify(responses)}`;
    if (afterData.serverMeta?.lastOp === opKey) return;

    await db.runTransaction(async (tx) => {
      const sessionSnap = await tx.get(sessionRef);
      if (!sessionSnap.exists) return;
      const data = sessionSnap.data() ?? {};
      const status = data.status?.toString();
      if (data.serverMeta?.lastOp === opKey) return;
      const locked = await acquireOpLock(tx, sessionRef, opKey);
      if (!locked) return;
      const sessionResponses = (data.responses ?? {}) as Record<string, unknown>;
      const txUserA = (data.userA ?? "").toString();
      const txUserB = (data.userB ?? "").toString();
      const txBothAccepted =
        sessionResponses[txUserA]?.toString() === "accepted" &&
        sessionResponses[txUserB]?.toString() === "accepted";
      if (status !== "accepted" && !txBothAccepted) return;
      if (data.chatRoomId != null && status === "accepted") return;

      const participants = [txUserA, txUserB].filter((id) => id.trim().length > 0);
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
      const alreadyAccepted = status?.toString() === "accepted";
      tx.set(
        sessionRef,
        {
          chatRoomId: sessionId,
          respondedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          status: alreadyAccepted ? status : "accepted",
          serverMeta: {
            lastOp: opKey,
            lastWriter: SERVER_WRITER,
            updatedAt: FieldValue.serverTimestamp(),
            source: SERVER_WRITER,
          },
        },
        {merge: true}
      );
    });

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

export const onMatchSessionRejectedByResponse = onDocumentWritten(
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
    if (afterData.serverMeta?.source === SERVER_WRITER) return;

    const sessionId = event.params.sessionId as string;
    if (sessionId.startsWith("queue_")) return;

    const beforeStatus = beforeData.status?.toString();
    const afterStatus = afterData.status?.toString();
    const beforeResponses = (beforeData.responses ?? {}) as Record<string, unknown>;
    const afterResponses = (afterData.responses ?? {}) as Record<string, unknown>;
    const responsesChanged =
      JSON.stringify(beforeResponses) !== JSON.stringify(afterResponses);
    const beforeHash = stableHash({status: beforeStatus, responses: beforeResponses});
    const afterHash = stableHash({status: afterStatus, responses: afterResponses});
    if (beforeHash === afterHash) return;
    // Guard: ignore writes with no relevant change.
    if (beforeStatus === afterStatus && !responsesChanged) return;
    if (afterStatus !== "pending") return;
    if (beforeStatus === "rejected" || beforeStatus === "expired") return;

    const userA = (afterData.userA ?? "").toString();
    const userB = (afterData.userB ?? "").toString();
    const responses = afterResponses;
    const rejected =
      responses[userA]?.toString() === "rejected" ||
      responses[userB]?.toString() === "rejected";
    if (!rejected) return;

    console.log("auto-match response rejected", {sessionId});
    const opKey = `onMatchSessionRejectedByResponse:${sessionId}:${JSON.stringify(responses)}`;
    if (afterData.serverMeta?.lastOp === opKey) return;

    await db.runTransaction(async (tx) => {
      const ref = db.collection("match_sessions").doc(sessionId);
      const snap = await tx.get(ref);
      if (!snap.exists) return;
      const data = snap.data() ?? {};
      const status = data.status?.toString();
      if (data.serverMeta?.lastOp === opKey) return;
      const locked = await acquireOpLock(tx, ref, opKey);
      if (!locked) return;
      if (status !== "pending") return;
      if (status === "rejected") return;
      tx.set(
        ref,
        {
          status: "rejected",
          respondedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          serverMeta: {
            lastOp: opKey,
            lastWriter: SERVER_WRITER,
            updatedAt: FieldValue.serverTimestamp(),
            source: SERVER_WRITER,
          },
        },
        {merge: true},
      );
    });
  },
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
    if (afterData.serverMeta?.source === SERVER_WRITER) return;

    const sessionId = event.params.sessionId as string;
    if (!sessionId.startsWith("queue_")) {
      console.log("auto-match skip: not queue doc", {sessionId});
      return;
    }

    const afterStatus = afterData.status?.toString();
    const beforeStatus = beforeData.status?.toString();
    const mode = afterData.mode?.toString();
    const beforeInterests = beforeData.interests ?? [];
    const afterInterests = afterData.interests ?? [];
    const beforeLocation = locationKey(beforeData.location);
    const afterLocation = locationKey(afterData.location);
    const beforeHash = stableHash({
      status: beforeStatus,
      userA: beforeData.userA ?? null,
      mode: beforeData.mode ?? null,
      interests: beforeInterests,
      location: beforeLocation,
      radiusKm: beforeData.radiusKm ?? null,
    });
    const afterHash = stableHash({
      status: afterStatus,
      userA: afterData.userA ?? null,
      mode: afterData.mode ?? null,
      interests: afterInterests,
      location: afterLocation,
      radiusKm: afterData.radiusKm ?? null,
    });
    const fieldsChanged = beforeHash !== afterHash;

    console.log("auto-match entry", {
      sessionId,
      mode,
      beforeStatus,
      afterStatus,
    });

    if (!fieldsChanged) {
      console.log("auto-match skip: no relevant field changes", {sessionId});
      return;
    }

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

    const userA = (afterData.userA ?? "").toString();
    if (!userA) {
      console.log("auto-match skip: missing userA", {sessionId});
      return;
    }

    console.log("auto-match attempt start", {userA});

    const gateAllowed = await db.runTransaction(async (tx) => {
      const queueSnap = await tx.get(afterSnap.ref);
      if (!queueSnap.exists) return false;
      const gate = await evaluateMatchGate(tx, userA);
      if (gate.decision === "BLOCK") {
        console.log("auto-match gate block at entry", {userA, reason: gate.reason});
        setQueueIdle(tx, afterSnap.ref, `gate-entry:${userA}`);
        return false;
      }
      if (gate.decision === "ALLOW_LIMITED") {
        const ok = await applyLimitedThrottle(tx, userA);
        if (!ok) {
          console.log("auto-match gate cooldown at entry", {userA});
          setQueueIdle(tx, afterSnap.ref, `gate-cooldown:${userA}`);
          return false;
        }
      }
      return true;
    });
    if (!gateAllowed) return;

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
    const now = Date.now();
    const minuteKey = formatMinuteKey(new Date());

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

      for (const doc of snapshot.docs) {
        const data = doc.data() ?? {};
        if (data.status?.toString() === "searching") {
          lastDoc = doc;
          continue;
        }
        const updatedAt = data.updatedAt as Timestamp | undefined;
        if (updatedAt && now - updatedAt.toMillis() < 60 * 1000) {
          lastDoc = doc;
          continue;
        }
        const locked = await db.runTransaction(async (tx) => {
          const snap = await tx.get(doc.ref);
          if (!snap.exists) return false;
          const current = snap.data() ?? {};
          if (current.status?.toString() === "searching") return false;
          const currentUpdatedAt = current.updatedAt as Timestamp | undefined;
          if (currentUpdatedAt && now - currentUpdatedAt.toMillis() < 60 * 1000) {
            return false;
          }
          return acquireOpLock(tx, doc.ref, minuteKey);
        });
        if (!locked) {
          lastDoc = doc;
          continue;
        }
        const updates: Record<string, unknown> = {};

        if ("userB" in data) updates.userB = FieldValue.delete();
        if ("participants" in data) updates.participants = FieldValue.delete();
        if ("ready" in data) updates.ready = FieldValue.delete();
        if ("cancelledBy" in data) updates.cancelledBy = FieldValue.delete();
        if ("connectedAt" in data) updates.connectedAt = FieldValue.delete();

        if (Object.keys(updates).length > 0) {
          await doc.ref.set(
            {
              ...updates,
              serverMeta: {
                lastOp: minuteKey,
                lastWriter: SERVER_WRITER,
                updatedAt: FieldValue.serverTimestamp(),
                source: SERVER_WRITER,
              },
            },
            {merge: true},
          );
        }
        lastDoc = doc;
      }
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
    if (!queueASnap.exists || !queueBSnap.exists) {
      console.log("auto-match skip: queue missing");
      return;
    }

    const queueAData = queueASnap.data() ?? {};
    const queueBData = queueBSnap.data() ?? {};
    if (queueAData.status?.toString() !== "searching") {
      console.log("auto-match skip: queueA not searching");
      return;
    }
    if (queueBData.status?.toString() !== "searching") {
      console.log("auto-match skip: queueB not searching");
      return;
    }
    if (queueAData.mode?.toString() !== "auto") {
      console.log("auto-match skip: queueA not auto");
      return;
    }
    if (queueBData.mode?.toString() !== "auto") {
      console.log("auto-match skip: queueB not auto");
      return;
    }
    if (!queueASnap.id.startsWith("queue_")) {
      console.log("auto-match skip: queueA id not queue_");
      return;
    }
    if (!queueBSnap.id.startsWith("queue_")) {
      console.log("auto-match skip: queueB id not queue_");
      return;
    }

    const userAId = (queueAData.userA ?? "").toString();
    const userBId = (queueBData.userA ?? "").toString();
    if (!userAId || !userBId || userAId === userBId) {
      console.log("auto-match skip: invalid users", {userAId, userBId});
      return;
    }

    const hydratedA = await hydrateQueueUser(tx, userAId, queueAData);
    const hydratedB = await hydrateQueueUser(tx, userBId, queueBData);
    if (!hydratedA || !hydratedB) {
      console.log("auto-match skip: hydrate failed");
      return;
    }

    const gateA = await evaluateMatchGate(tx, userAId);
    const gateB = await evaluateMatchGate(tx, userBId);
    if (gateA.decision === "BLOCK") {
      console.log("auto-match skip: gate block", {userAId, reason: gateA.reason});
      setQueueIdle(tx, queueARef, `gate:${userAId}`);
      return;
    }
    if (gateB.decision === "BLOCK") {
      console.log("auto-match skip: gate block", {userBId, reason: gateB.reason});
      setQueueIdle(tx, queueBRef, `gate:${userBId}`);
      return;
    }
    if (gateA.decision === "ALLOW_LIMITED") {
      const allowed = await applyLimitedThrottle(tx, userAId);
      if (!allowed) {
        console.log("auto-match skip: limited cooldown", {userAId});
        setQueueIdle(tx, queueARef, `cooldown:${userAId}`);
        return;
      }
    }
    if (gateB.decision === "ALLOW_LIMITED") {
      const allowed = await applyLimitedThrottle(tx, userBId);
      if (!allowed) {
        console.log("auto-match skip: limited cooldown", {userBId});
        setQueueIdle(tx, queueBRef, `cooldown:${userBId}`);
        return;
      }
    }

    console.log("auto-match eligible users", {userAId, userBId});

    if (!hasCommonInterest(hydratedA.interests, hydratedB.interests)) {
      console.log("auto-match skip: no common interests");
      return;
    }
    const distanceKm = distanceBetweenKm(hydratedA.location, hydratedB.location);
    if (distanceKm == null) {
      console.log("auto-match skip: distance missing");
      return;
    }
    const maxDistance = Math.min(hydratedA.radiusKm, hydratedB.radiusKm);
    if (distanceKm > maxDistance) {
      console.log("auto-match skip: outside radius");
      return;
    }

    const ids = [userAId, userBId].sort();
    const pairSessionId = `${ids[0]}_${ids[1]}`;
    const pairRef = db.collection("match_sessions").doc(pairSessionId);
    const pairSnap = await tx.get(pairRef);
    if (pairSnap.exists) {
      console.log("auto-match skip: pair already exists", {pairSessionId});
      return;
    }
    const opKey = `tryPairQueues:${pairSessionId}:${expiresAt.toMillis()}`;
    const locked = await acquireOpLock(tx, pairRef, opKey);
    if (!locked) return;

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
      responses: {
        [ids[0]]: null,
        [ids[1]]: null,
      },
      createdAt: FieldValue.serverTimestamp(),
      respondedAt: null,
      expiresAt,
      updatedAt: FieldValue.serverTimestamp(),
      serverMeta: {
        lastOp: opKey,
        lastWriter: SERVER_WRITER,
        updatedAt: FieldValue.serverTimestamp(),
        source: SERVER_WRITER,
      },
    });
    console.log("auto-match created match_session", {pairSessionId});

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
      {
        status: "idle",
        updatedAt: FieldValue.serverTimestamp(),
        serverMeta: {
          lastOp: opKey,
          lastWriter: SERVER_WRITER,
          updatedAt: FieldValue.serverTimestamp(),
          source: SERVER_WRITER,
        },
      },
      {merge: true},
    );
    tx.set(
      queueBRef,
      {
        status: "idle",
        updatedAt: FieldValue.serverTimestamp(),
        serverMeta: {
          lastOp: opKey,
          lastWriter: SERVER_WRITER,
          updatedAt: FieldValue.serverTimestamp(),
          source: SERVER_WRITER,
        },
      },
      {merge: true},
    );
    console.log("auto-match paired", {pairSessionId});
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
    if (afterData.serverMeta?.source === SERVER_WRITER) return;

    const sessionId = event.params.sessionId as string;
    if (sessionId.startsWith("queue_")) return;

    const afterStatus = afterData.status?.toString();
    const beforeStatus = beforeData.status?.toString();
    const beforeHash = stableHash({status: beforeStatus});
    const afterHash = stableHash({status: afterStatus});
    // Guard: ignore writes with no relevant change.
    if (beforeHash === afterHash) return;
    if (beforeStatus === afterStatus) return;
    if (afterStatus !== "expired" && afterStatus !== "rejected") return;

    console.log("auto-match rejected/expired: client should requeue", {
      sessionId,
      afterStatus,
    });
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
    console.log("auto-match hydrate: queue missing fields", {
      userId,
      hasInterests: Array.isArray(interests) && interests.length > 0,
      hasLocation: !!location,
      radiusKm,
    });
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
    console.log("auto-match hydrate: invalid user data", {
      userId,
      interestsCount: normalizedInterests.length,
      hasLocation: !!location,
      radiusKm,
    });
    return null;
  }

  return {
    interests: normalizedInterests,
    location,
    radiusKm,
  };
}

type MatchGateDecision = "ALLOW" | "DELAY" | "BLOCK" | "ALLOW_LIMITED";

async function evaluateMatchGate(
  tx: Transaction,
  uid: string,
): Promise<{decision: MatchGateDecision; reason?: string}> {
  const moderationRef = db.collection("user_moderation").doc(uid);
  const entRef = db.collection("user_entitlements").doc(uid);
  const [modSnap, entSnap] = await Promise.all([
    tx.get(moderationRef),
    tx.get(entRef),
  ]);
  const moderation = modSnap.data() ?? {};
  const entitlements = entSnap.data() ?? {};

  const level = Number(moderation.level ?? 0);
  const protectionEligible = moderation.protectionEligible ?? true;
  const hardFlags = (moderation.hardFlags ?? {}) as Record<string, boolean>;
  const severe = hardFlags.severe === true;
  const sexual = hardFlags.sexual === true;
  const violence = hardFlags.violence === true;

  const protection = (entitlements.protection ?? {}) as Record<string, unknown>;
  const ban = (entitlements.protectionBan ?? {}) as Record<string, unknown>;
  const banActive = ban.active === true;
  const banUntil = ban.until as Timestamp | null | undefined;
  const now = Timestamp.now();
  const banEffective = banActive && (!banUntil || banUntil.toMillis() > now.toMillis());

  const active = protection.active === true;
  const expiresAt = protection.expiresAt as Timestamp | undefined;
  const validProtection =
    active && !!expiresAt && expiresAt.toMillis() > now.toMillis() && !banEffective;

  if (level <= 0) return {decision: "ALLOW"};
  if (level === 1) {
    return validProtection ? {decision: "ALLOW"} : {decision: "DELAY"};
  }
  if (
    validProtection &&
    protectionEligible === true &&
    !severe &&
    !sexual &&
    !violence
  ) {
    return {decision: "ALLOW_LIMITED"};
  }
  return {decision: "BLOCK", reason: "level2"};
}

async function applyLimitedThrottle(tx: Transaction, uid: string): Promise<boolean> {
  const entRef = db.collection("user_entitlements").doc(uid);
  const snap = await tx.get(entRef);
  const data = snap.data() ?? {};
  const protection = (data.protection ?? {}) as Record<string, unknown>;
  // NOTE:
  // lastQueueAt is used ONLY for limited protection throttling.
  // It does NOT affect entitlement validity or billing logic.
  const lastQueueAt = protection.lastQueueAt as Timestamp | undefined;
  const now = Timestamp.now();
  if (lastQueueAt) {
    const diffMs = now.toMillis() - lastQueueAt.toMillis();
    if (diffMs < MATCH_LIMIT_MINUTES * 60 * 1000) {
      return false;
    }
  }
  tx.set(
    entRef,
    {
      protection: {
        ...protection,
        lastQueueAt: FieldValue.serverTimestamp(),
      },
      updatedAt: FieldValue.serverTimestamp(),
      serverMeta: {
        lastOp: `limitedQueue:${uid}:${now.toMillis()}`,
        lastWriter: SERVER_WRITER,
        updatedAt: FieldValue.serverTimestamp(),
        source: SERVER_WRITER,
      },
    },
    {merge: true},
  );
  return true;
}

function setQueueIdle(
  tx: Transaction,
  queueRef: DocumentReference<DocumentData>,
  opKey: string,
): void {
  tx.set(
    queueRef,
    {
      status: "idle",
      updatedAt: FieldValue.serverTimestamp(),
      serverMeta: {
        lastOp: opKey,
        lastWriter: SERVER_WRITER,
        updatedAt: FieldValue.serverTimestamp(),
        source: SERVER_WRITER,
      },
    },
    {merge: true},
  );
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

function stableHash(input: Record<string, unknown>): string {
  return JSON.stringify(sortObject(input));
}

function sortObject(input: Record<string, unknown>): Record<string, unknown> {
  const keys = Object.keys(input).sort();
  const result: Record<string, unknown> = {};
  for (const key of keys) {
    const value = input[key];
    if (value && typeof value === "object" && !Array.isArray(value)) {
      result[key] = sortObject(value as Record<string, unknown>);
    } else {
      result[key] = value;
    }
  }
  return result;
}

function locationKey(value: unknown): string {
  const loc = value as GeoPoint | undefined;
  if (!loc) return "null";
  const lat = Math.round(loc.latitude / LOCATION_EPS) * LOCATION_EPS;
  const lng = Math.round(loc.longitude / LOCATION_EPS) * LOCATION_EPS;
  return `${lat}:${lng}`;
}

function formatMinuteKey(date: Date): string {
  const pad = (n: number) => n.toString().padStart(2, "0");
  return [
    date.getUTCFullYear(),
    pad(date.getUTCMonth() + 1),
    pad(date.getUTCDate()),
    pad(date.getUTCHours()),
    pad(date.getUTCMinutes()),
  ].join("");
}

function parseExpiryMillis(value: unknown): number {
  if (typeof value === "number") return value;
  if (typeof value === "string") {
    const parsed = Date.parse(value);
    if (Number.isFinite(parsed)) return parsed;
    const num = Number(value);
    if (Number.isFinite(num)) return num;
  }
  return NaN;
}

async function acquireOpLock(
  tx: Transaction,
  sessionRef: DocumentReference<DocumentData>,
  opKey: string,
): Promise<boolean> {
  const opRef = sessionRef.collection("_ops").doc(opKey);
  const opSnap = await tx.get(opRef);
  if (opSnap.exists) return false;
  tx.set(opRef, {createdAt: FieldValue.serverTimestamp()});
  return true;
}

async function deleteStorageFolder(prefix: string): Promise<void> {
  const bucket = storage.bucket();
  let pageToken: string | undefined;
  while (true) {
    const [files, _, apiResponse] = await bucket.getFiles({
      prefix,
      autoPaginate: false,
      maxResults: 1000,
      pageToken,
    });
    if (files.length === 0) break;
    await Promise.all(files.map((file) => file.delete().catch(() => undefined)));
    pageToken = (apiResponse as any)?.nextPageToken;
    if (!pageToken) break;
  }
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
    if (afterData.serverMeta?.source === SERVER_WRITER) return;
    const beforeStatus = beforeData.status?.toString();
    const afterStatus = afterData.status?.toString();
    const beforeHash = stableHash({
      status: beforeStatus,
      chatRoomId: beforeData.chatRoomId ?? null,
    });
    const afterHash = stableHash({
      status: afterStatus,
      chatRoomId: afterData.chatRoomId ?? null,
    });
    // Guard: ignore writes with no relevant change.
    if (beforeHash === afterHash) return;
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
        title: "Match accepted",
        body: "You can start chatting now.",
      },
      data: {
        type: "match_accepted",
        sessionId,
        chatRoomId,
      },
    });
  },
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
    if (messageData.serverMeta?.source === SERVER_WRITER) return;

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
        title: "New message",
        body: "You received a new message.",
      },
      data: {
        type: "new_message",
        roomId,
        messageId,
        senderId,
      },
    });
  },
);

export const onChatRoomEnded = onDocumentWritten(
  {
    document: "chat_rooms/{roomId}",
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
    if (afterData.serverMeta?.source === SERVER_WRITER) return;

    const roomId = event.params.roomId as string;
    const beforeEndedBy = (beforeData.endedBy ?? "").toString();
    const afterEndedBy = (afterData.endedBy ?? "").toString();
    const beforeHash = stableHash({endedBy: beforeEndedBy});
    const afterHash = stableHash({endedBy: afterEndedBy});
    if (beforeHash === afterHash) return;
    if (!afterEndedBy) return;

    if (!beforeEndedBy) {
      await db
        .collection("chat_rooms")
        .doc(roomId)
        .collection("messages")
        .add({
          senderId: "system",
          text: "The other user ended the chat.",
          createdAt: FieldValue.serverTimestamp(),
        });
      return;
    }

    if (beforeEndedBy && afterEndedBy && beforeEndedBy !== afterEndedBy) {
      await deleteChatRoomWithMessages(roomId);
    }
  },
);

async function deleteChatRoomWithMessages(roomId: string): Promise<void> {
  const roomRef = db.collection("chat_rooms").doc(roomId);
  const messagesRef = roomRef.collection("messages");
  while (true) {
    const snapshot = await messagesRef.limit(200).get();
    if (snapshot.empty) break;
    const batch = db.batch();
    for (const doc of snapshot.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
  }
  await roomRef.delete();
}

async function markMatchAcceptedNotified(sessionId: string): Promise<boolean> {
  const sessionRef = db.collection("match_sessions").doc(sessionId);
  let shouldSend = false;
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(sessionRef);
    if (!snap.exists) return;
    const data = snap.data() ?? {};
    const notified = (data.notified ?? {}) as Record<string, unknown>;
    if (notified.accepted === true) return;
    const opKey = `markMatchAcceptedNotified:${sessionId}`;
    if (data.serverMeta?.lastOp === opKey) return;
    const locked = await acquireOpLock(tx, sessionRef, opKey);
    if (!locked) return;
    tx.set(
      sessionRef,
      {
        notified: {
          ...notified,
          accepted: true,
          acceptedAt: FieldValue.serverTimestamp(),
        },
        serverMeta: {
          lastOp: opKey,
          lastWriter: SERVER_WRITER,
          updatedAt: FieldValue.serverTimestamp(),
          source: SERVER_WRITER,
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
    const opKey = `markMessageNotified:${roomId}:${messageId}`;
    if (data.serverMeta?.lastOp === opKey) return;
    const locked = await acquireOpLock(tx, messageRef, opKey);
    if (!locked) return;
    tx.set(
      messageRef,
      {
        notified: true,
        notifiedAt: FieldValue.serverTimestamp(),
        serverMeta: {
          lastOp: opKey,
          lastWriter: SERVER_WRITER,
          updatedAt: FieldValue.serverTimestamp(),
          source: SERVER_WRITER,
        },
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
      batch.set(
        ref,
        {
          enabled: false,
          updatedAt: FieldValue.serverTimestamp(),
          serverMeta: {
            lastWriter: SERVER_WRITER,
            updatedAt: FieldValue.serverTimestamp(),
            source: SERVER_WRITER,
          },
        },
        {merge: true},
      );
    }
    await batch.commit();
  }
}
