
# ExpenseTracker (reloaded)

A Flutter app that automatically detects expense amounts from incoming SMS messages,
keeps a running daily total, stores transaction history locally, and provides a modern
dashboard UI with hero animations and smooth page transitions.

This repository contains the app source used during development: UI components are in
`lib/home_dashboard.dart` and app entry + routing is in `lib/main.dart`.

## Key features

- Auto-detect expense amounts from SMS (regex-based parsing)
- Local persistence using `SharedPreferences` (daily total + transaction history)
- In-app notifications (local notifications) when a new expense is detected
- Background SMS handling (registered handler for incoming messages)
- Dashboard UI with Hero animations and custom page transitions
- History, Profile and Settings placeholder pages with routing

## Prerequisites

- Flutter SDK (stable channel). Minimum Dart SDK is declared in `pubspec.yaml`.
- Android device/emulator for SMS-reading functionality (SMS permission is Android-specific).
- For Windows development, you can still run the app, but SMS features require a mobile device.

## Setup (Windows / PowerShell)

1. Install Flutter and confirm it is available on PATH. Then fetch dependencies:

```powershell
cd C:\Users\<user>\Desktop\expensetracker_reloaded
flutter pub get
```

1. Run the analyzer to check for issues:

```powershell
flutter analyze
```

1. Launch on a connected Android device or emulator:

```powershell
flutter run -d <device-id>
# e.g. flutter run -d emulator-5554
# ExpenseTracker (reloaded)

A Flutter app that automatically detects expense amounts from incoming SMS messages,
keeps a running daily total, stores transaction history locally, and provides a modern
dashboard UI with hero animations and smooth page transitions.

This repository contains the app source used during development: UI components are in
`lib/home_dashboard.dart` and app entry + routing is in `lib/main.dart`.

## Key features

- Auto-detect expense amounts from SMS (regex-based parsing)
- Local persistence using `SharedPreferences` (daily total + transaction history)
- In-app notifications (local notifications) when a new expense is detected
- Background SMS handling (registered handler for incoming messages)
- Dashboard UI with Hero animations and custom page transitions
- History, Profile and Settings placeholder pages with routing

## Prerequisites

- Flutter SDK (stable channel). Minimum Dart SDK is declared in `pubspec.yaml`.
- Android device/emulator for SMS-reading functionality (SMS permission is Android-specific).
- For Windows development, you can still run the app, but SMS features require a mobile device.

## Setup (Windows / PowerShell)

1. Install Flutter and confirm it is available on PATH. Then fetch dependencies:

```powershell
cd C:\Users\Abhra\Desktop\expensetracker_reloaded
flutter pub get
```

2. Run the analyzer to check for issues:

```powershell
flutter analyze
```

3. Launch on a connected Android device or emulator:

```powershell
flutter run -d <device-id>
# e.g. flutter run -d emulator-5554
```

**Notes:**

- SMS-reading requires `android.permission.RECEIVE_SMS` and `android.permission.READ_SMS` in
  `android/app/src/main/AndroidManifest.xml` and runtime permission acceptance on the device.
- Local notifications require configuring Android notification channels (the app already
  sets up a basic channel in `main.dart`).

## Project structure (important files)

- `lib/main.dart` — app entry, initialization of notifications, background SMS handler, and routing
- `lib/home_dashboard.dart` — main UI (Welcome screen, HomeDashboard, History, Profile, Settings),
  hero animations and SMS parsing logic
- `pubspec.yaml` — dependencies and SDK constraints

## Notes about SMS & background handling

- The app uses `another_telephony` (or similar) to listen to incoming SMS messages. On Android,
  a background message handler is annotated with `@pragma('vm:entry-point')` so it can run when
  the app is backgrounded. Depending on Android versions, background delivery of SMS to apps
  may be restricted; test on a device and ensure runtime permissions are granted.

## Troubleshooting

- Analyzer warnings: you may see minor warnings (unused imports) — these are non-blocking and
  can be cleaned up if desired.
- If transactions do not show up after SMS arrives:
  - Ensure SMS permissions are granted from device settings
  - Verify the regex in `home_dashboard.dart` matches your carrier's SMS text
  - Check `flutter run` logs for parsing or notification errors

## Testing & development tips

- To simulate incoming transactions during development, use the "Add Expense" shortcut in the app.
- Use `flutter analyze` and `flutter test` (if tests are added) to validate code.

## Next steps / improvements

- Add filters and search on the History page (by date / amount / vendor)
- Improve parsing to support more currencies and message formats
- Add sync/backup (e.g., export CSV or cloud sync)

## License

This project is provided as-is. Add a license file if you intend to open-source it.

---

If you'd like, I can:

- Clean the small analyzer warnings now (remove unused imports),
- Add an example AndroidManifest snippet for required permissions, or
- Add a short demo/test that programmatically inserts transactions for UI testing.

Tell me which of those you'd like and I'll make the changes.
