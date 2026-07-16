# SafeBuy Nepal — Next Build Prompt & Handoff

Paste this whole file into a new session to continue the build. It contains
(1) the current project state, (2) everything you must know about the codebase,
and (3) the full feature spec to implement.

---

## 0. HOW TO USE THIS FILE

You are the lead developer of **SafeBuy Nepal**. Read `Section 1` (current
state) and `Section 2` (codebase facts) first, then implement `Section 3`
(the features) in the stated priority order.

- Project root: `C:\Users\SAGESH\Desktop\claude-projects\safebuy_nepal`
- Read the relevant existing files before editing them.
- Fix every analyzer error automatically. Do not stop until complete.
- After every feature: run `flutter analyze` (0 issues required).
- The emulator on this machine is unreliable/slow — do NOT block on it.
  Validate with `flutter analyze`, `flutter test`, and `flutter build apk`.

---

## 1. CURRENT STATE (as of this handoff)

**Quality baseline:** `flutter analyze` = 0 issues · `flutter test` = 128/128
pass · debug + release APK both build.

**Architecture: PURE FIREBASE** (Supabase was tried and fully removed).
- Firebase Auth (phone OTP + Google Sign-In), Cloud Firestore, Firebase
  Storage (Blaze active), Cloud Functions (Node 20).
- App ID: `com.sagesh.safebuy.safebuy_nepal` · min SDK 21 · multiDex on.

**⚠ UNCOMMITTED CHANGES that must be verified + committed FIRST:**
A just-applied OTP fix is on disk but NOT yet committed. Before new work:
1. `flutter pub get` (pubspec added `integration_test` dev dependency)
2. `flutter analyze` → expect 0 issues
3. `flutter test` → expect 128 pass
4. Commit these files:
   - `lib/main.dart` — added `if (kDebugMode) FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);` after `Firebase.initializeApp` (+ `flutter/foundation.dart` import)
   - `lib/features/auth/presentation/screens/auth_screen.dart` — `sendOtp(phone)` now passes the BARE number
   - `lib/features/auth/presentation/screens/otp_screen.dart` — `sendOtp(widget.phone)` bare number + a `ref.listen(authNotifierProvider,…)` that shows send-failures
   - `integration_test/otp_flow_test.dart` (new) · `pubspec.yaml`

**The OTP root-cause bug that was fixed (context):** the UI double-prefixed
`+977`. Screens called `sendOtp('+977$phone')` and `AuthService.verifyPhoneNumber`
ALSO prepends `+977` (`phoneNumber: '+977$phone'`), producing
`+977+9779876543210` → Firebase rejected the malformed number → no SMS ever
sent, and the OTP screen wasn't listening for the error so it looked like
"OTP never arrives." Now fixed. **Keep the invariant: pass the bare 10-digit
number everywhere; only `AuthService` adds `+977`.**

**Firebase test setup (already partly done by the user):**
- Console → Auth → Phone test number `+977 9876543210` → code `123456` exists.
- Debug SHA-1: `54:91:7B:24:E2:B7:A5:F2:C9:CE:03:FC:1F:AA:32:1C:C3:3E:B5:C3`
- Debug SHA-256: `C4:07:2B:ED:06:DC:68:42:6F:4F:9B:5D:F0:66:2C:66:0E:D5:CC:E3:52:1F:BE:76:58:21:5E:AC:FD:EF:CB:36`
  (User still needs to paste SHA-1 into Firebase → Project Settings → Android
  app → Add fingerprint, then re-download `google-services.json`, for real-SMS
  on release. Debug builds work with the test number without it.)

