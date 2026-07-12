# SafeBuy Nepal — Technical Documentation

**Project:** Community-Driven Seller Trust Verification and Fraud Reporting Platform for Nepali Social Media Buyers
**Author:** Sagesh Adhikari, BSc (Hons) Ethical Hacking and Cybersecurity, Softwarica College, Coventry University UK
**Year:** 2026 (Final Year Thesis)
**Stack:** Flutter 3.41.9 · Dart 3.11.5 · Firebase (Firestore, Auth, Storage, Messaging) · Riverpod 2.x

---

## 1. System Architecture Overview

SafeBuy Nepal is built on **Clean Architecture** principles with strict layer separation, ensuring that domain logic is testable in isolation and the UI can be swapped without rewriting business rules.

```
┌──────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  • Screens (Stateless / ConsumerStateful Widgets)            │
│  • Riverpod Providers (state + side effects)                 │
│  • Core widgets (CustomButton, SellerTrustBadge, etc.)       │
└──────────────────────────────┬───────────────────────────────┘
                               │  watches/reads
                               ▼
┌──────────────────────────────────────────────────────────────┐
│                       DOMAIN LAYER                           │
│  • Models with toMap/fromMap/copyWith/Equatable              │
│  • Use cases (called via providers)                          │
│  • Repository interfaces (abstract)                          │
└──────────────────────────────┬───────────────────────────────┘
                               │  implements
                               ▼
┌──────────────────────────────────────────────────────────────┐
│                        DATA LAYER                            │
│  • Repository implementations                                │
│  • Service wrappers around Firebase SDKs                     │
│      AuthService · FirestoreService · StorageService         │
│      TrustScoreService · NotificationService                 │
│      AnalyticsService · SeedDataService                      │
└──────────────────────────────────────────────────────────────┘
                               │
                               ▼
                ┌───────────────────────────┐
                │   FIREBASE BACKEND        │
                │   (Cloud Firestore /      │
                │    Auth / Storage / FCM)  │
                └───────────────────────────┘
```

### Folder structure

```
lib/
├── core/                 # Design system + cross-cutting utilities
│   ├── theme/            # Colors, spacing, text styles, theme
│   ├── constants/        # App constants + bilingual strings
│   ├── utils/            # Validators, extensions
│   └── widgets/          # Reusable widgets (10 components)
├── features/             # Feature modules (auth, admin, ...)
│   └── <feature>/
│       ├── data/repositories/
│       ├── domain/repositories/
│       ├── domain/usecases/
│       └── presentation/
│           ├── providers/
│           └── screens/
├── models/               # Pure-Dart data models
├── services/             # Firebase service wrappers
├── widgets/              # Legacy widgets (chatbot, seller card)
├── screens/              # Legacy screens being migrated
├── providers/            # Cross-feature providers (language)
└── main.dart
```

---

## 2. Firebase Structure

### Collections

| Collection | Purpose | Read | Create | Update | Delete |
|---|---|---|---|---|---|
| `sellers` | Seller profiles + trust score | public | authenticated, only own | own (non-trust fields) or admin | admin |
| `reports` | Fraud reports | authenticated | authenticated, reporterId == auth.uid | seller: response only / admin: status | never |
| `reviews` | Buyer reviews | public | authenticated | admin only | never |
| `users` | App users | own / admin | own | own / admin | admin |
| `admin_audit_log` | Admin action audit | admin | admin | never | never |
| `admin_actions` | Admin moderation actions | admin | admin | never | never |

### Trust-locked fields

The following seller fields **cannot** be modified from the client SDK — only by Cloud Functions or the admin SDK (enforced via Firestore rules):
- `trustScore`
- `trustVerdict`
- `verifiedBadge`
- `scamReportCount`

### Storage layout

```
/evidence/{userId}/{reportId}/{type}_{timestamp}.{jpg|png|webp}
/profiles/{userId}/avatar.{jpg|png}
```

- 5 MB max for evidence; 2 MB for profile.
- Only the uploading user can write.
- No deletes on evidence (legal record integrity).

---

## 3. Trust Score Algorithm

The trust score is a **weighted aggregate of five factors** producing a value in `[0, 100]`:

| # | Factor | Max points | Rationale |
|---|---|---|---|
| 1 | Report severity | 40 | Reports are the strongest negative signal — they represent real money lost. The 40-point ceiling means even one severe verified report can move a seller from Trusted (≥ 80) to Unverified. |
| 2 | Verification status | 25 | A verified phone, eSewa, and linked social handle materially raises trust. Full badge = 25 pts; phone-only = 18 pts. |
| 3 | Review authenticity | 20 | A weighted average of ratings × authenticity weight. Suspicious accounts (new, spammy, short comments) score 0.2 weight, dropping their reviews' impact. |
| 4 | Dispute resolution | 10 | Sellers who actively respond to disputes earn this bonus. Rate >0.8 = 10 pts. |
| 5 | Account age | 5 | Older accounts have demonstrated continuity. >180 days = 5 pts. |

### Recency multiplier

To prevent a single old incident from permanently destroying a seller's reputation, each report's deduction is multiplied by:

