# SafeBuy Nepal — Thesis Demo Guide

> Before you start: on a debug build, open **Profile → Settings →
> Developer Options → Seed Demo Data** once so the 5 demo sellers
> exist. Then use the **Demo Quick Search** chips on the Search tab.

## Quick Demo Flow (5 minutes)

### Demo 1: Buyer Verifying a Seller
1. Open app → tap **Verify** tab
2. Type `9841234567` (or tap the ✅ Trusted chip) → show **Priya Fashions** (TRUSTED, 87)
3. Tap the verification card → show the full profile
4. Point out: registration date, verified badge, reviews

### Demo 2: High Risk Seller
1. Search `9881234571` (or tap 🔴 High Risk) → show **FastDeal Nepal** (HIGH RISK, 18)
2. Show: multiple fraud reports, money lost, a very new account
3. Show the red verdict and the report evidence

### Demo 3: Filing a Fraud Report
1. Tap **Report Fraud**
2. Fill seller details (use `9871234570` — QuickBuy Electronics)
3. Fill incident details (NPR 5000, item not delivered)
4. Upload a test screenshot
5. Submit → show confetti and the report ID (RPT-2026-XXXXX)

### Demo 4: Seller Verification (KYC)
1. Go to **Profile → Get SafeBuy Verified**
2. Walk the 5-step KYC flow (Gmail, QR, selfie+citizenship, PAN, location)
3. Show the SafeBuy Verification Card design

### Demo 5: Admin Panel
1. Sign in as an **admin** account (set `role: 'admin'` in Firestore)
2. Profile → **Admin: Dashboard** — show the stats
3. **Admin: KYC Review** — open a submission, show the documents
4. Approve a submission → the verification card generates

## Key Points to Mention to the Examiner
- **5-factor trust score algorithm** (original contribution)
- **6-layer anti-bot review system** (cybersecurity)
- **Community threat intelligence** (VirusTotal-style crowd model)
- **Digital evidence collection** (forensics principles)
- **KYC verification framework** (aligned with ETA 2063)
- **Pure Firebase architecture** (Auth + Firestore + Storage + Functions)
- **4 rule-based AI agents** (no external API cost)

## Demo seller reference
| Seller | Phone | Score | Verdict |
|---|---|---|---|
| Priya Fashions | 9841234567 | 87 | Trusted |
| TechNepal Store | 9851234568 | 82 | Trusted |
| Sunset Cosmetics | 9861234569 | 64 | Unverified |
| QuickBuy Electronics | 9871234570 | 31 | High Risk |
| FastDeal Nepal | 9881234571 | 18 | High Risk |