**Deploy pipeline:** GitHub `ctrl-sagesh/safebuy_nepal` → Vercel auto-deploys
the `website/` folder to https://safebuy-nepal.vercel.app on every push to
`main`. Release APK is copied to `Desktop\SafeBuyNepal.apk` and
`website/SafeBuyNepal.apk` (the site's Download button).

---

## 2. CODEBASE FACTS (conventions you MUST follow)

### Design system
- Colors: `lib/core/theme/app_colors.dart` (`AppColors.*`). Primary `#1565C0`,
  primaryDark `#0D47A1`, trusted `#00B850/00C853`, unverified `#FF8F00`,
  highRisk `#D32F2F/E23B3B`, bgSecondary `#F5F7FA`. NEVER hardcode hex — use
  `AppColors`. Gradients: `AppColors.heroGradient`, `primaryGradient`,
  `trustGradient`, `riskGradient`.
- Fonts via `google_fonts`: Poppins (headings), Inter (body), Noto Sans
  Devanagari (Nepali).
- Theme: `lib/core/theme/app_theme.dart`.

### Feedback / popups — ALWAYS use these (no silent failures)
`lib/core/utils/popup_helper.dart` → `PopupHelper.showSuccess/showError/
showWarning/showInfo/showConfirmDialog/showLoadingDialog/hideLoadingDialog/
showBottomSheet/showAuthGateBottomSheet`. Guests hitting a gated action get
`showAuthGateBottomSheet`.

### Validators
`lib/core/utils/validators.dart` → `Validators.nepaliPhone/panNumber/gmail/otp/
socialHandle/fullName/reportDescription/positiveAmount/…` (return null on OK).

### Config
`lib/core/config/app_config.dart` → `AppConfig.showDemoFeatures` (== kDebugMode),
`appVersion`, `buildNumber`, demo seller phones (`demoTrustedSeller` etc.).

### Storage (Firebase) — single facade
`lib/services/storage_service.dart` — STATIC methods:
`StorageService.uploadKycDocument/uploadEvidence/uploadReviewImage/uploadQrCode/
uploadProfileImage(...)` and `deleteFile(downloadUrl)`. All compress via
`flutter_image_compress` (800px, q75). Paths mirror `storage.rules`
(`kyc/…`, `evidence/…`, `review_images/…`, `qr_codes/…`, `profiles/…`).
`KycService` (`lib/services/kyc_service.dart`) delegates uploads to it.

### Data models (`lib/models/`)
- `seller_model.dart` — has KYC fields: `kycStatus`, `verificationTier`
  ('none'|'basic'|'verified'|'premium'), `panNumber`, `qrCodeUrl`,
  `safebuyCardId` (SBV-2026-XXXXX), `verificationDate`, `verificationExpiry`,
  `verificationDistrict`, plus getters `isKycVerified`, `isReverificationOverdue`,
  `tierLabel`, `maskedPan`. Trust: `trustScore` (double), `trustVerdict`
  ('trusted'|'unverified'|'high_risk'), `accountCreatedAt`, `scamReportCount`.
- `report_model.dart` — `reportId, reporterId, sellerId, sellerPhone,
  sellerSocialHandle, platform, incidentType, amountLost, description,
  incidentDate, paymentScreenshotUrl, chatScreenshotUrl, submittedAt, status,
  sellerResponse`, getter `anonymizedReporter`.
- `review_model.dart` — + `productImageUrl, productName, productRating, isTopReview`.
- `kyc_submission_model.dart`, `leaderboard_model.dart`.

### Services
- `firestore_service.dart` — `firestoreServiceProvider` (Riverpod). Methods:
  `searchSellers/searchSeller/getSellerById/registerSeller/getReportsForSeller/
  submitReport/addSellerResponse/getReviewsForSeller/submitReview/
  createOrUpdateUser/getUserById/checkReportRateLimit/…`.
- `auth_service.dart` + `features/auth/presentation/providers/auth_provider.dart`
  (`authNotifierProvider` with `AuthState{status,verificationId,errorMessage}`
  and `AuthStatus{idle,sendingOtp,otpSent,verifying,verified,error}`;
  `.sendOtp(barePhone)` / `.verifyOtp(otp)`).
- `google_auth_service.dart` (google_sign_in v7 API), `seed_data_service.dart`
  (`SeedDataService.seedDatabase()` — 5 demo sellers with fixed doc ids
  `seed_priya_fashions` etc.), `notification_service.dart`, `kyc_service.dart`,
  `leaderboard_service.dart`, `cyber_bureau_service.dart`, `trust_score_service.dart`,
  `analytics_service.dart`.

### Shared widgets
`lib/core/widgets/` → `verification_card.dart` (`SafebuyVerificationCard` +
`TierStyle` helper: `.color/.icon/.label/.cardGradient/.borderColor`),
`nepal_logo.dart` (`NepalLogo(size:)` CustomPainter), plus custom_button,
custom_text_field, empty_state_widget, error_state_widget, skeleton_loader,
seller_trust_badge, auth_gate_sheet, section_header.

### Routing (all in `lib/main.dart`, `onGenerateRoute`)
Add a route by adding a `case '/x': return _route(const XScreen(), settings);`.
`_route(...)` already does slide+fade page transitions. Args come via
`settings.arguments as Map<String,dynamic>`. Protected routes (require login,
else auth-gate) are in the `_protected` set: `/report, /register-business,
/kyc*`. Existing routes: `/splash /onboarding /auth /auth/otp
/auth/profile-setup /home /search /alerts /profile /seller /seller/card
/seller/review /report /report/success /register-business /kyc /kyc/gmail
/kyc/qr /kyc/selfie /kyc/pan /kyc/location /kyc/submitted /kyc/change-qr
/leaderboard /guide /scam-news /notifications /privacy /terms /about
/admin /admin/kyc /safeguard`.

### Navigation shell
`MainAppScreen` in `main.dart` = 4-tab `IndexedStack` (Home · Verify · Alerts ·
Profile), `NavigationBar` height 64, `onlyShowSelected` labels. IndexedStack
already preserves tab state (no KeepAlive needed). No chatbot FAB — SafeGuard
AI is a help icon in the Home app bar (`/safeguard`).

### Existing feature screens (already built — extend these, don't recreate)
- `features/splash/splash_screen.dart` (staged animation, particles)
- `features/onboarding/onboarding_screen.dart` (4 illustrated slides)
- `features/auth/presentation/screens/{auth_screen,otp_screen,profile_setup_screen}.dart`
- `features/home/presentation/screens/home_screen.dart` (hero, quick actions,
  featured sellers, alerts, safety tips carousel, notification bell w/ badge)
- `features/search/presentation/screens/search_screen.dart` (verification-card
  results, not-found card, demo quick-search chips in debug)
- `features/sellers/presentation/screens/seller_profile_screen.dart`
  (SliverAppBar, animated trust arc, Reviews/Reports/About tabs, card preview,
  fixed bottom Report bar) ← Features 1,3,7,8 attach here
- `features/kyc/` (intro, gmail, qr, selfie, pan, location, submitted,
  verification_card, qr_change) + `kyc_draft.dart` (KycUploadZone, KycStepHeader,
  KycBottomBar, pickKycImage)
- `features/reports/presentation/screens/{incident_report_screen,report_success_screen}.dart`
- `features/reviews/presentation/screens/write_review_screen.dart`
- `features/leaderboard/…/leaderboard_screen.dart`
- `features/guide/…/how_it_works_screen.dart`
- `features/alerts/presentation/screens/{alerts_screen,scam_news_screen}.dart`
  ← Feature 5 links from Alerts header
- `features/profile/presentation/screens/{profile_screen,about_screen}.dart`
  (profile has debug-only Developer Options → Seed Demo Data)
- `features/legal/{privacy_policy_screen,terms_screen}.dart` ← Feature 1 lives near here
- `features/admin/presentation/screens/{admin_dashboard_screen,admin_kyc_screen,…}.dart`
- `features/notifications/notifications_screen.dart`

### Reference data
`lib/core/data/nepal_scam_data.dart` → `NepalScamNewsData.scamCases` (10),
`scamStats` (6), `legalFramework` (5 laws w/ section+penalty). Reuse for
Features 1 & 5.

### Seed sellers (phones for demos)
Priya Fashions 9841234567 (87 trusted) · TechNepal 9851234568 (82 trusted) ·
Sunset Cosmetics 9861234569 (64 unverified) · QuickBuy 9871234570 (31 high
risk) · FastDeal Nepal 9881234571 (18 high risk).

### Test suite location
`test/unit/`, `test/widget/new_screens_smoke_test.dart`,
`integration_test/otp_flow_test.dart`. Keep tests green; add smoke tests for
new Firebase-free screens.

---

## 3. FEATURES TO BUILD (implement in this PRIORITY ORDER)

Add packages to `pubspec.yaml` as each feature needs them, run
`flutter pub get`, and `flutter analyze` after each. New deps across all
features: `pdf`, `printing`, `url_launcher`, `mobile_scanner`.
(Note: `mobile_scanner` needs camera permission in
`android/app/src/main/AndroidManifest.xml` + a usage string; min SDK is already
21 — check mobile_scanner's required minSdk and bump if needed.)

### FEATURE 1 — Cybercrime Bureau Report Generator  ★ HIGHEST PRIORITY
File: `lib/features/legal/presentation/screens/cybercrime_report_screen.dart`
Route: `/cybercrime-report` (pass `{reportId, sellerId}` args). Packages:
`pdf, printing, url_launcher`.

Entry point: on `seller_profile_screen.dart`, show an **"Escalate to Nepal
Police"** button ONLY when `seller.trustVerdict == 'high_risk'` AND the current
authenticated user has ≥1 report against this seller (check via
`firestoreService.getReportsForSeller` filtered by `reporterId == uid`).

Screen sections:
1. Bureau info card (blue gradient): Nepal Police Cybercrime Investigation
   Bureau · Naxal, Kathmandu · Phone 01-4412323 (tappable `tel:`) · Email
   cybercrime@nepalpolice.gov.np (tappable `mailto:`) · Sun–Fri 10am–5pm.
2. Complaint form, auto-filled where possible:
   - Your info: full name (user profile), phone (masked), address (textfield),
     district (Nepal district dropdown).
   - Incident (from the report): seller identifier, platform, date, amount lost,
     description.
   - SafeBuy reference: "SafeBuy Nepal Report ID: RPT-2026-XXXXX".
   - Applicable law (radio): ETA 2063 §47 (Computer Fraud), §48 (Electronic
     Fraud — advance payment), Consumer Protection Act 2075 §11 (misleading ads).
   - Evidence summary chips: payment/chat screenshot Attached (green) / Not
     provided (red).
   - Declaration checkbox (required): "I declare this information is true…
     filing a false complaint is an offence under the laws of Nepal."
3. Button A "Email Complaint to Nepal Police" → `url_launcher` `mailto:` with
   To=cybercrime@nepalpolice.gov.np, Subject="Cybercrime Complaint - Social
   Commerce Fraud - SafeBuy Nepal Report [RPT-ID]", Body = the full formatted
   complaint (see the exact template in the original spec — CYBERCRIME
   COMPLAINT header, complainant details, incident details, description,
   evidence note, applicable law, request for investigation, signature,
   "Filed via SafeBuy Nepal").
4. Button B "Save as PDF" → build with `pdf`/`printing`, same content, SafeBuy
   header, save to device, then showSuccess "PDF saved. Bring it to Naxal
   office in person."
5. Success screen after email: animated checkmark, "Complaint Sent to Nepal
   Police", reference number, 3 numbered next-step cards (ack in 3–5 days;
   may be called to Naxal 01-4412323; keep original screenshots safe).

### FEATURE 2 — QR Code Scanner  ★ SECOND
File: `lib/features/search/presentation/screens/qr_scan_screen.dart`. Package:
`mobile_scanner`. Full-screen camera + white animated scan frame + moving scan
line + "Scan seller's eSewa or Khalti QR code" + Cancel. On scan: extract a
phone number from the QR payload → pop back to Search with the number
pre-filled and auto-trigger the search. On failure: shake frame + "Could not
read QR code / Try typing the phone number manually." Add a QR icon on the
RIGHT of the Search bar in `search_screen.dart` that opens this screen.

### FEATURE 6 — Festival Fraud Alert  ★ THIRD
File: `lib/core/services/festival_alert_service.dart`. Gregorian-approx
windows: Dashain Oct1–20, Tihar Oct20–Nov10, Holi Mar1–30, Nepali New Year
Apr10–20, Teej Aug20–Sep10, Chhath Oct25–Nov5. On app start, if today is in a
window, show a dismissible red-gradient banner (`#DC143C`→`#8B0000`) below the
home hero: "[Festival] Season Fraud Alert / Fraud complaints increase 340%
during festivals. Verify every seller before paying." + "Verify a Seller Now"
→ Search tab. Slide-down+fade entrance. Show once per session; reappears next
session if still in-window.

### FEATURE 3 — WhatsApp Fraud Warning Share  ★ FOURTH
On high-risk seller profiles, directly below the red HIGH RISK banner, two
buttons: "Share on WhatsApp" (`url_launcher` `whatsapp://send?text=<encoded>`,
fallback = copy to clipboard + showSuccess "Warning text copied…") and "Copy
Warning Text". Message: "FRAUD WARNING — SafeBuy Nepal\nSeller: […]\nPlatform:
[…]\nTrust Rating: HIGH RISK — [score]/100\nFraud Reports: [n]\nAmount Reported
Lost: NPR [total]\n\nCheck any seller before paying:\nsafebuynepal.com\n\n—
Shared via SafeBuy Nepal".

### VISUAL IDENTITY — apply throughout (see Section 4)

### FEATURE 4 — "Before You Pay" checklist
When search returns an UNVERIFIED seller (score 50–79), show a card below the
result: "Unverified Seller — Check These Before Paying" with 5 tappable
checklist rows (video call of product; check IG/TikTok comments; small test
order < NPR 500; screenshot profile+QR before paying; never pay full before
dispatch). Progress "X of 5 completed"; all-checked → green "You have completed
all safety steps / You are better protected now." Dismiss "I understand the
risks" (per-seller per-session dismissed state).

### FEATURE 5 — Nepal Fraud Statistics Dashboard
File: `lib/features/stats/presentation/screens/nepal_fraud_stats_screen.dart`.
Route `/nepal-stats`; link from the Alerts tab header ("Nepal Fraud Data").
DARK theme for this screen only (bg `#0D2137`, cards `#1A3A5C`, accents
`#1565C0`/`#C62828`). Sections: LIVE SafeBuy data (4 animated counters from
Firestore: total reports, total NPR lost, high-risk sellers, verified sellers)
· Official Nepal Police data (fl_chart line 2020–2024 with 340% spike at 2023 +
4 stat boxes 340%/NPR40Cr/560%/2400+) · fraud-type donut (PieChart 35/28/20/12/5)
· platform bar chart (TikTok/Instagram/Facebook) · 3 expandable legal cards
(ETA §47, §48, CPA 2075) · bottom CTA mailto cybercrime bureau. Use
`fl_chart` (already a dep) and `NepalScamNewsData`.

### FEATURE 7 — Seller Response Countdown
On a verified seller's profile, below the Reports tab header: if there's an
unresponded report, amber card "Seller has [X] hours to respond" + progress bar
(48h from `report.submittedAt`). If responded → hide. If >48h no response → red
card "Seller did not respond within 48 hours / This negatively affects their
trust rating." Show hours+minutes remaining.

### FEATURE 8 — Seller Loyalty Badges
From `accountCreatedAt` with zero reports: 6mo → "6 Month Clean Record"
(bronze), 1yr → "1 Year Trusted" (silver), 2yr → "2 Year Elite Seller" (gold).
Medal-pill design; show in the profile verification-badges row and on the seller
card in search results when earned.

---

## 4. VISUAL IDENTITY — Nepal-themed animations (apply app-wide)

1. `DhakaPatternPainter` CustomPainter — repeating diamond/rhombus (Nepali
   Dhaka fabric), subtle: home hero (white, opacity .06), seller header (.04),
   splash (.08); slowly shifts over 10s.
2. Trust-badge glow: GREEN pulse opacity .3→.6 + scale 1→1.03, 2s; RED faster
   1.2s more intense; AMBER white shimmer sweep 3s.
3. Search result entrance: slide up 40px + fade, dampened elasticOut 600ms,
   100ms stagger for multiple.
4. Score circle: arc 0→score 800ms easeOutCubic, number counts up, color by
   band (red/amber/green), settle pulse 1→1.05→1.
5. Report success confetti: Nepal red `#DC143C` + blue `#003893` + white, mix
   rectangle+shield shapes, 4s, 150 pieces.
6. Home "Quick Safety Tips": continuous left-scrolling row of 5 tip cards,
   touch to pause (tips listed in spec).
7. Verification card shine: white gradient sweep L→R every 5s.
8. Page transitions: push slide-right+fade 250ms, pop slide-left+fade 200ms,
   bottom sheets spring-up, dialogs scale-from-center spring.
9. Bottom-nav active: icon bounce up 4px spring 300ms + pill scale-in.
10. Skeleton shimmers: blue tint `#EFF6FF`→`#DBEAFE`.
11. Tasteful tiny 🇳🇵 accent on splash corner, About header, cybercrime PDF
    footer, Nepal stats header.

Keep the existing `_route` transition in `main.dart` as the source of truth for
#8 (upgrade it rather than adding per-screen transitions).

---

## 5. WEBSITE ADDITIONS (`website/index.html` + `style.css`)

Append two sections (match the existing white/blue design system & animation
patterns; the site uses `data-en`/`data-ne` bilingual attributes and
`.reveal` scroll animations):

- **"SafeBuy Nepal + Nepal Police"** (dark navy `#0D2137`): heading "Your
  Report Can Lead to Legal Action"; 4-step horizontal flow (Submit report →
  Evidence preserved → Generate complaint PDF → Send to Cyber Bureau); contact
  card (Naxal, Kathmandu · 01-4412323 · cybercrime@nepalpolice.gov.np); quote
  box on ETA 2063 §48 (up to 3 years imprisonment).
