# SafeBuy Nepal — Complete Product Overview

**What it is:** a community-driven seller trust verification and fraud
reporting platform for Nepali social-media buyers. Android app (Flutter) +
companion website, backed by Firebase. Version 1.1.1.

**The problem it solves:** on TikTok, Instagram and Facebook a Nepali buyer
cannot tell a genuine seller from a scammer before sending an eSewa/Khalti
advance payment. Scammers face no consequences because their fraud history
is invisible and they simply rebrand under new handles. SafeBuy Nepal creates
the missing **shared memory + accountability layer**: search any seller, see a
colour trust verdict before paying, report fraud with evidence, and escalate
serious cases to Nepal Police.

---

## 1. HOW IT WORKS (architecture in plain terms)

- **Frontend:** Flutter (Dart), one Android app, portrait-only, bilingual
  (English + नेपाली). State management with Riverpod. Design system in
  `lib/core/theme`.
- **Backend:** pure Firebase — **Auth** (phone OTP + Google Sign-In),
  **Cloud Firestore** (database), **Storage** (evidence/KYC images),
  **Cloud Functions** (Node 20, server-side triggers), **Messaging** (push).
- **Security model:** Firestore rules make seller profiles publicly readable
  (so anyone can verify) but lock trust-score fields to admin/Cloud Functions
  only, so no one can inflate their own score. Evidence and KYC files are
  write-once (clients can't delete them) to preserve fraud-record integrity.
- **The verdict pipeline:** a buyer searches → the app reads the seller doc →
  the 5-factor algorithm produces a 0–100 score → the score maps to a
  colour verdict (green/amber/red) → the buyer decides before paying.

---

## 2. THE CORE ENGINE

### 2.1 Five-factor Trust Score (0–100)
`lib/services/trust_score_service.dart`. Every seller gets a score from five
weighted factors:

| Factor | Weight | Logic |
|---|---|---|
| Report severity | 40 pts | Deducted for fraud reports. Recent + serious + evidence-backed reports cost the most. `flagged_false` reports are excluded. |
| Verification status | 25 pts | Phone verified, identity (KYC) verified, verified badge. |
| Review authenticity | 20 pts | Genuine positive reviews add; low-authenticity reviews count less. |
| Dispute resolution | 10 pts | Higher response rate to complaints = higher score. |
| Account age | 5 pts | Older accounts earn a small maturity bonus. |

### 2.2 Verdict bands (the colour language)
- **80–100 → 🟢 TRUSTED** (green)
- **50–79 → 🟠 UNVERIFIED** (amber)
- **0–49 → 🔴 HIGH RISK** (red)

This colour verdict is the single most important UX decision: a low-literacy
buyer decides from colour alone, in seconds, before any payment.

### 2.3 Six-layer review integrity (anti-bot)
So nobody can game the score with fake reviews:
1. **Account age** — new accounts wait 7 days before reviewing.
2. **Rate limiting** — max 3 reviews/day, 1-hour cooldown.
3. **Duplicate detection** — one review per seller per user.
4. **Copy-paste detection** — near-identical text is flagged.
5. **Minimum content** — reviews must be 20+ characters.
6. **Credibility weighting** — reviews from established accounts count more.

### 2.4 Four rule-based agents (`lib/agents/`)
No external AI API cost — all deterministic rules:
- **SafeGuard** — the in-app safety assistant (bilingual Q&A).
- **Fraud detector** — flags coordinated attacks, phone recycling, rapid new
  accounts, platform concentration, etc.
- **Seller coach** — nudges sellers (verify phone, link socials, respond to
  reports, milestones).
- **Image analyzer** — sanity-checks evidence screenshots (size, ratio).

---

## 3. EVERY SCREEN — WHAT IT DOES & HOW IT WORKS

### Onboarding & Auth
- **Splash** (`/splash`) — 4-second branded intro (shield logo draws itself,
  Nepal accent, app name, tagline, feature pills, stats). Then routes by
  state: not onboarded → Onboarding; onboarded + logged in/guest → Home;
  else → Auth.
- **Onboarding** (`/onboarding`) — 4 slides: the problem, the solution, the
  community, the choice (account vs guest).
- **Auth** (`/auth`) — phone number (bare 10-digit, app adds +977), "Send
  OTP", Google Sign-In, or Continue as Guest.
- **OTP** (`/auth/otp`) — 6-box code entry, auto-submit, resend timer, shake
  on error. Firebase verifies the code and signs the user in.
- **Profile Setup** (`/auth/profile-setup`) — name, Buyer/Seller role cards
  (blue/green), language, and (for sellers) business name + category. Writes
  the user (and seller) document to Firestore.

### Core buyer flow
- **Home** (`/home`, tab 1) — hero search card, seasonal festival fraud
  banner, active alerts strip, quick actions, trusted-sellers row, scrolling
  safety tips, help (SafeGuard) + notification bell.
- **Search / Verify** (tab 2) — search by phone / eSewa ID / @handle, or scan
  a QR. Returns a **Seller Result Card** with the colour verdict, score,
  member-since, locked QR, socials, complaint count. Unverified results get a
  "Before You Pay" checklist; not-found shows safety guidance + "report/
  register" options.
- **Seller Trust Profile** (`/seller`) — the full dossier: animated trust
  ring, verdict badge (pulsing glow), verification checklist, verification
  card preview, and tabs for Reviews / Complaints / About. High-risk profiles
  add WhatsApp-share and (if you reported them) Escalate-to-Police. Verified
  profiles show a 48-hour response countdown on open complaints. Fixed bottom
  "Report This Seller" bar.
- **Verification Card** (`/seller/card`) — the physical-style SafeBuy card
  (tier gradient, QR, card ID SBV-2026-XXXXX, valid-until, shine sweep).
  Share / copy.

### Reporting & escalation
- **Report a Seller** (`/report`) — platform, incident type, amount slider,
  description (min 50 chars), payment + chat screenshot uploads, declaration.
  Writes a report doc (status `pending`) and recalculates the seller's score.
- **Report Success** (`/report/success`) — Nepal-flag confetti, report ID,
  next-steps.
- **Escalate to Nepal Police** (`/cybercrime-report`) — appears on high-risk
  sellers you've reported. Auto-fills an official complaint (your details +
  the incident + applicable law: ETA 2063 §47/§48 or CPA 2075 §11), then
  emails it to the Cybercrime Bureau or exports a PDF. Success screen with a
  reference number and next steps.

