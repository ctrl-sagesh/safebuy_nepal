/**
 * SafeBuy Nepal — Firestore data seeder (Firebase Admin SDK).
 *
 * Populates the platform with a realistic set of sellers, community fraud
 * reports, verified reviews, alerts, a leaderboard, a pending KYC submission,
 * and system notifications so every screen shows genuine production content.
 *
 * USAGE
 *   1. Download a service account key from the Firebase console:
 *        Project Settings -> Service accounts -> Generate new private key
 *      Save it next to this project as  firebase.json  (repo root).
 *   2. From the project root:
 *        npm install firebase-admin      (once)
 *        node tool/seed_demo_data.js
 *
 * The script is idempotent: it checks whether each document already exists
 * and skips it, so it is safe to run more than once.
 *
 * Field names below match the Dart models exactly
 * (lib/models/*.dart, lib/features/*).
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const serviceAccount = require('../firebasee.json');

initializeApp({
  credential: cert(serviceAccount),
});

const db = getFirestore();
const admin = { firestore: { Timestamp } };

// ── Time helpers ──────────────────────────────────────────────────────────────
function monthsAgo(n) {
  const d = new Date();
  d.setMonth(d.getMonth() - n);
  return Timestamp.fromDate(d);
}
function daysAgo(n) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return Timestamp.fromDate(d);
}
function monthsFromNow(n) {
  const d = new Date();
  d.setMonth(d.getMonth() + n);
  return Timestamp.fromDate(d);
}
function scoreHistory(base, variance, count) {
  return Array.from({ length: count }, (_, i) => ({
    score: base + Math.floor(Math.random() * variance),
    date: Timestamp.fromDate(
      new Date(Date.now() - (count - i) * 7 * 24 * 60 * 60 * 1000)
    ),
  }));
}
function currentMonth() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
}

const stats = { created: 0, skipped: 0 };

// Create a document only if it does not already exist.
async function seedDoc(ref, data, label) {
  const snap = await ref.get();
  if (snap.exists) {
    console.log(`  skip   ${label} (already exists)`);
    stats.skipped++;
    return;
  }
  await ref.set(data);
  console.log(`  create ${label}`);
  stats.created++;
}

// ── SELLERS ───────────────────────────────────────────────────────────────────
async function seedSellers() {
  console.log('\nSellers');
  const sellers = [
    {
      id: '9841234567',
      data: {
        sellerId: '9841234567',
        name: 'Priya Maharjan',
        phone: '9841234567',
        phoneNumber: '9841234567',
        esewaId: '9841234567',
        tiktokHandle: '@priyafashionsktm',
        instagramHandle: '@priyafashions.np',
        facebookHandle: '@priyafashionsktm',
        trustScore: 87.0,
        trustVerdict: 'trusted',
        isVerified: true,
        verifiedBadge: true,
        totalOrders: 156,
        reviewCount: 23,
        scamReportCount: 0,
        reportCount: 0,
        accountCreatedAt: monthsAgo(8),
        createdAt: monthsAgo(8),
        lastActiveAt: daysAgo(1),
        updatedAt: daysAgo(1),
        disputeResponseRate: 1.0,
        businessName: 'Priya Fashions',
        businessCategory: 'Clothing & Fashion',
        profileImageUrl: '',
        description:
          'Authentic clothing and fashion accessories from Kathmandu. ' +
          'Specialising in traditional and modern Nepali fashion since 2023.',
        trustScoreHistory: scoreHistory(85, 8, 30),
        averageRating: 4.7,
        linkedUserId: '',
        kycStatus: 'verified',
        verificationTier: 'premium',
        kycSelfieUrl: '',
        kycCitizenshipUrl: '',
        kycPanCardUrl: '',
        kycLocationPhoto1Url: '',
        kycLocationPhoto2Url: '',
        kycLocationPhoto3Url: '',
        kycLocationLat: 27.7172,
        kycLocationLng: 85.324,
        kycLocationDistrict: 'Kathmandu',
        panNumber: '123456789',
        panName: 'Priya Maharjan',
        citizenshipNumber: '56-01-78-12345',
        gmailAccount: 'priyafashions.ktm@gmail.com',
        qrCodeUrl: '',
        safebuyCardId: 'SBV-2026-00001',
        verificationDate: monthsAgo(6),
        verificationExpiry: monthsFromNow(6),
        lastReverificationDate: monthsAgo(6),
        kycRejectionReason: '',
        isQrLocked: true,
        verificationDistrict: 'Kathmandu',
      },
    },
    {
      id: '9851234568',
      data: {
        sellerId: '9851234568',
        name: 'Bibek Shrestha',
        phone: '9851234568',
        phoneNumber: '9851234568',
        esewaId: '9851234568',
        tiktokHandle: '@technepalstore',
        instagramHandle: '@technepal.store',
        facebookHandle: null,
        trustScore: 82.0,
        trustVerdict: 'trusted',
        isVerified: true,
        verifiedBadge: true,
        totalOrders: 98,
        reviewCount: 18,
        scamReportCount: 0,
        reportCount: 0,
        accountCreatedAt: monthsAgo(6),
        createdAt: monthsAgo(6),
        lastActiveAt: daysAgo(2),
        updatedAt: daysAgo(2),
        disputeResponseRate: 1.0,
        businessName: 'TechNepal Store',
        businessCategory: 'Electronics & Gadgets',
        profileImageUrl: '',
        description:
          'Genuine electronics and gadgets. Authorised reseller of major ' +
          'brands. All products come with full manufacturer warranty.',
        trustScoreHistory: scoreHistory(80, 6, 30),
        averageRating: 4.6,
        linkedUserId: '',
        kycStatus: 'verified',
        verificationTier: 'verified',
        kycSelfieUrl: '',
        kycCitizenshipUrl: '',
        kycPanCardUrl: '',
        kycLocationPhoto1Url: '',
        kycLocationPhoto2Url: '',
        kycLocationPhoto3Url: '',
        kycLocationLat: 27.6588,
        kycLocationLng: 85.3247,
        kycLocationDistrict: 'Lalitpur',
        panNumber: '234567890',
        panName: 'Bibek Shrestha',
        citizenshipNumber: '56-02-79-23456',
        gmailAccount: 'technepalstore@gmail.com',
        qrCodeUrl: '',
        safebuyCardId: 'SBV-2026-00002',
        verificationDate: monthsAgo(4),
        verificationExpiry: monthsFromNow(8),
        lastReverificationDate: monthsAgo(4),
        kycRejectionReason: '',
        isQrLocked: true,
        verificationDistrict: 'Lalitpur',
      },
    },
    {
      id: '9861234569',
      data: {
        sellerId: '9861234569',
        name: 'Sunita Sharma',
        phone: '9861234569',
        phoneNumber: '9861234569',
        esewaId: '9861234569',
        tiktokHandle: '@sunsetcosmetics.np',
        instagramHandle: null,
        facebookHandle: null,
        trustScore: 64.0,
        trustVerdict: 'unverified',
        isVerified: false,
        verifiedBadge: false,
        totalOrders: 34,
        reviewCount: 5,
        scamReportCount: 1,
        reportCount: 1,
        accountCreatedAt: monthsAgo(3),
        createdAt: monthsAgo(3),
        lastActiveAt: daysAgo(5),
        updatedAt: daysAgo(5),
        disputeResponseRate: 0.5,
        businessName: 'Sunset Cosmetics',
        businessCategory: 'Beauty & Cosmetics',
        profileImageUrl: '',
        description:
          'Skincare and beauty products from verified suppliers. Local and ' +
          'imported brands.',
        trustScoreHistory: scoreHistory(68, 8, 30),
        averageRating: 3.8,
        linkedUserId: '',
        kycStatus: 'pending',
        verificationTier: 'basic',
        kycSelfieUrl: '',
        kycCitizenshipUrl: '',
        kycPanCardUrl: '',
        kycLocationPhoto1Url: '',
        kycLocationPhoto2Url: '',
        kycLocationPhoto3Url: '',
        kycLocationLat: 27.671,
        kycLocationLng: 85.4298,
        kycLocationDistrict: 'Bhaktapur',
        panNumber: '345678901',
        panName: 'Sunita Sharma',
        citizenshipNumber: '',
        gmailAccount: '',
        qrCodeUrl: '',
        safebuyCardId: '',
        verificationDate: null,
        verificationExpiry: null,
        lastReverificationDate: null,
        kycRejectionReason: '',
        isQrLocked: false,
        verificationDistrict: 'Bhaktapur',
      },
    },
    {
      id: '9871234570',
      data: {
        sellerId: '9871234570',
        name: 'QuickBuy Electronics',
        phone: '9871234570',
        phoneNumber: '9871234570',
        esewaId: '9871234570',
        tiktokHandle: '@quickbuy.electronics',
        instagramHandle: '@quickbuynepal',
        facebookHandle: null,
        trustScore: 31.0,
        trustVerdict: 'high_risk',
        isVerified: false,
        verifiedBadge: false,
        totalOrders: 12,
        reviewCount: 2,
        scamReportCount: 4,
        reportCount: 4,
        accountCreatedAt: daysAgo(45),
        createdAt: daysAgo(45),
        lastActiveAt: daysAgo(10),
        updatedAt: daysAgo(10),
        disputeResponseRate: 0.0,
        businessName: 'QuickBuy Electronics',
        businessCategory: 'Electronics & Gadgets',
        profileImageUrl: '',
        description: '',
        trustScoreHistory: scoreHistory(35, 10, 30),
        averageRating: 2.1,
        linkedUserId: '',
        kycStatus: 'not_submitted',
        verificationTier: 'none',
        kycSelfieUrl: '',
        kycCitizenshipUrl: '',
        kycPanCardUrl: '',
        kycLocationPhoto1Url: '',
        kycLocationPhoto2Url: '',
        kycLocationPhoto3Url: '',
        kycLocationLat: 0,
        kycLocationLng: 0,
        kycLocationDistrict: '',
        panNumber: '',
        panName: '',
        citizenshipNumber: '',
        gmailAccount: '',
        qrCodeUrl: '',
        safebuyCardId: '',
        verificationDate: null,
        verificationExpiry: null,
        lastReverificationDate: null,
        kycRejectionReason: '',
        isQrLocked: false,
        verificationDistrict: '',
      },
    },
    {
      id: '9881234571',
      data: {
        sellerId: '9881234571',
        name: 'FastDeal Nepal',
        phone: '9881234571',
        phoneNumber: '9881234571',
        esewaId: '9881234571',
        tiktokHandle: '@fastdealnepal',
        instagramHandle: '@fastdeal.nepal',
        facebookHandle: null,
        trustScore: 18.0,
        trustVerdict: 'high_risk',
        isVerified: false,
        verifiedBadge: false,
        totalOrders: 0,
        reviewCount: 0,
        scamReportCount: 7,
        reportCount: 7,
        accountCreatedAt: daysAgo(12),
        createdAt: daysAgo(12),
        lastActiveAt: daysAgo(3),
        updatedAt: daysAgo(3),
        disputeResponseRate: 0.0,
        businessName: 'FastDeal Nepal',
        businessCategory: 'General Merchandise',
        profileImageUrl: '',
        description: '',
        trustScoreHistory: scoreHistory(20, 8, 30),
        averageRating: 0.0,
        linkedUserId: '',
        kycStatus: 'not_submitted',
        verificationTier: 'none',
        kycSelfieUrl: '',
        kycCitizenshipUrl: '',
        kycPanCardUrl: '',
        kycLocationPhoto1Url: '',
        kycLocationPhoto2Url: '',
        kycLocationPhoto3Url: '',
        kycLocationLat: 0,
        kycLocationLng: 0,
        kycLocationDistrict: '',
        panNumber: '',
        panName: '',
        citizenshipNumber: '',
        gmailAccount: '',
        qrCodeUrl: '',
        safebuyCardId: '',
        verificationDate: null,
        verificationExpiry: null,
        lastReverificationDate: null,
        kycRejectionReason: '',
        isQrLocked: false,
        verificationDistrict: '',
      },
    },
    {
      id: 'sagesh_store',
      data: {
        sellerId: 'sagesh_store',
        name: 'Everest Electronics',
        phone: '9828046299',
        phoneNumber: '9828046299',
        esewaId: '9828046299',
        tiktokHandle: '@sageshelectronics',
        instagramHandle: '@sagesh.electronics',
        facebookHandle: null,
        trustScore: 75.0,
        trustVerdict: 'unverified',
        isVerified: false,
        verifiedBadge: false,
        totalOrders: 8,
        reviewCount: 3,
        scamReportCount: 0,
        reportCount: 0,
        accountCreatedAt: monthsAgo(2),
        createdAt: monthsAgo(2),
        lastActiveAt: daysAgo(1),
        updatedAt: daysAgo(1),
        disputeResponseRate: 1.0,
        businessName: 'Everest Electronics',
        businessCategory: 'Electronics & Gadgets',
        profileImageUrl: '',
        description:
          'Quality electronics and accessories at competitive prices in ' +
          'Kathmandu.',
        trustScoreHistory: scoreHistory(73, 5, 30),
        averageRating: 4.3,
        linkedUserId: 'AdFCuXsadSbG89lwNDmW2c3NP5Q2',
        kycStatus: 'not_submitted',
        verificationTier: 'basic',
        kycSelfieUrl: '',
        kycCitizenshipUrl: '',
        kycPanCardUrl: '',
        kycLocationPhoto1Url: '',
        kycLocationPhoto2Url: '',
        kycLocationPhoto3Url: '',
        kycLocationLat: 27.7172,
        kycLocationLng: 85.324,
        kycLocationDistrict: 'Kathmandu',
        panNumber: '',
        panName: '',
        citizenshipNumber: '',
        gmailAccount: 'sageshadhikari@gmail.com',
        qrCodeUrl: '',
        safebuyCardId: '',
        verificationDate: null,
        verificationExpiry: null,
        lastReverificationDate: null,
        kycRejectionReason: '',
        isQrLocked: false,
        verificationDistrict: 'Kathmandu',
      },
    },
  ];

  for (const s of sellers) {
    await seedDoc(db.collection('sellers').doc(s.id), s.data, `sellers/${s.id}`);
  }
}

// ── REPORTS ───────────────────────────────────────────────────────────────────
// incidentType uses the app's internal codes so trust scoring stays consistent.
async function seedReports() {
  console.log('\nReports');
  const reports = [
    {
      id: 'RPT-2026-00001',
      data: {
        reporterId: 'community_001',
        sellerId: '9871234570',
        sellerPhone: '9871234570',
        sellerName: 'QuickBuy Electronics',
        reporterName: 'Buyer from Kathmandu',
        platform: 'Instagram',
        incidentType: 'no_delivery',
        amountLost: 8500,
        description:
          'Ordered a Bluetooth speaker worth NPR 8,500. Paid via eSewa. ' +
          'Seller confirmed receipt and promised delivery in 3 days. After ' +
          '2 weeks of no delivery and messages being ignored the seller ' +
          'blocked me on Instagram. No product received.',
        incidentDate: daysAgo(30),
        submittedAt: daysAgo(28),
        createdAt: daysAgo(28),
        status: 'pending',
        reporterDeclaration: true,
        sellerResponse: null,
      },
    },
    {
      id: 'RPT-2026-00002',
      data: {
        reporterId: 'community_002',
        sellerId: '9871234570',
        sellerPhone: '9871234570',
        sellerName: 'QuickBuy Electronics',
        reporterName: 'Buyer from Bhaktapur',
        platform: 'TikTok',
        incidentType: 'wrong_item',
        amountLost: 4500,
        description:
          'Ordered original iPhone charger listed at NPR 4,500. Received a ' +
          'cheap local copy worth maybe NPR 200. Seller refused to refund ' +
          'and stopped responding after I sent photos of the counterfeit product.',
        incidentDate: daysAgo(25),
        submittedAt: daysAgo(25),
        createdAt: daysAgo(25),
        status: 'disputed',
        reporterDeclaration: true,
        sellerResponse:
          'The item sent was exactly as described in our listing. The buyer ' +
          'is making false claims about the product condition.',
      },
    },
    {
      id: 'RPT-2026-00003',
      data: {
        reporterId: 'community_003',
        sellerId: '9881234571',
        sellerPhone: '9881234571',
        sellerName: 'FastDeal Nepal',
        reporterName: 'Buyer from Lalitpur',
        platform: 'TikTok',
        incidentType: 'no_delivery',
        amountLost: 15000,
        description:
          'Ordered 3 pieces of winter clothing totalling NPR 15,000. Seller ' +
          'insisted on full advance payment via eSewa. After payment seller ' +
          'said delivery in 5 days. Account disappeared after 2 days. Later ' +
          'found the same phone number operating under a new TikTok account ' +
          'with a different business name.',
        incidentDate: daysAgo(10),
        submittedAt: daysAgo(8),
        createdAt: daysAgo(8),
        status: 'escalated',
        reporterDeclaration: true,
        sellerResponse: null,
      },
    },
    {
      id: 'RPT-2026-00004',
      data: {
        reporterId: 'community_004',
        sellerId: '9881234571',
        sellerPhone: '9881234571',
        sellerName: 'FastDeal Nepal',
        reporterName: 'Buyer from Pokhara',
        platform: 'Instagram',
        incidentType: 'payment_issue',
        amountLost: 12000,
        description:
          'Seller posted product photos copied from a legitimate Kathmandu ' +
          'shop. Requested NPR 12,000 advance payment via Khalti before ' +
          'confirming order. Payment sent. Seller never responded again and ' +
          'has since deleted their Instagram account.',
        incidentDate: daysAgo(6),
        submittedAt: daysAgo(5),
        createdAt: daysAgo(5),
        status: 'pending',
        reporterDeclaration: true,
        sellerResponse: null,
      },
    },
    {
      id: 'RPT-2026-00005',
      data: {
        reporterId: 'community_005',
        sellerId: '9861234569',
        sellerPhone: '9861234569',
        sellerName: 'Sunset Cosmetics',
        reporterName: 'Buyer from Bhaktapur',
        platform: 'TikTok',
        incidentType: 'fake_product',
        amountLost: 2500,
        description:
          'Ordered Korean skincare products shown in the seller TikTok video. ' +
          'Received local counterfeit products with fake Korean branding. ' +
          'Products had no authentic hologram seal. Seller offered 50 percent ' +
          'refund which I declined as products were entirely counterfeit.',
        incidentDate: daysAgo(16),
        submittedAt: daysAgo(15),
        createdAt: daysAgo(15),
        status: 'resolved',
        reporterDeclaration: true,
        sellerResponse:
          'We sincerely apologise for this experience. Our supplier has been ' +
          'replaced and we now only stock verified genuine products. A full ' +
          'refund has been issued to this buyer.',
      },
    },
  ];

  for (const r of reports) {
    await seedDoc(
      db.collection('reports').doc(r.id),
      r.data,
      `reports/${r.id}`
    );
  }
}

// ── REVIEWS ───────────────────────────────────────────────────────────────────
async function seedReviews() {
  console.log('\nReviews');
  const reviews = [
    // Priya Fashions
    {
      sellerId: '9841234567', rating: 5,
      comment:
        'Excellent quality clothes exactly as shown in the TikTok video. ' +
        'Delivered within 3 days to my Kathmandu address. Very professional ' +
        'and responsive seller. Will definitely order again.',
      productName: 'Nepali traditional dress set',
      isVerifiedPurchase: true, authenticityWeight: 0.9,
      reviewerName: 'Buyer from Kathmandu', createdAt: monthsAgo(2),
    },
    {
      sellerId: '9841234567', rating: 5,
      comment:
        'Very genuine seller. Did a video call before I paid to show me the ' +
        'actual product in hand. Fast delivery and good packaging. Highly ' +
        'recommended for anyone looking for authentic Nepali clothing.',
      productName: 'Pashmina winter jacket',
      isVerifiedPurchase: true, authenticityWeight: 0.85,
      reviewerName: 'Buyer from Lalitpur', createdAt: daysAgo(42),
    },
    {
      sellerId: '9841234567', rating: 4,
      comment:
        'Good quality product. Slight delay in delivery but the seller kept ' +
        'me informed throughout. Product matches the description exactly. ' +
        'Overall happy with my purchase.',
      productName: 'Casual wear set',
      isVerifiedPurchase: true, authenticityWeight: 0.8,
      reviewerName: 'Buyer from Bhaktapur', createdAt: monthsAgo(1),
    },
    {
      sellerId: '9841234567', rating: 5,
      comment:
        'Best clothing seller I have found on TikTok in Nepal. The SafeBuy ' +
        'verified badge gave me confidence to place a large order. Everything ' +
        'delivered perfectly and exactly as described. Packaging was excellent.',
      productName: 'Clothing bundle NPR 8,500',
      isVerifiedPurchase: true, authenticityWeight: 0.92,
      reviewerName: 'Buyer from Pokhara', createdAt: daysAgo(21),
    },
    {
      sellerId: '9841234567', rating: 4,
      comment:
        'Good experience overall. Product quality is genuine unlike many ' +
        'sellers on social media. Packaging could be improved but seller was ' +
        'very responsive to all questions before I placed my order. Would buy again.',
      productName: 'Ethnic wear collection',
      isVerifiedPurchase: false, authenticityWeight: 0.78,
      reviewerName: 'Buyer from Chitwan', createdAt: daysAgo(14),
    },
    // TechNepal Store
    {
      sellerId: '9851234568', rating: 5,
      comment:
        'Bought a power bank. Completely genuine product with warranty card ' +
        'and original box included. Tested and working perfectly after 3 ' +
        'weeks. Seller helped me set it up over a video call.',
      productName: '20000mAh power bank',
      isVerifiedPurchase: true, authenticityWeight: 0.88,
      reviewerName: 'Buyer from Kathmandu', createdAt: daysAgo(35),
    },
    {
      sellerId: '9851234568', rating: 5,
      comment:
        'Original product confirmed. Fast delivery to Lalitpur. Price was ' +
        'more competitive than physical stores in New Road. Will definitely ' +
        'order from TechNepal again.',
      productName: 'Bluetooth earphones',
      isVerifiedPurchase: true, authenticityWeight: 0.82,
      reviewerName: 'Buyer from Lalitpur', createdAt: daysAgo(21),
    },
    {
      sellerId: '9851234568', rating: 4,
      comment:
        'Good seller with genuine products. Delivery took 5 days instead of ' +
        'promised 3 but seller apologised and offered a small discount on ' +
        'next order. Overall satisfied and would recommend.',
      productName: 'Phone case and screen protector',
      isVerifiedPurchase: true, authenticityWeight: 0.75,
      reviewerName: 'Buyer from Bhaktapur', createdAt: daysAgo(7),
    },
  ];

  let i = 0;
  for (const rv of reviews) {
    i++;
    const id = `seed_review_${rv.sellerId}_${i}`;
    await seedDoc(
      db.collection('reviews').doc(id),
      {
        sellerId: rv.sellerId,
        reviewerId: `community_reviewer_${i}`,
        reviewerDisplayName: rv.reviewerName,
        reviewerName: rv.reviewerName,
        rating: rv.rating,
        comment: rv.comment,
        createdAt: rv.createdAt,
        isVerifiedPurchase: rv.isVerifiedPurchase,
        authenticityWeight: rv.authenticityWeight,
        helpfulCount: Math.floor(Math.random() * 12),
        evidenceUrl: null,
        productImageUrl: '',
        productName: rv.productName,
        productRating: rv.rating,
        isTopReview: false,
      },
      `reviews/${id}`
    );
  }
}

// ── COMMUNITY ALERTS ──────────────────────────────────────────────────────────
async function seedAlerts() {
  console.log('\nCommunity alerts');
  const alerts = [
    {
      id: 'alert_tiktok_electronics',
      data: {
        title: 'High Volume Fraud: TikTok Electronics Sellers',
        message:
          'SafeBuy Nepal has detected an unusual increase in fraud complaints ' +
          'from TikTok electronics sellers operating in Kathmandu valley. ' +
          'Seven reports filed in the last 48 hours totalling NPR 83,500 in ' +
          'reported losses. Verify all electronics sellers before sending any ' +
          'advance payment.',
        severity: 'high',
        platform: 'TikTok',
        category: 'electronics',
        isActive: true,
        relatedSellerId: '9881234571',
        reportCount: 7,
        totalAmountLost: 83500,
        createdAt: daysAgo(2),
        createdBy: 'fraud_detector',
      },
    },
    {
      id: 'alert_counterfeit_cosmetics',
      data: {
        title: 'Counterfeit Cosmetics Warning: Instagram',
        message:
          'Three reports of counterfeit cosmetic and skincare products ' +
          'received this week from unverified sellers on TikTok and Instagram. ' +
          'Products presented as imported Korean brands but delivered as local ' +
          'counterfeits. Check SafeBuy verification status before ordering any ' +
          'beauty products.',
        severity: 'medium',
        platform: 'Instagram',
        category: 'cosmetics',
        isActive: true,
        relatedSellerId: '9861234569',
        reportCount: 3,
        totalAmountLost: 7500,
        createdAt: daysAgo(5),
        createdBy: 'fraud_detector',
      },
    },
  ];
  for (const a of alerts) {
    await seedDoc(
      db.collection('community_alerts').doc(a.id),
      a.data,
      `community_alerts/${a.id}`
    );
  }
}

// ── LEADERBOARD ───────────────────────────────────────────────────────────────
async function seedLeaderboard() {
  console.log('\nLeaderboard');
  const month = currentMonth();
  await seedDoc(
    db.collection('leaderboard').doc(month),
    { month, calculatedAt: Timestamp.now() },
    `leaderboard/${month}`
  );

  const entries = [
    {
      sellerId: '9841234567', sellerName: 'Priya Maharjan',
      businessName: 'Priya Fashions', trustScore: 87.0, reviewCount: 23,
      totalOrders: 156, averageRating: 4.7, rank: 1,
      verificationTier: 'premium', safebuyCardId: 'SBV-2026-00001',
    },
    {
      sellerId: '9851234568', sellerName: 'Bibek Shrestha',
      businessName: 'TechNepal Store', trustScore: 82.0, reviewCount: 18,
      totalOrders: 98, averageRating: 4.6, rank: 2,
      verificationTier: 'verified', safebuyCardId: 'SBV-2026-00002',
    },
  ];
  for (const e of entries) {
    await seedDoc(
      db.collection('leaderboard').doc(month).collection('entries').doc(e.sellerId),
      {
        ...e,
        profileImageUrl: '',
        month,
        calculatedAt: Timestamp.now(),
      },
      `leaderboard/${month}/entries/${e.sellerId}`
    );
  }
}

// ── KYC SUBMISSION ────────────────────────────────────────────────────────────
async function seedKyc() {
  console.log('\nKYC submissions');
  await seedDoc(
    db.collection('kyc_submissions').doc('kyc_sunset_cosmetics'),
    {
      sellerId: '9861234569',
      submittedBy: '9861234569',
      submittedAt: daysAgo(3),
      status: 'pending',
      selfieUrl:
        'https://placehold.co/400x600/E8E8E8/999999?text=Identity+Document',
      citizenshipUrl:
        'https://placehold.co/600x400/E8E8E8/999999?text=Citizenship+Card',
      panCardUrl:
        'https://placehold.co/600x400/E8E8E8/999999?text=PAN+Card',
      locationPhotoUrls: [],
      locationLat: 27.671,
      locationLng: 85.4298,
      panNumberSubmitted: '345678901',
      citizenshipNumberSubmitted: '',
      gmailAccountSubmitted: '',
      qrCodeUrlSubmitted: '',
      adminReviewedBy: '',
      adminReviewedAt: null,
      adminNotes: '',
      rejectionReason: '',
      // Convenience fields for admin list display.
      sellerName: 'Sunset Cosmetics',
      sellerPhone: '9861234569',
      fullName: 'Sunita Sharma',
      district: 'Bhaktapur',
      tier: 'verified',
    },
    'kyc_submissions/kyc_sunset_cosmetics'
  );
}

// ── NOTIFICATIONS ─────────────────────────────────────────────────────────────
// The notification bell queries `notifications` where userId == uid and
// read == false, so both fields are written here.
async function seedNotifications() {
  console.log('\nNotifications');
  const uid = 'AdFCuXsadSbG89lwNDmW2c3NP5Q2';
  const items = [
    {
      id: 'notif_1', read: false,
      title: 'New Fraud Report Filed',
      body:
        'A fraud complaint has been submitted against FastDeal Nepal. Trust ' +
        'rating updated to 18 out of 100.',
      type: 'fraud_alert', relatedId: '9881234571', createdAt: daysAgo(2),
    },
    {
      id: 'notif_2', read: false,
      title: 'Community Alert Posted',
      body:
        'High volume fraud pattern detected from TikTok electronics sellers. ' +
        'Seven reports filed in 48 hours.',
      type: 'community_alert', relatedId: '9881234571', createdAt: daysAgo(2),
    },
    {
      id: 'notif_3', read: true,
      title: 'KYC Review Required',
      body:
        'Sunset Cosmetics has submitted identity verification documents. ' +
        'Admin review is required.',
      type: 'kyc_pending', relatedId: '9861234569', createdAt: daysAgo(3),
    },
    {
      id: 'notif_4', read: true,
      title: 'New Seller Registration',
      body:
        'A new seller has completed registration on SafeBuy Nepal and is ' +
        'awaiting verification review.',
      type: 'new_seller', relatedId: '', createdAt: daysAgo(5),
    },
  ];
  for (const n of items) {
    await seedDoc(
      db.collection('notifications').doc(n.id),
      {
        userId: uid,
        read: n.read,
        isRead: n.read,
        title: n.title,
        body: n.body,
        type: n.type,
        relatedId: n.relatedId,
        createdAt: n.createdAt,
      },
      `notifications/${n.id}`
    );
  }
}

// ── Link the seller to the admin user account ─────────────────────────────────
async function linkAdminSeller() {
  console.log('\nAdmin user link');
  const uid = 'AdFCuXsadSbG89lwNDmW2c3NP5Q2';
  const ref = db.collection('users').doc(uid);
  const snap = await ref.get();
  if (snap.exists) {
    await ref.set({ linkedSellerId: 'sagesh_store' }, { merge: true });
    console.log(`  update users/${uid} linkedSellerId = sagesh_store`);
    stats.created++;
    // Refresh the business display name even if the seller doc already
    // exists (idempotent seeding otherwise skips it).
    await db.collection('sellers').doc('sagesh_store').set(
      { name: 'Everest Electronics', businessName: 'Everest Electronics' },
      { merge: true }
    );
    console.log('  update sellers/sagesh_store business name');
  } else {
    console.log(
      `  warn   users/${uid} does not exist yet — sign in once with the ` +
      `admin account, then re-run to link the seller.`
    );
    stats.skipped++;
  }
}

// ── Run ───────────────────────────────────────────────────────────────────────
async function main() {
  console.log('SafeBuy Nepal — seeding Firestore\n=================================');
  await seedSellers();
  await seedReports();
  await seedReviews();
  await seedAlerts();
  await seedLeaderboard();
  await seedKyc();
  await seedNotifications();
  await linkAdminSeller();

  console.log('\n=================================');
  console.log(`Done. Created: ${stats.created}   Skipped (existing): ${stats.skipped}`);
  process.exit(0);
}

main().catch((err) => {
  console.error('\nSeeding failed:', err.message);
  process.exit(1);
});
