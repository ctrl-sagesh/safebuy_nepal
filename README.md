# SafeBuy Nepal

A seller trust verification and fraud reporting platform for people who buy from sellers on Facebook, Instagram and TikTok in Nepal. Buyers can check a seller before they pay, report a seller who scammed them, and see community reports on that seller. Verified sellers earn a trust badge that follows their real identity across platforms.

Live website: https://safebuynepal.vercel.app

## The problem

Most online shopping in Nepal happens on social media, not on formal marketplaces. Payment usually goes straight to a personal eSewa or bank account before the buyer sees the product. There is no escrow and no platform refund. A fraud seller can take the money, block the buyer, delete the page and reopen under a new name the next day. SafeBuy Nepal attaches a public trust record to the seller's verified identity so that history cannot be erased by rebranding.

## Key features

- **Verify a seller** by phone number, eSewa number or social handle, and get a single trust verdict (Trusted / Unverified / High Risk) backed by a 0 to 100 score.
- **Report a fraud** through a guided flow that captures the seller, the incident, the amount lost and screenshot evidence.
- **Seller KYC verification** through a five step flow that binds a seller to a real legal identity using PAN.
- **Community reviews** and fraud reports aggregated on each seller profile.
- **Scam news and fraud alerts** for the Nepali market.
- **Escalate to Nepal Police**, which builds a formatted cybercrime complaint from the report and exports it as a PDF or an email.

## Trust score

The score is a weighted combination of five signals: fraud report severity, verification status, review authenticity, dispute response and account age. The calculation runs server side inside a Cloud Function so a client cannot forge it.

## Tech stack

- **App**: Flutter (Dart), Riverpod for state, go_router for navigation, Clean Architecture by feature.
- **Backend**: Firebase Auth (phone OTP and Google), Cloud Firestore, Firebase Storage, Cloud Functions on Node 20.
- **Website**: static site deployed on Vercel.
- **Platform**: Android (min SDK 21). App id `com.sagesh.safebuy.safebuy_nepal`.

## Getting started

Requires the Flutter SDK (Dart 3.11 or newer). Set up your own Firebase project and place your `google-services.json` under `android/app/`.

```bash
flutter pub get
flutter run
```

On Windows you can also double click `run_on_phone.bat`. While the app is running, press `r` for hot reload, `R` for hot restart and `q` to quit.

Build a release APK:

```bash
flutter build apk --release
```

Full setup notes, release signing and Firebase emulator instructions are in [README_DEVELOPMENT.md](README_DEVELOPMENT.md). A walkthrough of the main flows is in [DEMO_GUIDE.md](DEMO_GUIDE.md).

## Project structure

```
lib/
  agents/       rule based decision logic (fraud detector, safeguard, seller coach)
  core/         config, theme, shared widgets, services, utilities
  features/     one folder per feature (auth, home, search, reports, kyc,
                sellers, business, alerts, community, admin, leaderboard, ...)
functions/      Firebase Cloud Functions (server side trust scoring)
website/        static marketing and verify site (Vercel)
```

Each feature follows a data / domain / presentation split.

## Status

This is a final year academic project. It is a working prototype rather than a commercial product. Evaluation was carried out by the developer and no real user data was collected.
