"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onChatMessageCreatedNotification = exports.onMatchSessionAcceptedNotification = exports.cleanupQueueDocs = exports.onAutoMatchSessionSearching = exports.onMatchSessionAccepted = exports.expireMatchSessions = void 0;
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
    // Expire both pending/searching auto sessions to avoid idle buildup.
    const statuses = ["pending", "searching"];
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
            batch.set(doc.ref, {
                status: "expired",
                updatedAt: firestore_2.FieldValue.serverTimestamp(),
            }, { merge: true });
        }
        await batch.commit();
    }
});
exports.onMatchSessionAccepted = (0, firestore_1.onDocumentWritten)("match_sessions/{sessionId}", async (event) => {
    var _a, _b, _c, _d, _e, _f;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before;
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after;
    if (!after || !after.exists)
        return;
    const beforeStatus = (_d = (_c = before === null || before === void 0 ? void 0 : before.data()) === null || _c === void 0 ? void 0 : _c.status) === null || _d === void 0 ? void 0 : _d.toString();
    const afterData = (_e = after.data()) !== null && _e !== void 0 ? _e : {};
    const afterStatus = (_f = afterData.status) === null || _f === void 0 ? void 0 : _f.toString();
    if (beforeStatus === "accepted" || afterStatus !== "accepted")
        return;
    const sessionId = event.params.sessionId;
    const sessionRef = db.collection("match_sessions").doc(sessionId);
    const roomRef = db.collection("chat_rooms").doc(sessionId);
    await db.runTransaction(async (tx) => {
        var _a, _b, _c, _d, _e, _f;
        const sessionSnap = await tx.get(sessionRef);
        if (!sessionSnap.exists)
            return;
        const data = (_a = sessionSnap.data()) !== null && _a !== void 0 ? _a : {};
        if (((_b = data.status) === null || _b === void 0 ? void 0 : _b.toString()) !== "accepted")
            return;
        if (data.chatRoomId != null)
            return;
        const userA = ((_c = data.userA) !== null && _c !== void 0 ? _c : "").toString();
        const userB = ((_d = data.userB) !== null && _d !== void 0 ? _d : "").toString();
        const participants = [userA, userB].filter((id) => id.trim().length > 0);
        if (participants.length < 2)
            return;
        const mode = (_f = (_e = data.mode) === null || _e === void 0 ? void 0 : _e.toString()) !== null && _f !== void 0 ? _f : null;
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
        }, { merge: true });
    });
});
exports.onAutoMatchSessionSearching = (0, firestore_1.onDocumentWritten)({
    document: "match_sessions/{sessionId}",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
}, async (event) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j;
    const after = (_a = event.data) === null || _a === void 0 ? void 0 : _a.after;
    const before = (_b = event.data) === null || _b === void 0 ? void 0 : _b.before;
    if (!after || !after.exists)
        return;
    const sessionId = event.params.sessionId;
    if (!sessionId.startsWith("queue_"))
        return;
    const afterData = (_c = after.data()) !== null && _c !== void 0 ? _c : {};
    const afterStatus = (_d = afterData.status) === null || _d === void 0 ? void 0 : _d.toString();
    const beforeStatus = (_f = (_e = before === null || before === void 0 ? void 0 : before.data()) === null || _e === void 0 ? void 0 : _e.status) === null || _f === void 0 ? void 0 : _f.toString();
    const mode = (_g = afterData.mode) === null || _g === void 0 ? void 0 : _g.toString();
    // Only react to auto queue sessions transitioning into searching.
    if (mode !== "auto")
        return;
    if (afterStatus !== "searching")
        return;
    if (beforeStatus === "searching")
        return;
    const userA = ((_h = afterData.userA) !== null && _h !== void 0 ? _h : "").toString();
    if (!userA)
        return;
    console.log("auto-match attempt start", { userA });
    const candidates = await db
        .collection("match_sessions")
        .where("mode", "==", "auto")
        .where("status", "==", "searching")
        .limit(20)
        .get();
    const partnerDoc = candidates.docs.find((doc) => {
        var _a, _b, _c;
        if (doc.id === after.id)
            return false;
        if (!doc.id.startsWith("queue_"))
            return false;
        const data = (_a = doc.data()) !== null && _a !== void 0 ? _a : {};
        const otherUserA = ((_b = data.userA) !== null && _b !== void 0 ? _b : "").toString();
        const otherUserB = ((_c = data.userB) !== null && _c !== void 0 ? _c : "").toString();
        if (otherUserB.trim().length > 0)
            return false;
        return otherUserA && otherUserA !== userA;
    });
    if (!partnerDoc) {
        console.log("auto-match: no eligible partner");
        return;
    }
    const otherUserA = ((_j = partnerDoc.data().userA) !== null && _j !== void 0 ? _j : "").toString();
    if (!otherUserA || otherUserA === userA)
        return;
    const ids = [userA, otherUserA].sort();
    const pairSessionId = `${ids[0]}_${ids[1]}`;
    const pairRef = db.collection("match_sessions").doc(pairSessionId);
    const expiresAt = firestore_2.Timestamp.fromDate(new Date(Date.now() + 5 * 60 * 1000));
    await db.runTransaction(async (tx) => {
        var _a, _b, _c, _d, _e, _f, _g, _h;
        const currentSnap = await tx.get(after.ref);
        const partnerSnap = await tx.get(partnerDoc.ref);
        if (!currentSnap.exists || !partnerSnap.exists)
            return;
        const currentData = (_a = currentSnap.data()) !== null && _a !== void 0 ? _a : {};
        const partnerData = (_b = partnerSnap.data()) !== null && _b !== void 0 ? _b : {};
        if (((_c = currentData.status) === null || _c === void 0 ? void 0 : _c.toString()) !== "searching")
            return;
        if (((_d = partnerData.status) === null || _d === void 0 ? void 0 : _d.toString()) !== "searching")
            return;
        const currentUserA = ((_e = currentData.userA) !== null && _e !== void 0 ? _e : "").toString();
        const partnerUserA = ((_f = partnerData.userA) !== null && _f !== void 0 ? _f : "").toString();
        if (!currentUserA || !partnerUserA)
            return;
        if (currentUserA === partnerUserA)
            return;
        const currentUserB = ((_g = currentData.userB) !== null && _g !== void 0 ? _g : "").toString();
        const partnerUserB = ((_h = partnerData.userB) !== null && _h !== void 0 ? _h : "").toString();
        if (currentUserB.trim().length > 0 || partnerUserB.trim().length > 0) {
            return;
        }
        const pairSnap = await tx.get(pairRef);
        if (pairSnap.exists)
            return;
        tx.set(pairRef, {
            userA: ids[0],
            userB: ids[1],
            mode: "auto",
            status: "pending",
            initiatedBy: userA,
            chatRoomId: null,
            createdAt: firestore_2.FieldValue.serverTimestamp(),
            respondedAt: null,
            expiresAt,
            updatedAt: firestore_2.FieldValue.serverTimestamp(),
        });
        // Remove both users from the queue to prevent duplicate matches.
        tx.set(after.ref, { status: "expired", updatedAt: firestore_2.FieldValue.serverTimestamp() }, { merge: true });
        tx.set(partnerDoc.ref, { status: "expired", updatedAt: firestore_2.FieldValue.serverTimestamp() }, { merge: true });
    });
    console.log("auto-match: paired", { userA, otherUserA, pairSessionId });
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
exports.onMatchSessionAcceptedNotification = (0, firestore_1.onDocumentWritten)({
    document: "match_sessions/{sessionId}",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
}, async (event) => {
    var _a, _b, _c, _d, _e, _f, _g;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before;
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after;
    if (!after || !after.exists)
        return;
    const beforeStatus = (_d = (_c = before === null || before === void 0 ? void 0 : before.data()) === null || _c === void 0 ? void 0 : _c.status) === null || _d === void 0 ? void 0 : _d.toString();
    const afterData = (_e = after.data()) !== null && _e !== void 0 ? _e : {};
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
        data: {
            type: "match_accepted",
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
        data: {
            type: "new_message",
            roomId,
            messageId,
            senderId,
        },
    });
});
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