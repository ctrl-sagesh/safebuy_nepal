# SafeBuy Nepal — Figma Prototype Guide

Everything needed to build a high-fidelity, clickable Figma prototype that
matches the real app. Values are taken directly from the production code
(`lib/core/theme/app_colors.dart`, `app_theme.dart`, and the screens).

---

## 0. FIGMA FILE SETUP

**Frame / device:** iPhone 16 or "Android Large" — use **390 × 844 px**
(the app is portrait-only, so lock every frame to portrait).

**Pages to create (left panel):**
1. `🎨 Design System` — colors, type, components (the source of truth)
2. `🔑 Onboarding & Auth` — splash, onboarding, sign-in, OTP, profile setup
3. `🏠 Core App` — home, search, seller profile, alerts, profile
4. `🛡️ Trust & KYC` — verification card, KYC steps, register business
5. `🚩 Report & Police` — report flow, success, cybercrime escalation
6. `📊 Data & Extra` — Nepal stats dashboard, leaderboard, guide, about
7. `🔗 Prototype Flows` — arrows/connections view (optional)

**Grid:** 8px baseline grid. Side margins **16px** (content), **24px** on
auth/setup screens. Enable layout grid: columns = 1, margin 16.

---

## 1. DESIGN SYSTEM

### 1.1 Colors (create these as Figma color styles)

**Primary / Brand**
| Style name | Hex | Use |
|---|---|---|
| primary | `#1565C0` | main brand blue, buttons, links |
| primary/dark | `#0D47A1` | gradients, headers |
| primary/light | `#1976D2` | gradient mid |
| primary/50 | `#E3F2FD` | selected chip backgrounds |
| primary/100 | `#BBDEFB` | light borders |
| accent/blue | `#42A5F5` | gradient highlights |
| accent/cyan | `#00BCD4` | scan line, accents |

**Trust verdict (the heart of the app)**
| Style name | Hex | Use |
|---|---|---|
| trust/trusted | `#00C853` | green — score 80–100 |
| trust/trustedBg | `#E8F5E9` | green surface |
| trust/unverified | `#FF8F00` | amber — score 50–79 |
| trust/unverifiedBg | `#FFF8E1` | amber surface |
| trust/highRisk | `#D32F2F` | red — score 0–49 |
| trust/highRiskBg | `#FFEBEE` | red surface |

**Backgrounds**
| Style name | Hex | Use |
|---|---|---|
| bg/primary | `#FFFFFF` | cards, sheets |
| bg/secondary | `#F5F7FA` | screen background |
| bg/dark | `#0D2137` | Nepal Stats screen only |
| bg/darkCard | `#1A3A5C` | Stats cards only |

**Text / form ink (use these for ALL text — high contrast)**
| Style name | Hex | Use |
|---|---|---|
| ink/strong | `#1A1A1A` | headings, input text |
| ink/label | `#555555` | field labels |
| text/secondary | `#4A5568` | body text |
| text/muted | `#757575` | captions (AA on white) |
| ink/hint | `#9E9E9E` | placeholders, prefix icons |
| border/idle | `#E0E0E0` | input borders |
| border/light | `#E2E8F0` | card borders |

**Nepal flag accent (splash, confetti, PDF, stats header)**
| Style name | Hex |
|---|---|
| nepal/crimson | `#DC143C` |
| nepal/blue | `#003893` |

**Loyalty medals**
| Style name | Hex |
|---|---|
| medal/gold | `#D4AF37` (2 Year Elite) |
| medal/silver | `#97A3B4` (1 Year Trusted) |
| medal/bronze | `#CD7F32` (6 Month Clean) |

**Seller-side green** (Seller role card): `#2E7D32`, selected bg `#F0FDF4`.

### 1.2 Gradients (Figma linear fills)

- **heroGradient** (top→bottom): `#0D47A1` → `#1565C0` → `#1976D2`
- **primaryGradient** (top-left→bottom-right): `#1565C0` → `#0D47A1`
- **trustGradient**: `#00C853` → `#00E676`
- **riskGradient**: `#D32F2F` → `#F44336`
- **festivalGradient** (banner): `#DC143C` → `#8B0000`
- **splashBg** (top→bottom): `#0D47A1` → `#1565C0`

### 1.3 Typography (create text styles)

Fonts (all free on Google Fonts — add via Figma):
- **Poppins** — headings, titles, numbers, buttons
- **Inter** — body, labels, captions
- **Noto Sans Devanagari** — all Nepali (नेपाली) text

