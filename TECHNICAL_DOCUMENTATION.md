# SafeBuy Nepal â€” Technical Documentation

**Project:** Community-Driven Seller Trust Verification and Fraud Reporting Platform for Nepali Social Media Buyers
**Author:** Sagesh Adhikari, BSc (Hons) Ethical Hacking and Cybersecurity, Softwarica College, Coventry University UK
**Year:** 2026 (Final Year Thesis)
**Stack:** Flutter 3.41.9 Â· Dart 3.11.5 Â· Firebase (Firestore, Auth, Storage, Messaging) Â· Riverpod 2.x

---

## 1. System Architecture Overview

SafeBuy Nepal is built on **Clean Architecture** principles with strict layer separation, ensuring that domain logic is testable in isolation and the UI can be swapped without rewriting business rules.

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                    PRESENTATION LAYER                        â”‚
â”‚  â€¢ Screens (Stateless / ConsumerStateful Widgets)            â”‚
â”‚  â€¢ Riverpod Providers (state + side effects)                 â”‚
â”‚  â€¢ Core widgets (CustomButton, SellerTrustBadge, etc.)       â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                               â”‚  watches/reads
                               â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                       DOMAIN LAYER                           â”‚
â”‚  â€¢ Models with toMap/fromMap/copyWith/Equatable              â”‚
â”‚  â€¢ Use cases (called via providers)                          â”‚
â”‚  â€¢ Repository interfaces (abstract)                          â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                               â”‚  implements
                               â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                        DATA LAYER                            â”‚
â”‚  â€¢ Repository implementations                                â”‚
â”‚  â€¢ Service wrappers around Firebase SDKs                     â”‚
â”‚      AuthService Â· FirestoreService Â· StorageService         â”‚
â”‚      TrustScoreService Â· NotificationService                 â”‚
â”‚      AnalyticsService Â· SeedDataService                      â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                               â”‚
                               â–¼
                â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
                â”‚   FIREBASE BACKEND        â”‚
                â”‚   (Cloud Firestore /      â”‚
                â”‚    Auth / Storage / FCM)  â”‚
                â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

### Folder structure

