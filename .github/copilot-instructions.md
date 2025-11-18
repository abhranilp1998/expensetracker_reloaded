## Quick context

This is a Flutter mobile app (Android-first) that listens for incoming SMS messages, extracts expense amounts using regex, shows local notifications, and stores a per-day total + transaction history in SharedPreferences. Key implementation files:

- `lib/main.dart` — app entry, notification initialization, background SMS handler (`@pragma('vm:entry-point')`) and route wiring.
- `lib/home_dashboard.dart` — main UI, foreground SMS listener, parsing logic (`_parseMessage`), storage keys, animation/route examples (Hero tags and `_createRoute`).
- `pubspec.yaml` — dependency list (notable packages: `another_telephony`, `permission_handler`, `shared_preferences`, `flutter_local_notifications`, `sqflite`).

## Architecture & data flow (concise)

1. SMS arrives on device → either delivered to background handler in `main.dart` (`backgroundMessageHandler`) or to foreground listener in `home_dashboard.dart` (`telephony.listenIncomingSms`).
2. Message is parsed with a regex for amounts: pattern used in both files: `(?:rs\.?|inr)\s*([0-9,]+\.?[0-9]*)` (case-insensitive).
3. On match: value parsed to double, persisted to SharedPreferences keys:
   - `todayTotal` — stored as a double
   - `transactions` — stored as a List<String> of JSON-encoded transaction objects: { amount, time (ISO), message }
4. Local notification shown using `flutter_local_notifications` with channel id `expense_tracker` (see initialization in `main.dart` and usage in `_showNotification`).

Design rationale to keep in mind: single-process local storage (SharedPreferences) is the canonical single-source-of-truth for quick persistence in this app; background and foreground handlers both write directly to it.

## Important patterns & conventions (concrete)

- Background entry: handler is annotated with `@pragma('vm:entry-point')` in `main.dart`. Preserve that when refactoring or renaming the function.
- Storage keys are literal strings (`'todayTotal'`, `'transactions'`) — search for them when changing persistence.
- Transaction format is JSON-encoded maps stored as strings in a StringList — when adding migrations, convert each string entry.
- Routing uses a single `onGenerateRoute` and `_createRoute(...)` for consistent animated transitions; reuse `_createRoute` where new pages are added.
- Hero tags used: `app-logo`, `get-started-button`. Keep tags stable if you change UI transitions.

## Developer workflows & commands (PowerShell / Windows)

- Install deps and analyze:

```powershell
cd C:\Users\Abhra\Desktop\expensetracker_reloaded
flutter pub get
flutter analyze
```

- Run on a connected Android emulator/device (recommended for SMS features):

```powershell
flutter run -d <device-id>
# e.g. flutter run -d emulator-5554
```

- Build release APK (local Android build):

```powershell
flutter build apk --release
```

Notes:
- SMS functionality requires Android runtime permissions (`RECEIVE_SMS`, `READ_SMS`) in `android/app/src/main/AndroidManifest.xml` and user acceptance at runtime. The app requests `Permission.sms` via `permission_handler` in `home_dashboard.dart`.
- Background SMS delivery varies across Android versions. Use real devices for end-to-end tests.

## Files to inspect for common edits / touch points

- `lib/main.dart` — notifications init, background handler, route mapping
- `lib/home_dashboard.dart` — parsing logic, persistence, notification display, permission checks, UI widgets
- `android/app/src/main/AndroidManifest.xml` — ensure SMS permissions & broadcast receivers if you modify background behavior
- `pubspec.yaml` — add/update dependency versions here (run `flutter pub get` after changes)
- `test/widget_test.dart` — a starting place for widget tests; expand tests around parsing and persistence

## Quick examples to reference while coding

- Regex example used across the codebase (copy/paste safe):
  - `final regex = RegExp(r'(?:rs\.?|inr)\s*([0-9,]+\.?[0-9]*)', caseSensitive: false);`

- SharedPreferences usage pattern (in `home_dashboard.dart`):
  - read: `final prefs = await SharedPreferences.getInstance(); final total = prefs.getDouble('todayTotal') ?? 0.0;`
  - write: `prefs.setDouble('todayTotal', todayTotal);`
  - transactions: store JSON strings via `prefs.setStringList('transactions', listOfJsonStrings);`

## When editing or refactoring — checklist

- Preserve `@pragma('vm:entry-point')` for any background entry points.
- If you change storage keys or transaction format, add a migration path that converts old `transactions` list entries to the new format.
- Keep hero tag strings unchanged unless intentionally updating animations across pages.
- Update `pubspec.yaml` and run `flutter pub get` after adding/removing packages.
- Test on a physical Android device for SMS and background notification behavior.

## What I could not auto-discover

- Any CI/CD steps or custom Gradle tasks beyond the standard Flutter build (none found in repo). If you use a specific device farm or signing config, tell me and I will add it here.

---

If you'd like, I can:
- add an AndroidManifest snippet showing where to add SMS permissions,
- add a small unit test that checks the regex parsing against several carrier-message examples, or
- add a short local dev script (PowerShell) that automates `flutter analyze && flutter pub get`.

Tell me which of those you'd like and I'll update this file.
