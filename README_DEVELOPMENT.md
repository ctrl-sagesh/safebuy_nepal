# SafeBuy Nepal — Development Guide

## Running on Android Phone (USB Debug)

### One-time phone setup:
1. Settings → About phone → tap **Build number** 7 times
2. Settings → Developer options → enable **USB debugging**
3. Connect phone via USB → tap **Allow** on the phone

### Run the app:
```
flutter run
```
(Or double-click `run_on_phone.bat` on Windows.)

### Hot reload (while app is running):
- `r` = hot reload (instant UI updates)
- `R` = hot restart (full restart)
- `q` = quit

### Run on a specific device:
```
flutter devices           # list all devices
flutter run -d DEVICE_ID  # run on a specific device
```

### Build release APK:
```
flutter build apk --release
```

### Install the built APK directly to the phone:
```
flutter install
```

## Running in Android Studio
1. Open Android Studio
2. File → Open → select the `safebuy_nepal` folder
3. Wait for Gradle sync to finish
4. Select your device from the device dropdown
5. Click **Run** (green play button)

## VS Code
Launch configurations are in `.vscode/launch.json`:
- **SafeBuy Nepal (Debug)** — hot reload development
- **SafeBuy Nepal (Release)** — release-mode run
- **SafeBuy Nepal (Profile)** — performance profiling

## Demo / seed data (debug builds only)
- The debug build shows **Developer Options → Seed Demo Data** in
  Profile → Settings, which loads the 5 demo sellers into Firestore.
- The Search tab shows a **Demo Quick Search** row with Trusted /
  Unverified / High Risk chips that instantly search a demo seller.
- Neither appears in the release APK.

## Firebase Emulator (offline development)
```
firebase emulators:start
```
The debug build allows cleartext (HTTP) traffic so it can reach the
local emulator suite. Point Firestore/Auth at the emulator in code
with `useFirestoreEmulator(...)` / `useAuthEmulator(...)` when needed.

## Architecture
- **Firebase**: Auth (phone OTP + Google), Firestore, Storage, Cloud
  Functions (Node 20)
- App ID: `com.sagesh.safebuy.safebuy_nepal`
- Min SDK 21 · Target/compile SDK per Flutter · multiDex enabled