```
lib/
â”œâ”€â”€ core/                 # Design system + cross-cutting utilities
â”‚   â”œâ”€â”€ theme/            # Colors, spacing, text styles, theme
â”‚   â”œâ”€â”€ constants/        # App constants + bilingual strings
â”‚   â”œâ”€â”€ utils/            # Validators, extensions
â”‚   â””â”€â”€ widgets/          # Reusable widgets (10 components)
â”œâ”€â”€ features/             # Feature modules (auth, admin, ...)
â”‚   â””â”€â”€ <feature>/
â”‚       â”œâ”€â”€ data/repositories/
â”‚       â”œâ”€â”€ domain/repositories/
â”‚       â”œâ”€â”€ domain/usecases/
â”‚       â””â”€â”€ presentation/
â”‚           â”œâ”€â”€ providers/
â”‚           â””â”€â”€ screens/
â”œâ”€â”€ models/               # Pure-Dart data models
â”œâ”€â”€ services/             # Firebase service wrappers
â”œâ”€â”€ widgets/              # Legacy widgets (chatbot, seller card)
â”œâ”€â”€ screens/              # Legacy screens being migrated
â”œâ”€â”€ providers/            # Cross-feature providers (language)
â””â”€â”€ main.dart
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

The following seller fields **cannot** be modified from the client SDK â€” only by Cloud Functions or the admin SDK (enforced via Firestore rules):
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
| 1 | Report severity | 40 | Reports are the strongest negative signal â€” they represent real money lost. The 40-point ceiling means even one severe verified report can move a seller from Trusted (â‰¥ 80) to Unverified. |
| 2 | Verification status | 25 | A verified phone, eSewa, and linked social handle materially raises trust. Full badge = 25 pts; phone-only = 18 pts. |
| 3 | Review authenticity | 20 | A weighted average of ratings Ã— authenticity weight. Suspicious accounts (new, spammy, short comments) score 0.2 weight, dropping their reviews' impact. |
| 4 | Dispute resolution | 10 | Sellers who actively respond to disputes earn this bonus. Rate >0.8 = 10 pts. |
| 5 | Account age | 5 | Older accounts have demonstrated continuity. >180 days = 5 pts. |

### Recency multiplier

To prevent a single old incident from permanently destroying a seller's reputation, each report's deduction is multiplied by:

```
< 30 days  â†’ 1.0   (full weight)
< 90 days  â†’ 0.7
â‰¥ 90 days  â†’ 0.4
```

### Verdict thresholds

```
score >= 80  â†’ 'trusted'      (green shield)
score >= 50  â†’ 'unverified'   (orange caution)
score <  50  â†’ 'high_risk'    (red, pulse animation)
```

### Known limitations

1. **No platform-cross-checking yet** â€” the algorithm cannot verify that a TikTok handle is actually owned by the registering user.
2. **Self-reported amounts** â€” buyers state the NPR amount lost without escrow corroboration.
3. **Review brigading** â€” without payment-verified purchase confirmation, coordinated review attacks remain possible. The authenticity weight is the main mitigation.
4. **No machine-learning fraud detection** yet â€” flagging is rule-based.

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
| 12 | App Check (Play Integrity provider) â€” documented for prod | Production deployments must enable App Check before public release. |

---

## 5. API and Service Layer

| Service | Responsibility |
|---|---|
| **AuthService** | Wraps Firebase Auth phone OTP. Exposes `verifyPhoneNumber`, `confirmOTP`, `signOut`, `deleteAccount` (anonymises Firestore data). |
| **FirestoreService** | All Firestore reads/writes. Methods: `searchSellers`, `getSellerById`, `getReportsForSeller`, `submitReport`, `submitReview`, `registerSeller`, `createOrUpdateUser`, `getAdminStats`, `getAllReports`, `updateReportStatus`, `logAdminAction`, etc. Each method is wrapped in `try/rethrow`. |
| **StorageService** | Evidence upload to Firebase Storage with size validation. Returns download URL. |
| **TrustScoreService** | Pure algorithm â€” input: seller + reports + reviews. Output: double score + verdict string. Testable in isolation (no Firebase). |
| **NotificationService** | FCM initialisation, token persistence, foreground/background message handlers. |
| **AnalyticsService** | Event logging â€” never logs PII (phone, eSewa, handles). Only categorical data. |
| **SeedDataService** | Debug-mode-only generator for 5 demo sellers, 12 reports, 50+ reviews. |

### Provider graph (Riverpod)

```
languageProvider (StateNotifier)
authStateProvider (StreamProvider â†’ User?)
currentUserProvider (FutureProvider â†’ UserModel?)
firestoreServiceProvider (Provider â†’ FirestoreService)
trustScoreServiceProvider (Provider â†’ TrustScoreService)
adminStatsProvider (FutureProvider.autoDispose â†’ Map)
adminReportsProvider (FutureProvider.autoDispose.family â†’ List<ReportModel>)
adminSellersProvider (FutureProvider.autoDispose â†’ List<SellerModel>)
```

---

## 6. Testing Coverage

### What is tested

- **`trust_score_service_test.dart`** â€” 12 tests covering: range guarantees, verification bonuses, report effects, recency multiplier, dispute response, account age, review authenticity weighting, decimal rounding, and all three verdict thresholds.
- **`validators_test.dart`** â€” 18 tests covering: Nepal phone validation (valid prefixes, invalid lengths, non-digit stripping), HTML sanitisation, `@` stripping, description length, positive amount, business name length, eSewa optionality.

### What is NOT tested (and why)

- **Firestore reads/writes** â€” require `fake_cloud_firestore` mocks; out of scope for thesis MVP.
- **FCM message handling** â€” requires emulator + remote payload; manual smoke tested instead.
- **UI widgets** â€” covered by the in-app onboarding/preview manual test plan in the thesis report.

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
| Trust algorithm is rule-based | Train an XGBoost classifier on labelled fraud reports once we have â‰¥10k labelled samples. |
| No payment integration | Future versions could mediate eSewa transactions with held-funds escrow. |
| No web admin panel | Admin actions today require building an Android-only client; a Firebase Hosting web app would scale better. |
| FCM relies on Firebase project quota | Move to dedicated topic-based broadcast for community-wide scam alerts. |
| Image compression skipped | Add `flutter_image_compress` for sub-200 KB evidence uploads. |
| No offline cache (Hive) | Hive caching for last-20 searched sellers is a 1-day task. |

---

## 8. Thesis Defense Talking Points

1. **Genuine local relevance.** This thesis addresses a problem affecting tens of thousands of Nepali social-media buyers monthly â€” the lack of any verification layer between TikTok/Instagram sellers and eSewa/Khalti payments.

2. **Original trust score contribution.** The five-factor weighted algorithm with recency-decay is original work derived from the literature on review-spam detection and credit-risk scoring, adapted to Nepal's social-commerce context.

3. **Production-grade security design.** Firestore rules enforce least-privilege at field-level granularity. Trust score fields are server-locked even for authenticated users. Storage uploads are scoped, typed, and size-limited.

4. **Clean Architecture with strict layering.** The presentation layer cannot reach Firebase directly â€” all access flows through service interfaces. This makes the trust algorithm testable without any Firebase emulator.

5. **Bilingual from day one.** Nepali (Devanagari) and English are first-class, with Noto Sans Devanagari rendering and a single `AppStrings.get(key, lang)` API. The chatbot answers in either language based on user preference.

6. **Genuine accessibility commitment.** Minimum 48 px tap targets, 4.5:1 contrast on all text, colour-plus-icon for every status, semantic widget labels.

7. **Ethical hacking lens.** As a cybersecurity student, I prioritised threat modelling: report-bombing rate limits, anti-impersonation reporterId checks, signed-URL evidence access, immutable audit logs, HTML stripping, App Check planning for prod.

8. **MVP that scales.** Riverpod's autoDispose + paginated Firestore queries + skeleton loaders + offline-aware UI patterns mean the same codebase can serve 100 or 100,000 users without re-architecture.

9. **Bilingual AI assistant.** The in-app SafeBuy Assistant chatbot answers fraud-prevention questions in either language using a curated knowledge base â€” no LLM dependency, fully offline-capable.

10. **Real-world deployable.** Privacy Policy, Terms of Service, account deletion, FCM tokens, analytics, admin moderation, security rules, and seed data for live demo â€” every artefact expected of a production app exists in the repository.

---

## Appendix â€” Run, Build, Deploy

```bash
# Run
flutter pub get
flutter run