- **"Nepal Social Commerce Fraud by Numbers"**: animated counters
  340% / NPR 40Cr / 560% / 2400+ (reuse the existing counter pattern), source
  "Nepal Police Annual Report 2023", note "SafeBuy Nepal is building the
  evidence database that makes law enforcement possible."

After editing, bump the `?v=N` query on `style.css`/`app.js` in `index.html`,
commit, push (Vercel auto-deploys). The site's live URL is
https://safebuy-nepal.vercel.app.

---

## 6. FINAL REQUIREMENTS (run at the end)
1. `flutter pub get`
2. `dart fix --apply` (may hit a transient Windows perf-file lock — rerun or
   ignore if `flutter analyze` is already clean)
3. `flutter analyze` → **0 issues required**
4. `flutter test` → all pass (add smoke tests for new no-Firebase screens)
5. `flutter build apk --release` → report APK size
6. Copy the APK to `Desktop\SafeBuyNepal.apk` and `website/SafeBuyNepal.apk`
7. Commit + push (co-author line: `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`)
8. Report every file created/modified + APK size + manual steps.

---

## 7. GOTCHAS (learned the hard way)
- **OTP:** pass bare 10-digit numbers; only `AuthService` adds `+977`. Debug
  build has `appVerificationDisabledForTesting=true`, so ONLY Firebase test
  numbers work in debug (real SMS is release-only + needs SHA-1). Test with
  `9876543210` / `123456`.
- **Emulator is unreliable here** — often boots `offline`. Prefer analyze/test/
  build for verification; the user tests on a real phone via USB.
- **Firebase Storage paths must match `storage.rules`** — don't invent new ones.
- **google-services.json only has `com.sagesh.safebuy.safebuy_nepal`** — do NOT
  add a `.debug` applicationIdSuffix (breaks the google-services build step).
- **url_launcher on Android 11+** needs `<queries>` intents in the manifest for
  `tel:`, `mailto:`, `https`, and `whatsapp://` — add them or launches fail
  silently.
- Line endings: repo warns LF→CRLF on Windows; harmless.
- Docs already in repo: `TECHNICAL_DOCUMENTATION.md`, `README_DEVELOPMENT.md`,
  `DEMO_GUIDE.md`.