| Style name | Font | Size | Weight | Color |
|---|---|---|---|---|
| Display | Poppins | 28 | 800 | ink/strong |
| H1 | Poppins | 22 | 700 | ink/strong |
| H2 | Poppins | 19 | 700 | ink/strong |
| H3 | Poppins | 16 | 600 | ink/strong |
| Title | Poppins | 15 | 600 | ink/strong |
| Body | Inter | 14 | 400 | text/secondary |
| Body-strong | Inter | 13.5 | 600 | ink/strong |
| Label | Inter | 13 | 500 | ink/label |
| Caption | Inter | 12 | 400 | text/muted |
| Micro | Inter | 10.5 | 500 | text/muted |
| Score | Poppins | 28 | 800 | (verdict color) |
| Button | Poppins | 16 | 600 | white |
| Mono (card ID) | Roboto Mono | 12 | 600 | ink/strong |

### 1.4 Radii, spacing, shadows

- **Corner radius:** cards 16–20, buttons 14, chips/pills 20, inputs 14,
  small tags 8.
- **Spacing scale:** 4, 6, 8, 10, 12, 14, 16, 18, 24, 28, 36.
- **Card shadow:** X 0, Y 6, Blur 16, color `#000000` at 6% opacity.
- **Button shadow (primary):** X 0, Y 6, Blur 14, `#1565C0` at 20%.
- **Bottom-nav shadow:** X 0, Y −4, Blur 20, `#000000` at 8%.

---

## 2. COMPONENTS TO BUILD (make these Figma components with variants)

1. **Button** — variants: Primary (blue gradient), Outline (blue border),
   Danger (red), Disabled. Height 52, radius 14, Poppins 16/600.
2. **Trust Score Ring** — 110×110 circular arc, variants: Trusted (green),
   Unverified (amber), High-Risk (red). Center: big number + "/100".
3. **Verdict Badge** — pill, variants: ✓ TRUSTED / ? UNVERIFIED / ✕ HIGH RISK,
   colored surface + colored text.
4. **Seller Result Card** — the big search-result card (see §3.4).
5. **Verification Card** — the physical SafeBuy card (340×200 ratio),
   variants: Basic / Verified / Premium (different gradients + tier color).
6. **Input Field** — white fill, `#E0E0E0` border idle / `#1565C0` focus,
   label `#555555`, text `#1A1A1A`, hint `#9E9E9E`, prefix icon `#9E9E9E`.
7. **Dropdown** — closed (white, dark text, chevron) + open sheet (white,
   dark items, selected = blue text + check).
8. **Loyalty Badge** — pill, variants: Bronze / Silver / Gold, medal icon.
9. **Bottom Nav Bar** — 4 tabs: Home · Verify · Alerts · Profile, height 64,
   active icon blue + pill indicator.
10. **App Bar** — white, title Poppins 18/600, optional actions.
11. **Section Header** — accent bar + title.
12. **Stat Counter Card** — number (Poppins 800) + label.
13. **Empty / Not-Found Card**, **Skeleton Loader** (blue shimmer
    `#EFF6FF`→`#DBEAFE`).

---

## 3. SCREEN-BY-SCREEN SPEC

> For each screen: background, top-to-bottom content, exact copy.

### 3.1 Splash (4-second animated intro)
- BG: splashBg gradient + faint Dhaka diamond pattern (opacity 8%).
- Center: **shield logo** (90×90, white outline, crimson+blue Nepal band
  inside, small double-pennant flag on top-right, "SB" in white Poppins).
- Below: **"SafeBuy Nepal"** Poppins 28/800 white.
- Tagline: **"Nepal's Seller Verification Platform"** Inter 14, white 85%.
- Three pills: **Verify Sellers · Report Fraud · Stay Safe** (white 15% bg).
- Bottom stats: **"1,247 Sellers Verified • 389 Reports • NPR 2.1M Saved"**
  Inter 11, white 70%.
- Top-right corner: 🇳🇵 flag.
- *(In Figma: make 3–4 frames showing the sequence, or one final state.)*

### 3.2 Onboarding (4 swipeable slides)
Each slide: illustration top, headline (Poppins 22/700), body (Inter 14),
page dots, "Next" / "Skip". Content:
1. **The Problem** — "Social media shopping in Nepal is booming — and so is
   fraud." Footnote: "NPR 40 crore lost in 2023 alone (Nepal Police Report)".