# Test
flutter test test/unit/

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage

# Build release APK
flutter build apk --release
```

## Storage Architecture â€” Pure Firebase (Blaze)

SafeBuy Nepal runs entirely on Firebase:
- Firebase Auth: Phone OTP + Google Sign In
- Cloud Firestore: all application data, protected by
  deployed security rules
- Firebase Storage: all file uploads (KYC documents,
  fraud evidence, review images, seller QR codes,
  profile photos), protected by deployed storage rules
- Cloud Functions: Node.js 20 runtime (trust-score and
  escalation triggers)

Storage paths (mirrored by storage.rules):
- kyc/{userId}/â€¦                 (private, 10MB): KYC verification docs
- evidence/{userId}/{reportId}/â€¦ (private, 5MB): fraud report evidence
- review_images/{reviewId}/â€¦     (public read, 5MB): product review photos
- qr_codes/{userId}/â€¦            (public read, 2MB): seller eSewa QR codes
- profiles/{userId}/â€¦            (public read, 2MB): user profile photos

All images are compressed client-side (max 800px, quality 75,
flutter_image_compress) before upload. Evidence, KYC, and QR files
are immutable from the client â€” storage rules block deletes to
preserve fraud-record integrity.

`lib/services/storage_service.dart` is the single upload facade;
`KycService`, the report flow, and the review flow all delegate
file uploads to it.


## 12. Law-Enforcement Escalation and Safety Features (v1.1)

### Cybercrime Bureau complaint generator
Route `/cybercrime-report` (auth-protected). Entry point appears on a
high-risk seller profile only when the signed-in user has at least one
report filed against that seller. The screen assembles an official
complaint from the user profile and the report record:

- Complainant details (name, phone masked in UI, address, district
  selected from all 77 districts in `core/data/nepal_districts.dart`)
- Incident details pulled from the ReportModel (seller identifiers,
  platform, date, amount, description, SafeBuy reference RPT-YYYY-XXXXX)
- Applicable law selection: ETA 2063 Section 47 (computer fraud),
  ETA 2063 Section 48 (electronic fraud with advance payment), or
  Consumer Protection Act 2075 Section 11 (misleading advertising)
- Evidence summary chips reflecting stored payment/chat screenshots
- Mandatory truth declaration (false complaints are an offence)

Two outputs: a `mailto:` draft to cybercrime@nepalpolice.gov.np with the
complete formatted complaint body, and a PDF (packages `pdf` + `printing`)
saved to app documents and offered through the system share sheet. The
complaint text never uploads anywhere; it is generated on-device from
data the user already owns.

### QR seller verification
`features/search/.../qr_scan_screen.dart` uses `mobile_scanner` to read
eSewa/Khalti QR payloads and extract a Nepali mobile number with the
pattern `(?:\+?977[-\s]?)?(9[78]\d{8})`. The number is returned to the
Search screen and the trust lookup runs automatically. Camera permission
is declared in the manifest with `android.hardware.camera` marked
optional so the app remains installable on camera-less devices.

### Behavioural safety nets
- Festival fraud banner: `core/services/festival_alert_service.dart`
  holds Gregorian approximations of Dashain, Tihar, Chhath, Holi,
  Nepali New Year, and Teej windows; the Home tab shows a dismissible
  warning while a window is active (once per session).
- Before You Pay checklist: five interactive safety steps rendered
  under every unverified search result with progress tracking and a
  per-seller, per-session dismissal.
- WhatsApp fraud warning: high-risk profiles offer a pre-formatted
  warning message via `whatsapp://send` with clipboard fallback.
