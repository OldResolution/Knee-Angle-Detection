# Gopal App (The Kinetic Sanctuary)

Flutter app for knee-health monitoring with BLE data streaming, gait analysis, alerts, and session history.

## What this project does

- Live knee angle tracking from BLE device
- Step/activity monitoring
- On-device gait classification using model in `assets/models/gait_model.json`
- User auth and profile data with Firebase
- Local session storage with Hive
- Simulation mode for testing without BLE hardware

## Prerequisites

- Flutter SDK installed and available in `PATH`
- Dart SDK `>=3.0.0 <4.0.0` (from `pubspec.yaml`)
- Android Studio SDK + platform tools (`adb`)
- JDK 17 (project Android config uses Java 17)
- Android phone (recommended for BLE testing)

Notes:
- Android emulator is not reliable for real BLE workflows.
- App supports simulation mode when hardware is unavailable.

## 1) Clone and install dependencies

```bash
git clone <your-repo-url>
cd "Gopal Application"
flutter pub get
```

## 2) Configure Firebase

Make sure to add `google-services.json` to `android/app` and follow standard Firebase setup. Or configure via FlutterFire CLI.

## 3) Run locally (debug)

Connect Android phone first (USB or wireless). Then:

```bash
flutter devices
flutter run -d <device-id>
```

Useful:

```bash
flutter run -v
```

If BLE hardware not available, open app and enable simulation mode:

- Settings -> Connectivity -> Simulation Mode

## 4) Build APK

Debug APK (fast for local testing):

```bash
flutter build apk --debug
```

Release APK:

```bash
flutter build apk --release
```

Output files:

- `build/app/outputs/flutter-apk/app-debug.apk`
- `build/app/outputs/flutter-apk/app-release.apk`

Optional smaller split APKs:

```bash
flutter build apk --release --split-per-abi
```

## 5) Install APK on phone (USB)

### Phone setup

1. Enable Developer options
2. Enable USB debugging
3. Connect phone with USB cable
4. Accept RSA prompt on phone

### Verify device

```bash
adb devices
flutter devices
```

### Install APK

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

If signature conflict:

```bash
adb uninstall com.example.gopal_app
adb install build/app/outputs/flutter-apk/app-debug.apk
```

Run directly from source to keep hot reload:

```bash
flutter run -d <device-id>
```

## 6) Run on phone with wireless debugging

Works best on Android 11+.

### Pair device

1. Phone: Developer options -> Wireless debugging -> Pair device with pairing code
2. On computer, run pairing command shown by phone (IP:port + code)

Example:

```bash
adb pair 192.168.1.10:37123
```

### Connect device

```bash
adb connect 192.168.1.10:39987
adb devices
flutter devices
```

Then run:

```bash
flutter run -d <wireless-device-id>
```

You can also install built APK over wireless:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## 7) Android permissions used

Project requests BLE/location related permissions in Android manifest, including:

- `BLUETOOTH`, `BLUETOOTH_ADMIN` (legacy)
- `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT` (Android 12+)
- `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` (legacy BLE scan support)

On Android 12+, ensure Bluetooth permissions are allowed when prompted.

## 8) Troubleshooting

### Firebase Initialization Error

- Confirm `google-services.json` exists in `android/app`
- Check Firebase configuration in console

### `adb` command not found

- Add Android `platform-tools` to `PATH`
- Reopen terminal and run `adb version`

### Device not showing in `adb devices`

- Re-plug USB cable
- Switch USB mode to file transfer
- Re-enable USB debugging and accept RSA prompt again

### BLE scan fails on emulator

- Use physical phone for BLE
- Or use simulation mode from Settings -> Connectivity

### Release APK install/update issues

- Uninstall old app if signature differs:
	- `adb uninstall com.example.gopal_app`

## 9) Quick command checklist

```bash
flutter pub get
flutter devices
flutter run -d <device-id>
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```
