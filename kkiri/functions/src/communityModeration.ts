import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {onDocumentCreated} from "firebase-functions/v2/firestore";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

function toSafeReasonKey(value: string): string {
  const valueTrimmed = value.trim();
  if (!valueTrimmed) return "Unknown";
  return valueTrimmed.replace(/[./#[\]$]/g, "_");
}

export const onCommunityPostReportCreated = onDocumentCreated(
  "community/apps/main/root/posts/{postId}/reports/{reporterUid}",
  async (event) => {
    const reportSnap = event.data;
    if (!reportSnap) return;

    const postId = event.params.postId;
    const reporterUid = event.params.reporterUid;
    if (!postId || !reporterUid) return;

    const reportData = reportSnap.data();
    const rawReason = reportData?.reason;
    const reason = typeof rawReason === "string" ? rawReason : "Unknown";
    const reasonKey = toSafeReasonKey(reason);

    const postRef = db.doc(`community/apps/main/root/posts/${postId}`);
    const reportRef = postRef.collection("reports").doc(reporterUid);

    try {
      await db.runTransaction(async (transaction) => {
        const currentReportSnap = await transaction.get(reportRef);
        if (!currentReportSnap.exists) return;

        const currentReportData = currentReportSnap.data() ?? {};
        if (currentReportData.moderationProcessed === true) return;

        const postSnap = await transaction.get(postRef);
        if (!postSnap.exists) {
          transaction.set(
            reportRef,
            {
              moderationProcessed: true,
              moderationProcessedAt: admin.firestore.FieldValue.serverTimestamp(),
              moderationSkippedReason: "post_missing",
            },
            {merge: true},
          );
          return;
        }

        const postData = postSnap.data() ?? {};
        const rawAuthorUid = postData.authorUid;
        const authorUid = typeof rawAuthorUid === "string" ? rawAuthorUid.trim() : "";

        const reportsSnapshot = await transaction.get(postRef.collection("reports"));
        const reportCount = reportsSnapshot.size;
        transaction.set(
          postRef,
          {
            reportCount,
            isHidden: reportCount >= 3,
          },
          {merge: true},
        );

        if (authorUid) {
          const moderationRef = db.collection("user_moderation").doc(authorUid);
          const moderationSnap = await transaction.get(moderationRef);

          if (!moderationSnap.exists) {
            transaction.set(
              moderationRef,
              {
                totalReports: 1,
                level: 0,
                reasonCounts: {[reasonKey]: 1},
              },
              {merge: true},
            );
          } else {
            const moderationData = moderationSnap.data() ?? {};
            const rawTotalReports = moderationData.totalReports;
            const currentTotalReports =
              typeof rawTotalReports === "number" ? rawTotalReports : 0;
            const nextTotalReports = currentTotalReports + 1;

            let level = 0;
            if (nextTotalReports >= 6) {
              level = 2;
            } else if (nextTotalReports >= 3) {
              level = 1;
            }

            transaction.set(
              moderationRef,
              {
                totalReports: admin.firestore.FieldValue.increment(1),
                level,
                [`reasonCounts.${reasonKey}`]: admin.firestore.FieldValue.increment(1),
              },
              {merge: true},
            );
          }
        }

        transaction.set(
          reportRef,
          {
            moderationProcessed: true,
            moderationProcessedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          {merge: true},
        );
      });
    } catch (error) {
      logger.error("onCommunityPostReportCreated failed", {
        postId,
        reporterUid,
        error,
      });
    }
  },
);

export const onCommunityCommentReportCreated = onDocumentCreated(
  "community/apps/main/root/posts/{postId}/comments/{commentId}/reports/{reporterUid}",
  async (event) => {
    const reportSnap = event.data;
    if (!reportSnap) return;

    const postId = event.params.postId;
    const commentId = event.params.commentId;
    const reporterUid = event.params.reporterUid;
    if (!postId || !commentId || !reporterUid) return;

    const reportData = reportSnap.data();
    const rawReason = reportData?.reason;
    const reason = typeof rawReason === "string" ? rawReason : "Unknown";
    const reasonKey = toSafeReasonKey(reason);

    const commentRef = db.doc(
      `community/apps/main/root/posts/${postId}/comments/${commentId}`,
    );
    const reportRef = commentRef.collection("reports").doc(reporterUid);

    try {
      await db.runTransaction(async (transaction) => {
        const currentReportSnap = await transaction.get(reportRef);
        if (!currentReportSnap.exists) return;

        const currentReportData = currentReportSnap.data() ?? {};
        if (currentReportData.moderationProcessed === true) return;

        const commentSnap = await transaction.get(commentRef);
        if (!commentSnap.exists) {
          transaction.set(
            reportRef,
            {
              moderationProcessed: true,
              moderationProcessedAt: admin.firestore.FieldValue.serverTimestamp(),
              moderationSkippedReason: "comment_missing",
            },
            {merge: true},
          );
          return;
        }

        const commentData = commentSnap.data() ?? {};
        const rawAuthorUid = commentData.authorUid;
        const authorUid = typeof rawAuthorUid === "string" ? rawAuthorUid.trim() : "";

        const reportsSnapshot = await transaction.get(commentRef.collection("reports"));
        const reportCount = reportsSnapshot.size;
        transaction.set(
          commentRef,
          {
            reportCount,
            isHidden: reportCount >= 3,
          },
          {merge: true},
        );

        if (authorUid) {
          const moderationRef = db.collection("user_moderation").doc(authorUid);
          const moderationSnap = await transaction.get(moderationRef);

          if (!moderationSnap.exists) {
            transaction.set(
              moderationRef,
              {
                totalReports: 1,
                level: 0,
                reasonCounts: {[reasonKey]: 1},
              },
              {merge: true},
            );
          } else {
            const moderationData = moderationSnap.data() ?? {};
            const rawTotalReports = moderationData.totalReports;
            const currentTotalReports =
              typeof rawTotalReports === "number" ? rawTotalReports : 0;
            const nextTotalReports = currentTotalReports + 1;

            let level = 0;
            if (nextTotalReports >= 6) {
              level = 2;
            } else if (nextTotalReports >= 3) {
              level = 1;
            }

            transaction.set(
              moderationRef,
              {
                totalReports: admin.firestore.FieldValue.increment(1),
                level,
                [`reasonCounts.${reasonKey}`]: admin.firestore.FieldValue.increment(1),
              },
              {merge: true},
            );
          }
        }

        transaction.set(
          reportRef,
          {
            moderationProcessed: true,
            moderationProcessedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          {merge: true},
        );
      });
    } catch (error) {
      logger.error("onCommunityCommentReportCreated failed", {
        postId,
        commentId,
        reporterUid,
        error,
      });
    }
  },
);