- Seller response countdown: verified sellers get a 48-hour window to
  answer the newest complaint; the Reports tab shows a live countdown
  (amber) that turns into a permanent negative marker (red) on expiry.
- Loyalty badges: clean-record medals (6 months bronze, 1 year silver,
  2 years gold) computed from account age and zero reports in
  `core/widgets/loyalty_badge.dart`.

### Nepal fraud statistics dashboard
Route `/nepal-stats`, the only dark-themed screen. Live counters use
Firestore aggregate queries: seller-derived numbers (report totals via
sum of `scamReportCount`, high-risk and KYC-verified counts) work for
guests because the sellers collection is public; the total amount lost
aggregates the `reports` collection and therefore requires sign-in, so
guests see a lock card instead of a misleading zero. Official Nepal
Police figures (2020-2024 complaint line chart, fraud-type donut,
platform bars) come from `core/data/nepal_scam_data.dart` with fl_chart.

## 13. Release Build and Signing (v1.1)

- Signing: `android/upload-keystore.jks` + `android/key.properties`
  (both gitignored; Flutter's default android/.gitignore covers them).
  `build.gradle.kts` loads the keystore when present and falls back to
  debug signing on machines without it, so CI and fresh clones still
  build.
- Shrinking: release builds run R8 with `isMinifyEnabled` and
  `isShrinkResources`; keep rules for Firebase, ML Kit (mobile_scanner),
  and uCrop live in `android/app/proguard-rules.pro`.
- The release certificate's SHA-1 and SHA-256 must be registered in
  Firebase Console (Project Settings, Android app, Add fingerprint) for
  phone-OTP app verification and Google Sign-In to work in release
  builds, then `google-services.json` re-downloaded so it contains the
  generated OAuth client entries.
- Versioning: `pubspec.yaml` `version:` drives versionName/versionCode;
  `AppConfig.appVersion` mirrors it for the About screen.

End of document.
