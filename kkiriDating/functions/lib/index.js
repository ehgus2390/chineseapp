"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onChatRoomEnded = exports.onChatMessageCreatedNotification = exports.onMatchSessionAcceptedNotification = exports.onMatchSessionRejectedOrExpired = exports.cleanupQueueDocs = exports.onAutoMatchSessionSearching = exports.onMatchSessionRejectedByResponse = exports.onMatchSessionAccepted = exports.expireMatchSessions = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const firestore_1 = require("firebase-functions/v2/firestore");
const app_1 = require("firebase-admin/app");
const firestore_2 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");
(0, app_1.initializeApp)();
const db = (0, firestore_2.getFirestore)();
const messaging = (0, messaging_1.getMessaging)();
// B-step hardening: region/memory/timeout to control cost and latency.
exports.expireMatchSessions = (0, scheduler_1.onSchedule)({
    schedule: "every 1 minutes",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
}, async () => {
    var _a;
    // Only expire pending matches; queue docs are handled separately.
    const statuses = ["pending"];
    const now = firestore_2.Timestamp.now();
    // Batch + loop avoids unbounded reads and keeps costs predictable.
    while (true) {
        const snapshot = await db
            .collection("match_sessions")
            .where("mode", "==", "auto")
            .where("status", "in", statuses)
            .where("expiresAt", "<=", now)
            .orderBy("expiresAt")
            .limit(200)
            .get();
        if (snapshot.empty) {
            break;
        }
        const batch = db.batch();
        for (const doc of snapshot.docs) {
            const data = (_a = doc.data()) !== null && _a !== void 0 ? _a : {};
            batch.set(doc.ref, {
                status: "expired",
                respondedAt: firestore_2.FieldValue.serverTimestamp(),
                updatedAt: firestore_2.FieldValue.serverTimestamp(),
            }, { merge: true });
        }
        await batch.commit();
    }
});
exports.onMatchSessionAccepted = (0, firestore_1.onDocumentWritten)("match_sessions/{sessionId}", async (event) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l;
    const beforeSnap = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before;
    const afterSnap = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after;
    if (!afterSnap || !afterSnap.exists)
        return;
    // Extract once to avoid redeclaration bugs.
    const beforeData = (_c = beforeSnap === null || beforeSnap === void 0 ? void 0 : beforeSnap.data()) !== null && _c !== void 0 ? _c : {};
    const afterData = (_d = afterSnap.data()) !== null && _d !== void 0 ? _d : {};
    const beforeStatus = (_e = beforeData.status) === null || _e === void 0 ? void 0 : _e.toString();
    const afterStatus = (_f = afterData.status) === null || _f === void 0 ? void 0 : _f.toString();
    const responses = ((_g = afterData.responses) !== null && _g !== void 0 ? _g : {});
    const userA = ((_h = afterData.userA) !== null && _h !== void 0 ? _h : "").toString();
    const userB = ((_j = afterData.userB) !== null && _j !== void 0 ? _j : "").toString();
    const bothAccepted = ((_k = responses[userA]) === null || _k === void 0 ? void 0 : _k.toString()) === "accepted" &&
        ((_l = responses[userB]) === null || _l === void 0 ? void 0 : _l.toString()) === "accepted";
    const shouldAccept = afterStatus === "pending" && bothAccepted;
    if (beforeStatus === "accepted")
        return;
    if (afterStatus !== "accepted" && !shouldAccept)
        return;
    const sessionId = event.params.sessionId;
    const sessionRef = db.collection("match_sessions").doc(sessionId);
    const roomRef = db.collection("chat_rooms").doc(sessionId);
    await db.runTransaction(async (tx) => {
        var _a, _b, _c, _d, _e, _f, _g, _h, _j;
        const sessionSnap = await tx.get(sessionRef);
        if (!sessionSnap.exists)
            return;
        const data = (_a = sessionSnap.data()) !== null && _a !== void 0 ? _a : {};
        const status = (_b = data.status) === null || _b === void 0 ? void 0 : _b.toString();
        const sessionResponses = ((_c = data.responses) !== null && _c !== void 0 ? _c : {});
        const txUserA = ((_d = data.userA) !== null && _d !== void 0 ? _d : "").toString();
        const txUserB = ((_e = data.userB) !== null && _e !== void 0 ? _e : "").toString();
        const txBothAccepted = ((_f = sessionResponses[txUserA]) === null || _f === void 0 ? void 0 : _f.toString()) === "accepted" &&
            ((_g = sessionResponses[txUserB]) === null || _g === void 0 ? void 0 : _g.toString()) === "accepted";
        if (status !== "accepted" && !txBothAccepted)
            return;
        if (data.chatRoomId != null)
            return;
        const participants = [txUserA, txUserB].filter((id) => id.trim().length > 0);
        if (participants.length < 2)
            return;
        const mode = (_j = (_h = data.mode) === null || _h === void 0 ? void 0 : _h.toString()) !== null && _j !== void 0 ? _j : null;
        const roomSnap = await tx.get(roomRef);
        if (!roomSnap.exists) {
            tx.set(roomRef, {
                participants,
                sessionId,
                mode,
                createdAt: firestore_2.FieldValue.serverTimestamp(),
                updatedAt: firestore_2.FieldValue.serverTimestamp(),
                lastMessage: null,
                lastMessageAt: null,
                isActive: true,
            }, { merge: true });
        }
        // Idempotent: always link the session to the room if accepted.
        tx.set(sessionRef, {
            chatRoomId: sessionId,
            respondedAt: firestore_2.FieldValue.serverTimestamp(),
            updatedAt: firestore_2.FieldValue.serverTimestamp(),
            status: "accepted",
        }, { merge: true });
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
            createdAt: firestore_2.FieldValue.serverTimestamp(),
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
            createdAt: firestore_2.FieldValue.serverTimestamp(),
        });
    }
});
exports.onMatchSessionRejectedByResponse = (0, firestore_1.onDocumentWritten)({
    document: "match_sessions/{sessionId}",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
}, async (event) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l;
    const beforeSnap = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before;
    const afterSnap = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after;
    if (!afterSnap || !afterSnap.exists)
        return;
    // Extract once to avoid redeclaration bugs.
    const beforeData = (_c = beforeSnap === null || beforeSnap === void 0 ? void 0 : beforeSnap.data()) !== null && _c !== void 0 ? _c : {};
    const afterData = (_d = afterSnap.data()) !== null && _d !== void 0 ? _d : {};
    const sessionId = event.params.sessionId;
    if (sessionId.startsWith("queue_"))
        return;
    const beforeStatus = (_e = beforeData.status) === null || _e === void 0 ? void 0 : _e.toString();
    const afterStatus = (_f = afterData.status) === null || _f === void 0 ? void 0 : _f.toString();
    if (afterStatus !== "pending")
        return;
    if (beforeStatus === "rejected" || beforeStatus === "expired")
        return;
    const userA = ((_g = afterData.userA) !== null && _g !== void 0 ? _g : "").toString();
    const userB = ((_h = afterData.userB) !== null && _h !== void 0 ? _h : "").toString();
    const responses = ((_j = afterData.responses) !== null && _j !== void 0 ? _j : {});
    const rejected = ((_k = responses[userA]) === null || _k === void 0 ? void 0 : _k.toString()) === "rejected" ||
        ((_l = responses[userB]) === null || _l === void 0 ? void 0 : _l.toString()) === "rejected";
    if (!rejected)
        return;
    console.log("auto-match response rejected", { sessionId });
    await db.runTransaction(async (tx) => {
        var _a, _b;
        const ref = db.collection("match_sessions").doc(sessionId);
        const snap = await tx.get(ref);
        if (!snap.exists)
            return;
        const data = (_a = snap.data()) !== null && _a !== void 0 ? _a : {};
        const status = (_b = data.status) === null || _b === void 0 ? void 0 : _b.toString();
        if (status !== "pending")
            return;
        tx.set(ref, {
            status: "rejected",
            respondedAt: firestore_2.FieldValue.serverTimestamp(),
            updatedAt: firestore_2.FieldValue.serverTimestamp(),
        }, { merge: true });
    });
});
exports.onAutoMatchSessionSearching = (0, firestore_1.onDocumentWritten)({
    document: "match_sessions/{sessionId}",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
}, async (event) => {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    const beforeSnap = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before;
    const afterSnap = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after;
    if (!afterSnap || !afterSnap.exists)
        return;
    // Extract once to avoid redeclaration bugs.
    const beforeData = (_c = beforeSnap === null || beforeSnap === void 0 ? void 0 : beforeSnap.data()) !== null && _c !== void 0 ? _c : {};
    const afterData = (_d = afterSnap.data()) !== null && _d !== void 0 ? _d : {};
    const sessionId = event.params.sessionId;
    if (!sessionId.startsWith("queue_")) {
        console.log("auto-match skip: not queue doc", { sessionId });
        return;
    }
    const afterStatus = (_e = afterData.status) === null || _e === void 0 ? void 0 : _e.toString();
    const beforeStatus = (_f = beforeData.status) === null || _f === void 0 ? void 0 : _f.toString();
    const mode = (_g = afterData.mode) === null || _g === void 0 ? void 0 : _g.toString();
    console.log("auto-match entry", {
        sessionId,
        mode,
        beforeStatus,
        afterStatus,
    });
    if (beforeStatus === afterStatus) {
        console.log("auto-match skip: status unchanged", {
            sessionId,
            beforeStatus,
            afterStatus,
        });
        return;
    }
    // Only react to auto queue sessions transitioning into searching.
    // If pairing never creates a pending {uidA}_{uidB} doc, the UI never sees match found.
    if (mode !== "auto") {
        console.log("auto-match skip: mode not auto", { sessionId, mode });
        return;
    }
    if (afterStatus !== "searching") {
        console.log("auto-match skip: status not searching", {
            sessionId,
            afterStatus,
        });
        return;
    }
    const userA = ((_h = afterData.userA) !== null && _h !== void 0 ? _h : "").toString();
    if (!userA) {
        console.log("auto-match skip: missing userA", { sessionId });
        return;
    }
    console.log("auto-match attempt start", { userA });
    const candidates = await db
        .collection("match_sessions")
        .where("mode", "==", "auto")
        .where("status", "==", "searching")
        .limit(20)
        .get();
    let matched = false;
    for (const doc of candidates.docs) {
        if (doc.id === afterSnap.id)
            continue;
        if (!doc.id.startsWith("queue_"))
            continue;
        if (matched)
            break;
        matched = await tryPairQueues(afterSnap.ref, doc.ref, userA);
    }
    if (!matched) {
        console.log("auto-match: no eligible partner");
    }
    else {
        console.log("auto-match: paired successfully", { userA });
    }
});
exports.cleanupQueueDocs = (0, scheduler_1.onSchedule)({
    schedule: "every 1 minutes",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
}, async () => {
    var _a;
    const prefixStart = "queue_";
    const prefixEnd = "queue_~";
    let lastDoc = null;
    while (true) {
        let query = db
            .collection("match_sessions")
            .orderBy(firestore_2.FieldPath.documentId())
            .where(firestore_2.FieldPath.documentId(), ">=", prefixStart)
            .where(firestore_2.FieldPath.documentId(), "<", prefixEnd)
            .limit(200);
        if (lastDoc) {
            query = query.startAfter(lastDoc);
        }
        const snapshot = await query.get();
        if (snapshot.empty)
            break;
        const batch = db.batch();
        for (const doc of snapshot.docs) {
            const data = (_a = doc.data()) !== null && _a !== void 0 ? _a : {};
            const updates = {};
            if ("userB" in data)
                updates.userB = firestore_2.FieldValue.delete();
            if ("participants" in data)
                updates.participants = firestore_2.FieldValue.delete();
            if ("ready" in data)
                updates.ready = firestore_2.FieldValue.delete();
            if ("cancelledBy" in data)
                updates.cancelledBy = firestore_2.FieldValue.delete();
            if ("connectedAt" in data)
                updates.connectedAt = firestore_2.FieldValue.delete();
            if (Object.keys(updates).length > 0) {
                batch.set(doc.ref, updates, { merge: true });
            }
        }
        await batch.commit();
        lastDoc = snapshot.docs[snapshot.docs.length - 1];
    }
});
async function tryPairQueues(queueARef, queueBRef, initiatedBy) {
    const expiresAt = firestore_2.Timestamp.fromMillis(Date.now() + 10 * 1000);
    let paired = false;
    await db.runTransaction(async (tx) => {
        var _a, _b, _c, _d, _e, _f, _g, _h;
        const [queueASnap, queueBSnap] = await Promise.all([
            tx.get(queueARef),
            tx.get(queueBRef),
        ]);
        if (!queueASnap.exists || !queueBSnap.exists) {
            console.log("auto-match skip: queue missing");
            return;
        }
        const queueAData = (_a = queueASnap.data()) !== null && _a !== void 0 ? _a : {};
        const queueBData = (_b = queueBSnap.data()) !== null && _b !== void 0 ? _b : {};
        if (((_c = queueAData.status) === null || _c === void 0 ? void 0 : _c.toString()) !== "searching") {
            console.log("auto-match skip: queueA not searching");
            return;
        }
        if (((_d = queueBData.status) === null || _d === void 0 ? void 0 : _d.toString()) !== "searching") {
            console.log("auto-match skip: queueB not searching");
            return;
        }
        if (((_e = queueAData.mode) === null || _e === void 0 ? void 0 : _e.toString()) !== "auto") {
            console.log("auto-match skip: queueA not auto");
            return;
        }
        if (((_f = queueBData.mode) === null || _f === void 0 ? void 0 : _f.toString()) !== "auto") {
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
        const userAId = ((_g = queueAData.userA) !== null && _g !== void 0 ? _g : "").toString();
        const userBId = ((_h = queueBData.userA) !== null && _h !== void 0 ? _h : "").toString();
        if (!userAId || !userBId || userAId === userBId) {
            console.log("auto-match skip: invalid users", { userAId, userBId });
            return;
        }
        const hydratedA = await hydrateQueueUser(tx, userAId, queueAData);
        const hydratedB = await hydrateQueueUser(tx, userBId, queueBData);
        if (!hydratedA || !hydratedB) {
            console.log("auto-match skip: hydrate failed");
            return;
        }
        console.log("auto-match eligible users", { userAId, userBId });
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
            console.log("auto-match skip: pair already exists", { pairSessionId });
            return;
        }
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
            createdAt: firestore_2.FieldValue.serverTimestamp(),
            respondedAt: null,
            expiresAt,
            updatedAt: firestore_2.FieldValue.serverTimestamp(),
        });
        console.log("auto-match created match_session", { pairSessionId });
        tx.set(notifARef, {
            type: "match",
            fromUid: ids[1],
            refId: pairSessionId,
            seen: false,
            createdAt: firestore_2.FieldValue.serverTimestamp(),
        });
        tx.set(notifBRef, {
            type: "match",
            fromUid: ids[0],
            refId: pairSessionId,
            seen: false,
            createdAt: firestore_2.FieldValue.serverTimestamp(),
        });
        tx.set(queueARef, { status: "idle", updatedAt: firestore_2.FieldValue.serverTimestamp() }, { merge: true });
        tx.set(queueBRef, { status: "idle", updatedAt: firestore_2.FieldValue.serverTimestamp() }, { merge: true });
        console.log("auto-match paired", { pairSessionId });
        paired = true;
    });
    return paired;
}
exports.onMatchSessionRejectedOrExpired = (0, firestore_1.onDocumentWritten)({
    document: "match_sessions/{sessionId}",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
}, async (event) => {
    var _a, _b, _c, _d, _e, _f;
    const beforeSnap = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before;
    const afterSnap = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after;
    if (!afterSnap || !afterSnap.exists)
        return;
    // Extract once to avoid redeclaration bugs.
    const beforeData = (_c = beforeSnap === null || beforeSnap === void 0 ? void 0 : beforeSnap.data()) !== null && _c !== void 0 ? _c : {};
    const afterData = (_d = afterSnap.data()) !== null && _d !== void 0 ? _d : {};
    const sessionId = event.params.sessionId;
    if (sessionId.startsWith("queue_"))
        return;
    const afterStatus = (_e = afterData.status) === null || _e === void 0 ? void 0 : _e.toString();
    const beforeStatus = (_f = beforeData.status) === null || _f === void 0 ? void 0 : _f.toString();
    if (afterStatus !== "expired" && afterStatus !== "rejected")
        return;
    if (beforeStatus === afterStatus)
        return;
    console.log("auto-match rejected/expired: client should requeue", {
        sessionId,
        afterStatus,
    });
});
async function hydrateQueueUser(tx, userId, queueData) {
    var _a, _b, _c;
    let interests = ((_a = queueData.interests) !== null && _a !== void 0 ? _a : []);
    let location = queueData.location;
    let radiusKm = Number(queueData.radiusKm);
    if (!Array.isArray(interests) ||
        interests.length === 0 ||
        !location ||
        !Number.isFinite(radiusKm) ||
        radiusKm <= 0) {
        const userSnap = await tx.get(db.collection("users").doc(userId));
        const userData = (_b = userSnap.data()) !== null && _b !== void 0 ? _b : {};
        interests = ((_c = userData.interests) !== null && _c !== void 0 ? _c : []);
        location = userData.location;
        const fallbackRadius = Number(userData.distanceKm);
        radiusKm = Number.isFinite(fallbackRadius) && fallbackRadius > 0
            ? fallbackRadius
            : radiusKm;
        const normalizedInterests = normalizeInterests(interests);
        if (normalizedInterests.length > 0 &&
            location &&
            Number.isFinite(radiusKm) &&
            radiusKm > 0) {
            tx.set(db.collection("match_sessions").doc(`queue_${userId}`), {
                interests: normalizedInterests,
                location,
                radiusKm,
                updatedAt: firestore_2.FieldValue.serverTimestamp(),
            }, { merge: true });
        }
    }
    const normalizedInterests = normalizeInterests(interests);
    if (normalizedInterests.length === 0 ||
        !location ||
        !Number.isFinite(radiusKm) ||
        radiusKm <= 0) {
        return null;
    }
    return {
        interests: normalizedInterests,
        location,
        radiusKm,
    };
}
function hasCommonInterest(a, b) {
    if (a.length === 0 || b.length === 0)
        return false;
    const set = new Set(a);
    return b.some((interest) => set.has(interest));
}
function distanceBetweenKm(a, b) {
    if (!a || !b)
        return null;
    const toRad = (value) => (value * Math.PI) / 180;
    const radius = 6371;
    const dLat = toRad(b.latitude - a.latitude);
    const dLon = toRad(b.longitude - a.longitude);
    const lat1 = toRad(a.latitude);
    const lat2 = toRad(b.latitude);
    const h = Math.sin(dLat / 2) ** 2 +
        Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
    return radius * 2 * Math.asin(Math.sqrt(h));
}
function normalizeInterests(input) {
    return input
        .map((item) => (typeof item === "string" ? item : item === null || item === void 0 ? void 0 : item.toString()))
        .filter((value) => typeof value === "string" && value.length > 0);
}
async function requeueUser(userId) {
    var _a, _b;
    if (!userId)
        return;
    const userSnap = await db.collection("users").doc(userId).get();
    const userData = (_a = userSnap.data()) !== null && _a !== void 0 ? _a : {};
    const interests = normalizeInterests(((_b = userData.interests) !== null && _b !== void 0 ? _b : []));
    const location = userData.location;
    const radiusKm = Number(userData.distanceKm);
    if (!location || interests.length === 0 || !Number.isFinite(radiusKm) || radiusKm <= 0) {
        return;
    }
    await db.collection("match_sessions").doc(`queue_${userId}`).set({
        userA: userId,
        interests,
        location,
        radiusKm,
        mode: "auto",
        status: "searching",
        createdAt: firestore_2.FieldValue.serverTimestamp(),
        expiresAt: firestore_2.Timestamp.fromMillis(Date.now() + 5 * 60 * 1000),
        updatedAt: firestore_2.FieldValue.serverTimestamp(),
    }, { merge: true });
}
exports.onMatchSessionAcceptedNotification = (0, firestore_1.onDocumentWritten)({
    document: "match_sessions/{sessionId}",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
}, async (event) => {
    var _a, _b, _c, _d, _e, _f, _g;
    const beforeSnap = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before;
    const afterSnap = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after;
    if (!afterSnap || !afterSnap.exists)
        return;
    // Extract once to avoid redeclaration bugs.
    const beforeData = (_c = beforeSnap === null || beforeSnap === void 0 ? void 0 : beforeSnap.data()) !== null && _c !== void 0 ? _c : {};
    const afterData = (_d = afterSnap.data()) !== null && _d !== void 0 ? _d : {};
    const beforeStatus = (_e = beforeData.status) === null || _e === void 0 ? void 0 : _e.toString();
    const afterStatus = (_f = afterData.status) === null || _f === void 0 ? void 0 : _f.toString();
    if (beforeStatus === "accepted" || afterStatus !== "accepted")
        return;
    const sessionId = event.params.sessionId;
    const chatRoomId = ((_g = afterData.chatRoomId) === null || _g === void 0 ? void 0 : _g.toString()) || sessionId;
    // Idempotency: mark notified.accepted once to prevent duplicates.
    const shouldSend = await markMatchAcceptedNotified(sessionId);
    if (!shouldSend)
        return;
    const recipients = getParticipants(afterData);
    const records = await resolveDeviceTokens(recipients);
    if (records.length === 0)
        return;
    await sendMulticast(records, {
        notification: {
            title: "💞 매칭이 완료됐어요",
            body: "지금 대화를 시작해보세요",
        },
        data: { type: "match_accepted",
            sessionId,
            chatRoomId,
        },
    });
});
exports.onChatMessageCreatedNotification = (0, firestore_1.onDocumentCreated)({
    document: "chat_rooms/{roomId}/messages/{messageId}",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
}, async (event) => {
    var _a, _b, _c, _d;
    const messageSnap = event.data;
    if (!(messageSnap === null || messageSnap === void 0 ? void 0 : messageSnap.exists))
        return;
    const roomId = event.params.roomId;
    const messageId = event.params.messageId;
    const messageData = (_a = messageSnap.data()) !== null && _a !== void 0 ? _a : {};
    if (messageData.notified === true)
        return;
    // Idempotency: mark notified once per message before sending.
    const shouldSend = await markMessageNotified(roomId, messageId);
    if (!shouldSend)
        return;
    const senderId = ((_b = messageData.senderId) !== null && _b !== void 0 ? _b : "").toString();
    if (!senderId)
        return;
    const roomSnap = await db.collection("chat_rooms").doc(roomId).get();
    const roomData = (_c = roomSnap.data()) !== null && _c !== void 0 ? _c : {};
    const participants = ((_d = roomData.participants) !== null && _d !== void 0 ? _d : []);
    const recipients = participants
        .map((id) => id === null || id === void 0 ? void 0 : id.toString())
        .filter((id) => id && id !== senderId);
    if (recipients.length === 0)
        return;
    const records = await resolveDeviceTokens(recipients);
    if (records.length === 0)
        return;
    await sendMulticast(records, {
        notification: {
            title: "💬 새 메시지",
            body: "메시지가 도착했어요",
        },
        data: { type: "new_message",
            roomId,
            messageId,
            senderId,
        },
    });
});
exports.onChatRoomEnded = (0, firestore_1.onDocumentWritten)({
    document: "chat_rooms/{roomId}",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
}, async (event) => {
    var _a, _b, _c, _d, _e, _f;
    const beforeSnap = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before;
    const afterSnap = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after;
    if (!afterSnap || !afterSnap.exists)
        return;
    // Extract once to avoid redeclaration bugs.
    const beforeData = (_c = beforeSnap === null || beforeSnap === void 0 ? void 0 : beforeSnap.data()) !== null && _c !== void 0 ? _c : {};
    const afterData = (_d = afterSnap.data()) !== null && _d !== void 0 ? _d : {};
    const roomId = event.params.roomId;
    const beforeEndedBy = ((_e = beforeData.endedBy) !== null && _e !== void 0 ? _e : "").toString();
    const afterEndedBy = ((_f = afterData.endedBy) !== null && _f !== void 0 ? _f : "").toString();
    if (!afterEndedBy)
        return;
    if (!beforeEndedBy) {
        await db
            .collection("chat_rooms")
            .doc(roomId)
            .collection("messages")
            .add({
            senderId: "system",
            text: "상대가 채팅을 종료했습니다",
            createdAt: firestore_2.FieldValue.serverTimestamp(),
        });
        return;
    }
    if (beforeEndedBy && afterEndedBy && beforeEndedBy !== afterEndedBy) {
        await deleteChatRoomWithMessages(roomId);
    }
});
async function deleteChatRoomWithMessages(roomId) {
    const roomRef = db.collection("chat_rooms").doc(roomId);
    const messagesRef = roomRef.collection("messages");
    while (true) {
        const snapshot = await messagesRef.limit(200).get();
        if (snapshot.empty)
            break;
        const batch = db.batch();
        for (const doc of snapshot.docs) {
            batch.delete(doc.ref);
        }
        await batch.commit();
    }
    await roomRef.delete();
}
async function markMatchAcceptedNotified(sessionId) {
    const sessionRef = db.collection("match_sessions").doc(sessionId);
    let shouldSend = false;
    await db.runTransaction(async (tx) => {
        var _a, _b;
        const snap = await tx.get(sessionRef);
        if (!snap.exists)
            return;
        const data = (_a = snap.data()) !== null && _a !== void 0 ? _a : {};
        const notified = ((_b = data.notified) !== null && _b !== void 0 ? _b : {});
        if (notified.accepted === true)
            return;
        tx.set(sessionRef, {
            notified: Object.assign(Object.assign({}, notified), { accepted: true, acceptedAt: firestore_2.FieldValue.serverTimestamp() }),
        }, { merge: true });
        shouldSend = true;
    });
    return shouldSend;
}
async function markMessageNotified(roomId, messageId) {
    const messageRef = db
        .collection("chat_rooms")
        .doc(roomId)
        .collection("messages")
        .doc(messageId);
    let shouldSend = false;
    await db.runTransaction(async (tx) => {
        var _a;
        const snap = await tx.get(messageRef);
        if (!snap.exists)
            return;
        const data = (_a = snap.data()) !== null && _a !== void 0 ? _a : {};
        if (data.notified === true)
            return;
        tx.set(messageRef, {
            notified: true,
            notifiedAt: firestore_2.FieldValue.serverTimestamp(),
        }, { merge: true });
        shouldSend = true;
    });
    return shouldSend;
}
function getParticipants(data) {
    var _a, _b;
    const userA = ((_a = data.userA) !== null && _a !== void 0 ? _a : "").toString();
    const userB = ((_b = data.userB) !== null && _b !== void 0 ? _b : "").toString();
    return [userA, userB].filter((id) => id.trim().length > 0);
}
async function resolveDeviceTokens(userIds) {
    const tokenSets = await Promise.all(userIds.map(async (uid) => {
        var _a;
        const userSnap = await db.collection("users").doc(uid).get();
        const userData = (_a = userSnap.data()) !== null && _a !== void 0 ? _a : {};
        if (userData.notificationsEnabled === false)
            return [];
        const devicesSnap = await db
            .collection("users")
            .doc(uid)
            .collection("devices")
            .where("enabled", "==", true)
            .get();
        return devicesSnap.docs
            .map((doc) => {
            var _a, _b, _c;
            const data = (_a = doc.data()) !== null && _a !== void 0 ? _a : {};
            const token = (_c = (_b = data.token) === null || _b === void 0 ? void 0 : _b.toString()) !== null && _c !== void 0 ? _c : "";
            if (!token)
                return null;
            return { token, deviceRef: doc.ref };
        })
            .filter((record) => record !== null);
    }));
    return tokenSets.flat();
}
async function sendMulticast(records, message) {
    const tokens = records.map((r) => r.token);
    const response = await messaging.sendEachForMulticast({
        tokens,
        notification: message.notification,
        data: message.data,
    });
    const invalidRefs = [];
    response.responses.forEach((res, index) => {
        var _a, _b;
        if (res.success)
            return;
        const code = (_b = (_a = res.error) === null || _a === void 0 ? void 0 : _a.code) !== null && _b !== void 0 ? _b : "";
        if (code === "messaging/invalid-registration-token" ||
            code === "messaging/registration-token-not-registered") {
            invalidRefs.push(records[index].deviceRef);
        }
    });
    if (invalidRefs.length > 0) {
        const batch = db.batch();
        for (const ref of invalidRefs) {
            batch.set(ref, { enabled: false, updatedAt: firestore_2.FieldValue.serverTimestamp() }, { merge: true });
        }
        await batch.commit();
    }
}
//# sourceMappingURL=index.js.map