### Seller / KYC side
- **Register Business** (`/register-business`) — name, phone, type,
  description → creates a seller profile.
- **KYC flow** (`/kyc` → gmail → qr → selfie → pan → location → submitted) —
  5 steps: link Gmail, upload eSewa QR (gets locked to the card), selfie with
  citizenship card, PAN card, geo-tagged location photos. Admin reviews and
  approves; the verified card then generates. Tiers: none → basic → verified
  → premium.
- **Write Review** (`/seller/review`) — rating, product, photo, comment;
  passes the six integrity checks before it counts.

### Awareness & data
- **Alerts** (tab 3) — scam-news entry, trending scam types, live community
  alerts, link to Nepal Fraud Data.
- **Scam News** (`/scam-news`) — 10 documented Nepali fraud cases, official
  stats, legal framework.
- **Nepal Fraud Statistics** (`/nepal-stats`) — dark dashboard: live Firestore
  counters + official Nepal Police charts (2020–2024 line, fraud-type donut,
  platform bars) + expandable ETA/CPA legal cards + Bureau email CTA.
- **Leaderboard** (`/leaderboard`) — monthly top verified sellers.
- **How It Works** (`/guide`) — buyers / sellers / trust-score explained.
- **SafeGuard AI** (`/safeguard`) — bilingual safety chat assistant.

### Profile & admin
- **Profile** (tab 4) — buyer or seller dashboard, verification status,
  settings, language, legal links. (Debug: seed demo data.)
- **Admin** (`/admin`, `/admin/kyc`) — dashboard, KYC review/approval, and the
  Cyber Bureau escalation queue (auto-drafted bilingual निवेदन letters that
  require human admin approval before submission).
- **Notifications, Privacy, Terms, About** — supporting screens.

---

## 4. THE 8 FLAGSHIP FEATURES (built this cycle)

1. **Cybercrime Bureau Report Generator** — turns a fraud report into an
   official ETA-2063 complaint (email + PDF) to Nepal Police. Your unique
   differentiator: individually small losses become legally actionable.
2. **QR seller verification** — scan an eSewa/Khalti QR, extract the phone,
   auto-run the trust lookup.
3. **Festival fraud alerts** — seasonal red banner during Dashain/Tihar/etc.
   ("fraud rises 340% during festivals").
4. **WhatsApp fraud warning** — one-tap share of a pre-written warning about a
   high-risk seller.
5. **Before You Pay checklist** — 5 safety steps under every unverified
   result.
6. **Nepal Fraud Statistics dashboard** — live + official fraud data.
7. **48-hour seller response countdown** — verified sellers must answer
   complaints in 48h or take a trust hit.
8. **Clean-record loyalty badges** — bronze/silver/gold for 6mo/1yr/2yr with
   zero reports (rewards honest sellers, not just punishing bad ones).

---

## 5. DATA MODEL (Firestore collections)

`sellers` (public read, trust fields locked) · `reports` (auth read, reporter
creates, seller can respond) · `reviews` (public read, immutable) · `users`
(own doc only) · `kyc_submissions` · `verification_cards` · `leaderboard` ·
`community_alerts` · `cyber_bureau_escalations` (admin only) · plus admin
audit logs. Storage paths mirror the rules: `kyc/`, `evidence/`,
`review_images/`, `qr_codes/`, `profiles/` (all compressed client-side).

---

## 6. SECURITY & PRIVACY (thesis-relevant)

- Trust-score fields writable only by admin/Cloud Functions (no self-inflation).
- Evidence & KYC files are write-once (fraud-record integrity).
- Reporters are anonymised publicly ("Verified buyer #XXXX"); only admins see
  identities.
- Public data (district, business name) is separated from private data
  (full address, phone shown masked).
- Aligned with Nepal's ETA 2063, Consumer Protection Act 2075, and Privacy
  Act 2075; six-layer anti-bot integrity resists review manipulation.

---

## 7. PLATFORM PARITY

The **website** (safebuy-nepal.vercel.app) mirrors the app: a browser demo
with the same trust scoring, search, report, review, loyalty badges,
checklist, WhatsApp warning, and police-escalation flows — so an examiner can
try the product without installing anything.

---

## 8. QUALITY & RELEASE

- `flutter analyze`: 0 issues · `flutter test`: 141/141 pass.
- Signed release APK (78.8 MB, R8-minified), v1.1.1+3.
- All text dark-on-white, minimum 4.5:1 contrast (WCAG AA).
