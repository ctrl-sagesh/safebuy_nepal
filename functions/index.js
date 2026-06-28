/**
 * SafeBuy Nepal — Firebase Cloud Functions
 *
 * Automated trust-score recalculation, fraud-pattern detection,
 * push notifications, and scheduled maintenance tasks.
 *
 * Project: BSc (Hons) Ethical Hacking & Cybersecurity Thesis
 * Author:  Sagesh Adhikari — Softwarica College / Coventry University
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// ═══════════════════════════════════════════════════════════════
// HELPER — Recalculate Trust Score
// ═══════════════════════════════════════════════════════════════

async function recalculateTrustScore(sellerId) {
  const sellerRef = db.collection("sellers").doc(sellerId);
  const sellerSnap = await sellerRef.get();
  if (!sellerSnap.exists) return null;

  const seller = sellerSnap.data();

  // Fetch non-false-flagged reports
  const reportsSnap = await db
    .collection("reports")
    .where("sellerId", "==", sellerId)
    .where("status", "!=", "false_flag")
    .get();

  // Fetch reviews
  const reviewsSnap = await db
    .collection("reviews")
    .where("sellerId", "==", sellerId)
    .get();

  // --- Calculate score ---
  let score = 100.0;

  // Factor 1: Report severity (40% weight area)
  reportsSnap.forEach((doc) => {
    const report = doc.data();
    const amountLost = report.amountLost || 0;
    const basePenalty = Math.min(amountLost / 1000, 30);

    const incidentDate = report.incidentDate
      ? report.incidentDate.toDate()
      : new Date();
    const daysSince = Math.floor(
      (Date.now() - incidentDate.getTime()) / (1000 * 60 * 60 * 24)
    );

    let recency = 0.4;
    if (daysSince < 30) recency = 1.0;
    else if (daysSince < 90) recency = 0.7;

    score -= basePenalty * recency;
  });

  score = Math.max(score, 60);

  // Factor 2: Verification status (25% weight area)
  const isVerified = seller.isVerified === true;
  const hasSocialLink =
    (seller.tiktokHandle && seller.tiktokHandle.length > 0) ||
    (seller.instagramHandle && seller.instagramHandle.length > 0) ||
    (seller.facebookHandle && seller.facebookHandle.length > 0);

  if (isVerified && hasSocialLink) {
    score += 25;
  } else if (isVerified) {
    score += 15;
  }

  // Factor 3: Review authenticity (20% weight area)
  if (!reviewsSnap.empty) {
    let weightedSum = 0;
    let totalWeight = 0;

    reviewsSnap.forEach((doc) => {
      const review = doc.data();
      const rating = review.rating || 3;
      const authWeight = review.authenticityWeight || 1.0;
      weightedSum += rating * authWeight;
      totalWeight += authWeight;
    });

    if (totalWeight > 0) {
      const avgRating = weightedSum / totalWeight;
      score += (avgRating / 5) * 20;
    }
  }

  // Factor 4: Dispute resolution (10% weight area)
  const disputeResponseRate = seller.disputeResponseRate || 0;
  if (disputeResponseRate > 0.8) {
    score += 10;
  } else if (disputeResponseRate > 0.5) {
    score += 5;
  }

  // Factor 5: Account age (5% weight area)
  const accountCreated = seller.accountCreatedAt
    ? seller.accountCreatedAt.toDate()
    : new Date();
  const ageDays = Math.floor(
    (Date.now() - accountCreated.getTime()) / (1000 * 60 * 60 * 24)
  );

  if (ageDays > 180) score += 5;
  else if (ageDays > 90) score += 3;
  else if (ageDays > 30) score += 1;

  // Clamp
  const finalScore = Math.max(0, Math.min(100, Math.round(score * 10) / 10));

  // Verdict
  let verdict = "high_risk";
  if (finalScore >= 80) verdict = "trusted";
  else if (finalScore >= 50) verdict = "unverified";

  return {
    score: finalScore,
    verdict,
    reportCount: reportsSnap.size,
    reviewCount: reviewsSnap.size,
  };
}

// ═══════════════════════════════════════════════════════════════
// HELPER — Detect Fraud Patterns
// ═══════════════════════════════════════════════════════════════

async function detectFraudPatterns(sellerId, report, reportId) {
  const sellerRef = db.collection("sellers").doc(sellerId);
  const sellerSnap = await sellerRef.get();
  if (!sellerSnap.exists) return;

  const seller = sellerSnap.data();
  const triggeredRules = [];
  const now = new Date();

  // Rule 1: Account < 30 days AND scamReportCount >= 2
  const accountCreated = seller.accountCreatedAt
    ? seller.accountCreatedAt.toDate()
    : now;
  const accountAgeDays = Math.floor(
    (now.getTime() - accountCreated.getTime()) / (1000 * 60 * 60 * 24)
  );

  if (accountAgeDays < 30 && (seller.scamReportCount || 0) >= 2) {
    triggeredRules.push("rapid_new_account");
    // Cap trust score at 40
    await sellerRef.update({
      trustScore: Math.min(seller.trustScore || 50, 40),
      trustVerdict: "high_risk",
    });
  }

  // Rule 2: amountLost > 20000 NPR
  if ((report.amountLost || 0) > 20000) {
    triggeredRules.push("large_amount");
    await db.collection("admin_notifications").add({
      type: "large_amount_report",
      sellerId,
      reportId,
      amountLost: report.amountLost,
      message: `High-value fraud report: NPR ${report.amountLost} against seller ${sellerId}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
    });
  }

  // Rule 3: 3+ reports in last 48 hours
  const twoDaysAgo = new Date(now.getTime() - 48 * 60 * 60 * 1000);
  const recentReportsSnap = await db
    .collection("reports")
    .where("sellerId", "==", sellerId)
    .where("submittedAt", ">=", admin.firestore.Timestamp.fromDate(twoDaysAgo))
    .get();

  if (recentReportsSnap.size >= 3) {
    triggeredRules.push("coordinated_attack");
    await sellerRef.update({ status: "under_review" });
  }

  // Rule 4: 5+ reports of same type on same platform in 7 days
  const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const platformTypeSnap = await db
    .collection("reports")
    .where("sellerId", "==", sellerId)
    .where("platform", "==", report.platform || "")
    .where("incidentType", "==", report.incidentType || "")
    .where(
      "submittedAt",
      ">=",
      admin.firestore.Timestamp.fromDate(sevenDaysAgo)
    )
    .get();

  if (platformTypeSnap.size >= 5) {
    triggeredRules.push("platform_concentration");
    await db.collection("community_alerts").add({
      type: "platform_concentration",
      sellerId,
      platform: report.platform,
      incidentType: report.incidentType,
      count: platformTypeSnap.size,
      message: `${platformTypeSnap.size} ${report.incidentType} reports on ${report.platform} for seller ${sellerId} in 7 days`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  // Log all triggered rules
  if (triggeredRules.length > 0) {
    await db.collection("fraud_detector_log").add({
      sellerId,
      reportId,
      triggeredRules,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      details: {
        accountAgeDays,
        amountLost: report.amountLost || 0,
        recentReportCount: recentReportsSnap.size,
        platformTypeCount: platformTypeSnap.size,
      },
    });
  }
}

// ═══════════════════════════════════════════════════════════════
// FUNCTION 1 — onReportCreated
// ═══════════════════════════════════════════════════════════════

exports.onReportCreated = functions.firestore
  .document("reports/{reportId}")
  .onCreate(async (snap, context) => {
    const report = snap.data();
    const reportId = context.params.reportId;
    const sellerId = report.sellerId;

    if (!sellerId) return null;

    // Recalculate trust score
    const result = await recalculateTrustScore(sellerId);
    if (!result) return null;

    const sellerRef = db.collection("sellers").doc(sellerId);

    // Update seller document
    await sellerRef.update({
      trustScore: result.score,
      trustVerdict: result.verdict,
      scamReportCount: result.reportCount,
      lastTrustUpdate: admin.firestore.FieldValue.serverTimestamp(),
      trustScoreHistory: admin.firestore.FieldValue.arrayUnion({
        score: result.score,
        timestamp: Date.now(),
        reason: "new_report",
      }),
    });

    // Send FCM notification to seller
    const sellerSnap = await sellerRef.get();
    const sellerData = sellerSnap.data();

    if (sellerData && sellerData.fcmToken) {
      try {
        await messaging.send({
          token: sellerData.fcmToken,
          notification: {
            title: "New Report Filed Against Your Profile",
            body: "A buyer has submitted a report. Respond within 48 hours to protect your trust score.",
          },
          data: {
            type: "new_report",
            reportId,
            sellerId,
          },
        });
      } catch (e) {
        console.log("FCM send failed (token may be stale):", e.message);
      }
    }

    // Detect fraud patterns
    await detectFraudPatterns(sellerId, report, reportId);

    return null;
  });

// ═══════════════════════════════════════════════════════════════
// FUNCTION 2 — onReviewCreated
// ═══════════════════════════════════════════════════════════════

exports.onReviewCreated = functions.firestore
  .document("reviews/{reviewId}")
  .onCreate(async (snap, context) => {
    const review = snap.data();
    const reviewId = context.params.reviewId;
    const sellerId = review.sellerId;

    if (!sellerId) return null;

    // Calculate authenticity weight
    let weight = 1.0;

    // Check reviewer account age
    if (review.reviewerId) {
      const userSnap = await db
        .collection("users")
        .doc(review.reviewerId)
        .get();
      if (userSnap.exists) {
        const userData = userSnap.data();
        const createdAt = userData.createdAt
          ? userData.createdAt.toDate()
          : new Date();
        const accountAgeDays = Math.floor(
          (Date.now() - createdAt.getTime()) / (1000 * 60 * 60 * 24)
        );
        if (accountAgeDays < 7) weight -= 0.3;
      }

      // Check if reviewer posted 3+ reviews in last 24 hours
      const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
      const recentReviewsSnap = await db
        .collection("reviews")
        .where("reviewerId", "==", review.reviewerId)
        .where(
          "createdAt",
          ">=",
          admin.firestore.Timestamp.fromDate(oneDayAgo)
        )
        .get();

      if (recentReviewsSnap.size >= 3) weight -= 0.2;
    }

    // Check comment length
    const comment = review.comment || "";
    if (comment.length < 20) weight -= 0.2;

    weight = Math.max(weight, 0.1);

    // Write authenticity weight back to review
    await snap.ref.update({ authenticityWeight: weight });

    // Recalculate trust score
    const result = await recalculateTrustScore(sellerId);
    if (!result) return null;

    await db
      .collection("sellers")
      .doc(sellerId)
      .update({
        trustScore: result.score,
        trustVerdict: result.verdict,
        reviewCount: result.reviewCount,
        lastTrustUpdate: admin.firestore.FieldValue.serverTimestamp(),
        trustScoreHistory: admin.firestore.FieldValue.arrayUnion({
          score: result.score,
          timestamp: Date.now(),
          reason: "new_review",
        }),
      });

    return null;
  });

// ═══════════════════════════════════════════════════════════════
// FUNCTION 3 — onReportUpdated (seller response)
// ═══════════════════════════════════════════════════════════════

exports.onReportUpdated = functions.firestore
  .document("reports/{reportId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const reportId = context.params.reportId;

    // Only fire when sellerResponse changes from empty to filled
    const hadResponse =
      before.sellerResponse && before.sellerResponse.length > 0;
    const hasResponse =
      after.sellerResponse && after.sellerResponse.length > 0;

    if (hadResponse || !hasResponse) return null;

    const sellerId = after.sellerId;
    const reporterId = after.reporterId;

    // Send FCM to reporter
    if (reporterId) {
      const userSnap = await db.collection("users").doc(reporterId).get();
      if (userSnap.exists) {
        const userData = userSnap.data();
        if (userData.fcmToken) {
          try {
            await messaging.send({
              token: userData.fcmToken,
              notification: {
                title: "Seller Responded to Your Report",
                body: "The seller has provided a response to your fraud report.",
              },
              data: {
                type: "seller_response",
                reportId,
                sellerId: sellerId || "",
              },
            });
          } catch (e) {
            console.log("FCM send to reporter failed:", e.message);
          }
        }
      }
    }

    // Update dispute response rate
    if (sellerId) {
      const allReportsSnap = await db
        .collection("reports")
        .where("sellerId", "==", sellerId)
        .get();

      let total = 0;
      let responded = 0;
      allReportsSnap.forEach((doc) => {
        total++;
        const r = doc.data();
        if (r.sellerResponse && r.sellerResponse.length > 0) responded++;
      });

      const rate = total > 0 ? responded / total : 0;

      await db.collection("sellers").doc(sellerId).update({
        disputeResponseRate: Math.round(rate * 100) / 100,
      });

      // Recalculate trust score
      const result = await recalculateTrustScore(sellerId);
      if (result) {
        await db
          .collection("sellers")
          .doc(sellerId)
          .update({
            trustScore: result.score,
            trustVerdict: result.verdict,
            lastTrustUpdate: admin.firestore.FieldValue.serverTimestamp(),
            trustScoreHistory: admin.firestore.FieldValue.arrayUnion({
              score: result.score,
              timestamp: Date.now(),
              reason: "dispute_response",
            }),
          });
      }
    }

    return null;
  });

// ═══════════════════════════════════════════════════════════════
// FUNCTION 4 — weeklySellerDigest
// ═══════════════════════════════════════════════════════════════

exports.weeklySellerDigest = functions.pubsub
  .schedule("every monday 08:00")
  .timeZone("Asia/Kathmandu")
  .onRun(async () => {
    const sellersSnap = await db
      .collection("sellers")
      .where("isVerified", "==", true)
      .where("fcmToken", "!=", null)
      .get();

    const promises = [];

    sellersSnap.forEach((doc) => {
      const seller = doc.data();
      if (seller.fcmToken) {
        const score = seller.trustScore || 0;
        const verdict = seller.trustVerdict || "unverified";

        promises.push(
          messaging
            .send({
              token: seller.fcmToken,
              notification: {
                title: "Your Weekly Trust Score Summary",
                body: `Your current trust score is ${score} (${verdict}). Keep up the good work!`,
              },
              data: {
                type: "weekly_digest",
                score: String(score),
                verdict,
              },
            })
            .catch((e) =>
              console.log("Weekly digest FCM failed:", e.message)
            )
        );
      }
    });

    await Promise.all(promises);
    console.log(
      `Weekly digest sent to ${promises.length} verified sellers.`
    );
    return null;
  });

// ═══════════════════════════════════════════════════════════════
// FUNCTION 5 — dailyCleanup
// ═══════════════════════════════════════════════════════════════

exports.dailyCleanup = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    const thirtyDaysAgo = new Date(
      Date.now() - 30 * 24 * 60 * 60 * 1000
    );

    const oldNotificationsSnap = await db
      .collection("admin_notifications")
      .where("read", "==", true)
      .where(
        "createdAt",
        "<=",
        admin.firestore.Timestamp.fromDate(thirtyDaysAgo)
      )
      .get();

    const batch = db.batch();
    let count = 0;

    oldNotificationsSnap.forEach((doc) => {
      batch.delete(doc.ref);
      count++;
    });

    if (count > 0) {
      await batch.commit();
    }

    console.log(`Daily cleanup: deleted ${count} old read notifications.`);
    return null;
  });