2. **The Solution** — "Check any seller's trust score, reviews, and fraud
   complaints before sending a single rupee."
3. **The Community** — "Report once, protect thousands. Every report makes
   the next buyer safer."
4. **The Choice** — "Create an account or continue as guest." → CTA buttons.

### 3.3 Auth / Sign-in
- Hero: blue gradient top with curved bottom + shield.
- Title: **"Verify Before You Pay"**.
- Phone field: prefix **+977**, hint "98XXXXXXXX" (bare 10-digit).
- Primary button: **"Send OTP"**.
- Divider "or", **"Continue with Google"** (white, Google logo).
- **"Continue as Guest"** text button.
- Footer: Terms + Privacy links.

**OTP screen:** 6 pinput boxes, "Enter the code sent to +977 98•••••210",
resend timer "Resend in 30s", auto-submit, shake on error.

### 3.4 Profile Setup (NEW clean design)
- BG white, 24px margins.
- Header: **"Complete Your Profile"** (Poppins 22/700 #1A1A1A) +
  **"Tell us a bit about yourself"** (Inter 14 #666).
- **Full Name** — label #555, input white/#E0E0E0 border, person icon #9E9E9E.
- **"I am a..."** — two cards side by side:
  - **Buyer** (cart icon): unselected white/#E0E0E0; selected bg `#EFF6FF`,
    border `#1565C0` 2px, blue icon+text, blue corner check. Subtitle
    "Shop safely with trust ratings".
  - **Seller** (store icon): selected bg `#F0FDF4`, border `#2E7D32` 2px,
    green icon+text, green corner check. Subtitle "Build my trust rating".
- **Language / भाषा** — two flag cards: 🇬🇧 English · 🇳🇵 नेपाली,
  selected = blue border.
- *(Seller only)* **Business Name** + **Business Category** dropdown
  (white sheet, dark `#1A1A1A` items).
- **Complete Setup** — full-width blue gradient button, radius 14, height 52.

### 3.5 Home (bottom-nav tab 1)
- App bar: shield + **"SafeBuy Nepal"**, help icon (?), notification bell.
- **Hero search card** — blue gradient, faint Dhaka pattern, "Verify Before
  You Pay" / "Namaste, [name]", white search bar "Phone number, @handle,
  or eSewa ID...", example chips "Try: 9841234567".
- **Festival banner** (seasonal) — red gradient, "Dashain Season Fraud Alert
  / Fraud complaints increase 340% during festivals. Verify every seller
  before paying." + "Verify a Seller Now".
- **Active alerts strip** (amber) — tappable → Alerts.
- **Two quick actions** — "Verify a Seller" / "Report Fraud" cards.
- **Trusted sellers** — horizontal list of top sellers (avatar + score).
- **Recent alerts** — list.
- **Safety Tips** — continuously scrolling ticker of 5 tip cards (blue
  gradient): "Never pay 100% advance...", "Search before every purchase...",
  "Keep payment & chat screenshots...", "Only trust QR on a SafeBuy card...",
  "Prefer Cash on Delivery...".
- **"Learn how SafeBuy works"** card → guide.

### 3.6 Search / Verify (bottom-nav tab 2)
- App bar "Verify a Seller".
- Search bar: search icon, text field, **Search** button, **QR scan icon**
  (right).
- Live hint: "Searching by phone number / handle / business name".
- *(debug)* Demo quick-search chips: ✅ Trusted · ⚠ Unverified · 🔴 High Risk.
- **Results** = Seller Result Card(s), staggered slide-up entrance.
- If unverified result → **"Before You Pay" checklist card** below it.
- Empty → **Not-Found card**: "Seller not found on SafeBuy Nepal / This does
  not mean they are fraudulent..." + safety tips + "Report if you were
  scammed" / "This is my business? Register".

**Seller Result Card (build as component):**
- TOP (hero gradient): avatar (tier-colored ring), name, category chip,
  trust score circle + verdict label.
- VERDICT BANNER (colored surface): icon + "TRUSTED SELLER / UNVERIFIED
  SELLER / HIGH RISK — DO NOT PAY" + score/100 + one-line explanation.
  *(High-risk icon has a red pulsing glow.)*
- MIDDLE (white): "📅 Member since March 2024", "🔄 Verified until..." or
  "⚠ Re-verification Overdue", tier banner, loyalty pill if earned, socials
  + "⭐ N Reviews · 📋 N Complaints".
- BOTTOM (light grey): locked QR image + "🔒 This QR is locked by SafeBuy
  Nepal, safe to use", card ID (mono), **View Full Profile** / **Report**.

### 3.7 Seller Profile (full screen)
- SliverAppBar: verdict-colored gradient + Dhaka pattern, avatar, name,
  category · district.
- **Trust score card**: animated ring (score, verdict color) + verdict badge
  (pulsing glow) + "Last verified: ..." + mini stats ⭐ 📋 📦.
- **Verdict explanation** (red warning / green confidence box).
- *(High-risk)* **Share on WhatsApp** + **Copy Warning Text** buttons.
- *(High-risk + you reported)* **Escalate to Nepal Police** button (navy).
- **Verification status card**: tier, ✓/✗ checklist (phone, identity,
  location, social), registered date, loyalty badge, re-verification date.
- **Verification card preview** (if KYC verified) — tappable, shine sweep.
- **Sticky tabs**: Reviews (n) · Complaints (n) · About.
  - Reviews: review cards (avatar, stars, product, comment, photo, verified
    purchase, date; top review gold border).
  - Complaints: 48h response countdown card (amber/red) if applicable, then
    report cards (incident type tag, amount, description, seller response,
    anonymized reporter, status + date).
  - About: description, category, district, member since, socials.
- **Fixed bottom bar**: **Report This Seller** (red).

### 3.8 SafeBuy Verification Card (full screen)
- The physical card, large, centered: tier gradient, "SafeBuy Nepal" +
  shield, tier badge, avatar + name + category · district + member since,
  QR code, card ID (SBV-2026-XXXXX), "Verified by SafeBuy Nepal", valid-until.
- White shine sweeps across every 5s.
- Buttons: **Share Card**, **Copy Card Details**.

### 3.9 Report Fraud (multi-field form)
- App bar "Report a Seller".
- Seller identifier (prefilled), platform dropdown (TikTok/Instagram/
  Facebook/WhatsApp/Viber/Other), incident type (Item Not Delivered / Wrong
  Item / Fake Product / Paid No Response / Impersonation / Other).
- Amount lost — slider "NPR 5,000".
- Description — textarea, min 50 chars.
- Payment screenshot + chat screenshot uploaders.
- Evidence strength note: "Both payment and chat proof attached. This report
  carries full weight."
- Declaration checkbox (required).
- **Submit Report**.

**Report Success:** Nepal-flag confetti (crimson/blue/white, shield shapes),
animated check, "Report Filed Successfully", "RPT-2026-XXXXX", "What
happens next" cards, **Done**.

### 3.10 Escalate to Nepal Police (`/cybercrime-report`)
- App bar "Escalate to Nepal Police" (blue).
- **Bureau card** (blue gradient): 🛡️ "Nepal Police Cybercrime Investigation
  Bureau", 📍 Naxal, Kathmandu, 📞 01-4412323 (tappable), ✉️
  cybercrime@nepalpolice.gov.np (tappable), 🕙 Sun to Fri, 10am to 5pm.
- **Your information**: full name, phone (masked), address field, District
  dropdown (all 77, white/dark).
- **Incident** (from report): seller, platform, date, amount, SafeBuy ref.
- **Applicable law** (radio): ETA 2063 §47 / §48 / CPA 2075 §11.
- **Evidence chips**: Payment screenshot Attached (green) / Not provided (red).
- **Declaration checkbox** (required).
- Buttons: **Email Complaint to Nepal Police** / **Save as PDF**.
- **Success screen**: green check, "Complaint Sent to Nepal Police",
  reference, 3 next-step cards (ack in 3–5 days, may be called to Naxal,
  keep originals safe).

### 3.11 KYC flow (5 steps, seller verification)
Intro (three tiers explained) → Step 1 **Gmail** link → Step 2 **eSewa QR**
upload (gets locked) → Step 3 **Selfie with citizenship card** → Step 4
**PAN card** photo + number → Step 5 **Location photos** (3, with GPS) →
**Submitted** (pending admin review). Each step: step header, upload zone
(dotted border), why-we-need-this note, bottom Next bar.

### 3.12 Register Business
Business name, phone, business type dropdown (white/dark), description,
"Start Your Free Registration".

### 3.13 Alerts (bottom-nav tab 3)
- App bar "Safety Alerts" + **"Nepal Fraud Data"** action → stats.
- **Scam Reports Nepal** entry card (red gradient) → scam news.
- **Trending scam types**: 📦 Non-Delivery 35% · 🏷️ Fake Products 28% ·
  💳 Payment Fraud 20% · 🎭 Account Cloning 12%.
- Live community alerts list.

### 3.14 Nepal Fraud Statistics (dark screen, `/nepal-stats`)
- BG `#0D2137`, cards `#1A3A5C`. App bar "🇳🇵 Nepal Fraud Data".
- **LIVE: SafeBuy Community Data** — 4 counters: Fraud reports filed / NPR
  reported lost / High-risk sellers / Verified sellers (guests see a "Sign
  in to view" lock on the money one).
- **Official Nepal Police Data** — line chart 2020→2024 (spike at 2023),
  4 stat boxes: 340% / NPR 40Cr+ / 560% / 2,400+.
- **What Kind of Fraud** — donut: Non-delivery 35 / Fake 28 / Wrong 20 /
  Payment 12 / Other 5.
- **Where It Happens** — bars: TikTok 48 / Instagram 32 / Facebook 20.
- **The Law Is On Your Side** — 3 expandable cards (ETA §47, §48, CPA §11)
  with penalties.
- Bottom CTA: **Email the Bureau** (red).

### 3.15 Profile (bottom-nav tab 4)
- Guest: sign-in prompt. Logged in: avatar + name + role.
- Buyer dashboard: reports submitted, quick links.
- Seller dashboard: trust score, verification status, "Get SafeBuy Verified".
- Menu: Leaderboard, How It Works, Notifications, Privacy, Terms, About,
  Language, Sign Out. *(debug: Developer Options → Seed Demo Data.)*

### 3.16 Extra screens
- **Leaderboard** — monthly top verified sellers, medals.
- **How It Works** — 3 tabs (buyers / sellers / trust score explained).
- **SafeGuard AI** — chat screen (help icon on Home), bilingual Q&A.
- **QR Scanner** — full-screen camera, white corner frame, moving scan line,
  "Scan seller's eSewa or Khalti QR code", Cancel.
- **About** — "About SafeBuy Nepal 🇳🇵", academic credits.

---

## 4. DEMO SELLER DATA (use these in mockups for consistency)

| Seller | Handle | Phone | Score | Verdict |
|---|---|---|---|---|
| Priya Fashions | @priya_fashions | 9841234567 | 87 | Trusted |
| Himalayan Handicrafts | @himalayan_crafts | 9856701234 | 97 | Trusted (Gold badge) |
| Sunset Cosmetics | @sunset_cosmetics | 9861234569 | 64 | Unverified |
| GadgetZone Nepal | @gadgetzone | 9803456789 | 57 | Unverified |
| QuickBuy Electronics | @quickbuy_np | 9871234570 | 31 | High Risk |
| FastDeal Nepal | — | 9881234571 | 18 | High Risk |

---

## 5. PROTOTYPE FLOWS TO WIRE (Figma "Prototype" tab)

**Flow A — Buyer verifies (the money shot):**
Splash → Onboarding → Auth (or Guest) → Home → tap search → Search →
type 9841234567 → Priya result (Trusted) → View Profile → back →
type 9871234570 → QuickBuy (High Risk) → profile → Share WhatsApp /
Escalate to Police → complaint screen → success.

**Flow B — Report fraud:**
Seller profile → Report This Seller → fill form → Submit → confetti success.

**Flow C — Seller onboarding:**
Auth → Profile Setup (pick Seller) → Register Business → KYC intro →
5 steps → Submitted → Verification Card preview.

**Flow D — Safety education:**
Home → festival banner → Search; Alerts → Nepal Fraud Data (dark dashboard).

Interaction settings: use **Smart Animate**, 250–300ms, ease-out. Bottom-nav
taps = instant. Card taps = dissolve/slide.

---

## 6. THESIS-READY NOTES

- Emphasize the **trust verdict color language** (green/amber/red) as the
  core UX decision — instant risk comprehension before payment.
- Show the **bilingual** support (English + नेपाली) in at least one screen.
- The **police escalation flow** is your unique differentiator — give it a
  full flow in the prototype.
- Keep all text **dark-on-white** (min 4.5:1 contrast) — mention WCAG AA
  compliance in your report; it's a real, defensible design decision.