```
< 30 days  → 1.0   (full weight)
< 90 days  → 0.7
≥ 90 days  → 0.4
```

### Verdict thresholds

```
score >= 80  → 'trusted'      (green shield)
score >= 50  → 'unverified'   (orange caution)
score <  50  → 'high_risk'    (red, pulse animation)
```

### Known limitations

1. **No platform-cross-checking yet** — the algorithm cannot verify that a TikTok handle is actually owned by the registering user.
2. **Self-reported amounts** — buyers state the NPR amount lost without escrow corroboration.
3. **Review brigading** — without payment-verified purchase confirmation, coordinated review attacks remain possible. The authenticity weight is the main mitigation.
4. **No machine-learning fraud detection** yet — flagging is rule-based.

---

## 4. Security Measures

| # | Control | Rationale |
|---|---|---|
| 1 | Firebase Phone OTP authentication | Real-name verification is impractical in Nepal. Phone OTP gates account creation. |
| 2 | Firestore security rules enforce `reporterId == auth.uid` | Prevents impersonation of report submitters. |
| 3 | Trust score fields locked client-side (`trustFieldsUnchanged()` rule) | Even a malicious user with valid auth cannot inflate their own trust score. |
| 4 | Storage rules enforce content-type + file size + path scoping | Prevents arbitrary file uploads and quota abuse. |
| 5 | HTML tag stripping in `Validators.sanitize()` before any text Firestore write | Defence against stored XSS in any future web admin panel. |
| 6 | Rate limiting: 3 reports per seller per 7 days per reporter | Prevents report bombing / defamation campaigns. |
| 7 | Account-deletion anonymisation (preserves reports) | Balances GDPR right-to-be-forgotten with fraud-record integrity. |
| 8 | Evidence served via signed URLs expiring in 1 hour | Prevents URL sharing leaking private evidence indefinitely. |
| 9 | All admin actions logged to immutable `admin_audit_log` | Enables compliance audits and prevents covert admin abuse. |
| 10 | Reporter declaration checkbox required on every report | Legal acknowledgment increases the cost of false reporting. |
| 11 | Portrait-only orientation (set in main.dart) | Reduces UI attack surface and ensures consistent experience. |
| 12 | App Check (Play Integrity provider) — documented for prod | Production deployments must enable App Check before public release. |

---

## 5. API and Service Layer

| Service | Responsibility |
|---|---|
| **AuthService** | Wraps Firebase Auth phone OTP. Exposes `verifyPhoneNumber`, `confirmOTP`, `signOut`, `deleteAccount` (anonymises Firestore data). |
| **FirestoreService** | All Firestore reads/writes. Methods: `searchSellers`, `getSellerById`, `getReportsForSeller`, `submitReport`, `submitReview`, `registerSeller`, `createOrUpdateUser`, `getAdminStats`, `getAllReports`, `updateReportStatus`, `logAdminAction`, etc. Each method is wrapped in `try/rethrow`. |
| **StorageService** | Evidence upload to Firebase Storage with size validation. Returns download URL. |
| **TrustScoreService** | Pure algorithm — input: seller + reports + reviews. Output: double score + verdict string. Testable in isolation (no Firebase). |
| **NotificationService** | FCM initialisation, token persistence, foreground/background message handlers. |
| **AnalyticsService** | Event logging — never logs PII (phone, eSewa, handles). Only categorical data. |
| **SeedDataService** | Debug-mode-only generator for 5 demo sellers, 12 reports, 50+ reviews. |

### Provider graph (Riverpod)

```
languageProvider (StateNotifier)
authStateProvider (StreamProvider → User?)
currentUserProvider (FutureProvider → UserModel?)
firestoreServiceProvider (Provider → FirestoreService)
trustScoreServiceProvider (Provider → TrustScoreService)
adminStatsProvider (FutureProvider.autoDispose → Map)
adminReportsProvider (FutureProvider.autoDispose.family → List<ReportModel>)
adminSellersProvider (FutureProvider.autoDispose → List<SellerModel>)
```

---

## 6. Testing Coverage

### What is tested

- **`trust_score_service_test.dart`** — 12 tests covering: range guarantees, verification bonuses, report effects, recency multiplier, dispute response, account age, review authenticity weighting, decimal rounding, and all three verdict thresholds.
- **`validators_test.dart`** — 18 tests covering: Nepal phone validation (valid prefixes, invalid lengths, non-digit stripping), HTML sanitisation, `@` stripping, description length, positive amount, business name length, eSewa optionality.

### What is NOT tested (and why)

- **Firestore reads/writes** — require `fake_cloud_firestore` mocks; out of scope for thesis MVP.
- **FCM message handling** — requires emulator + remote payload; manual smoke tested instead.
- **UI widgets** — covered by the in-app onboarding/preview manual test plan in the thesis report.

Run tests with:

```bash
flutter test test/unit/
```

---

## 7. Known Limitations and Future Work

| Limitation | Roadmap |
|---|---|
| No Cloud Functions deployed yet (algorithm runs client-side) | Wire `onReportCreated` and `onReviewCreated` triggers to recalculate scores server-side; remove client trust to write. |
| No App Check in production | Enable Play Integrity provider before Play Store release. |
| No email/social auth fallback | Add Google Sign-in as a secondary path for users without phones. |
| Bilingual coverage is EN/Nepali only | Add Maithili and Newari per Nepal demographic distribution. |
| Trust algorithm is rule-based | Train an XGBoost classifier on labelled fraud reports once we have ≥10k labelled samples. |
| No payment integration | Future versions could mediate eSewa transactions with held-funds escrow. |
| No web admin panel | Admin actions today require building an Android-only client; a Firebase Hosting web app would scale better. |
| FCM relies on Firebase project quota | Move to dedicated topic-based broadcast for community-wide scam alerts. |
| Image compression skipped | Add `flutter_image_compress` for sub-200 KB evidence uploads. |
| No offline cache (Hive) | Hive caching for last-20 searched sellers is a 1-day task. |

---

## 8. Thesis Defense Talking Points

1. **Genuine local relevance.** This thesis addresses a problem affecting tens of thousands of Nepali social-media buyers monthly — the lack of any verification layer between TikTok/Instagram sellers and eSewa/Khalti payments.

2. **Original trust score contribution.** The five-factor weighted algorithm with recency-decay is original work derived from the literature on review-spam detection and credit-risk scoring, adapted to Nepal's social-commerce context.

3. **Production-grade security design.** Firestore rules enforce least-privilege at field-level granularity. Trust score fields are server-locked even for authenticated users. Storage uploads are scoped, typed, and size-limited.

4. **Clean Architecture with strict layering.** The presentation layer cannot reach Firebase directly — all access flows through service interfaces. This makes the trust algorithm testable without any Firebase emulator.

5. **Bilingual from day one.** Nepali (Devanagari) and English are first-class, with Noto Sans Devanagari rendering and a single `AppStrings.get(key, lang)` API. The chatbot answers in either language based on user preference.

6. **Genuine accessibility commitment.** Minimum 48 px tap targets, 4.5:1 contrast on all text, colour-plus-icon for every status, semantic widget labels.

7. **Ethical hacking lens.** As a cybersecurity student, I prioritised threat modelling: report-bombing rate limits, anti-impersonation reporterId checks, signed-URL evidence access, immutable audit logs, HTML stripping, App Check planning for prod.

8. **MVP that scales.** Riverpod's autoDispose + paginated Firestore queries + skeleton loaders + offline-aware UI patterns mean the same codebase can serve 100 or 100,000 users without re-architecture.

9. **Bilingual AI assistant.** The in-app SafeBuy Assistant chatbot answers fraud-prevention questions in either language using a curated knowledge base — no LLM dependency, fully offline-capable.

10. **Real-world deployable.** Privacy Policy, Terms of Service, account deletion, FCM tokens, analytics, admin moderation, security rules, and seed data for live demo — every artefact expected of a production app exists in the repository.

---

## Appendix — Run, Build, Deploy

```bash
# Run
flutter pub get
flutter run

# Test
flutter test test/unit/

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Firestore rules only (Firebase Storage is NOT used — see below)
# firebase deploy --only storage   ← obsolete, storage moved to Supabase

# Build release APK
flutter build apk --release
```

## Storage Architecture — Hybrid Cloud

SafeBuy Nepal uses a hybrid cloud architecture:
- Firebase: Phone OTP Auth, Google Sign In,
  Firestore database, security rules
- Supabase: All file storage (KYC documents,
  evidence photos, review images, QR codes,
  profile photos)

Supabase Project: safebuy-nepal
Region: South Asia (Mumbai) — ap-south-1
Account: adhisage69@gmail.com

Reason for hybrid approach:
Firebase Storage requires Blaze billing plan which
could not be activated due to payment gateway
restrictions between Google Cloud and Nepali banking
infrastructure (OR_BACR2_44 error). Supabase Storage
provides equivalent functionality with a generous
free tier (1GB storage, 2GB bandwidth) accessible
without international payment requirements.

Supabase Storage buckets:
- kyc-documents (private, 10MB): KYC verification docs
- evidence-files (private, 10MB): Fraud report evidence
- review-images (public, 5MB): Product review photos
- qr-codes (public, 2MB): Seller eSewa QR codes
- profile-images (public, 5MB): User profile photos

All images compressed to max 800px width, quality 75
before upload. Private files use 1-year signed URLs.
Public files use permanent public URLs.

Implementation notes:
- `lib/core/config/supabase_config.dart` holds the project URL,
  publishable (anon) client key, and bucket names.
- `lib/services/storage_service.dart` is the single upload facade
  (Supabase); `KycService` delegates its uploads to it.
- Because users authenticate with Firebase (not Supabase Auth),
  the app talks to Supabase under the `anon` role. Bucket RLS
  policies are therefore bucket-scoped anon-insert with no client
  UPDATE/DELETE (immutable evidence); private buckets are readable
  only through signed URLs. See
  `lib/core/config/supabase_policies.sql` (run OPTION B in the
  Supabase SQL editor).

End of document.
