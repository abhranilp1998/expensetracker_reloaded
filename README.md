# Ledgerly

Android-only Flutter app that reads bank/UPI SMS on the device, turns them into debit/credit
transactions, and shows today's spend, income and net balance. Uncertain SMS go to a **Review**
queue; your decisions become **learned rules**. All data (including raw SMS) stays on the phone.

- Package: `com.abhranil.ledgerly` · State: Riverpod · Storage: Drift (SQLite)
- Version: **1.0.1+2** — see [`CHANGELOG.md`](CHANGELOG.md)
- Functional spec (screens, rules, settings, privacy): [`docs/FUNCTIONAL_SPEC.md`](docs/FUNCTIONAL_SPEC.md)
- Developer handoff (architecture, tests, release, open items): [`docs/HANDOFF.md`](docs/HANDOFF.md)
- Sideload / permission troubleshooting: [`docs/SIDELOAD_ANDROID.md`](docs/SIDELOAD_ANDROID.md)

## Prerequisites

- Flutter stable (Dart SDK per `pubspec.yaml`), Android SDK + platform-tools (`adb`) on PATH.
- JDK 17. Builds use Gradle 8.14, AGP 8.11.1, Kotlin 2.2.20.

```powershell
cd "F:\Dev\Projects - The Hub\expensetracker_reloaded"
flutter pub get
flutter analyze   # 0 errors
flutter test      # 167 tests
```

## Run on a physical phone over USB (Windows)

1. **Developer options**: Settings → About phone → tap *Build number* 7 times.
2. **USB debugging**: Settings → System → Developer options → enable *USB debugging*
   (on Xiaomi/Realme also enable *Install via USB* / *USB debugging (Security settings)*).
3. Plug in the phone, choose *File transfer*, accept the **Allow USB debugging?** RSA prompt.
   If the device is not detected, install the OEM USB driver or Google USB Driver (SDK Manager).
4. Check the connection:
   ```powershell
   adb devices          # should list <serial>   device  (not "unauthorized")
   flutter devices      # shows the id to use below
   ```
5. Run with hot reload / breakpoints:
   ```powershell
   flutter run -d <device-id>              # debug
   flutter run -d <device-id> --profile    # performance
   flutter run -d <device-id> --release
   ```
   In VS Code: pick the device in the status bar, then *Run and Debug* → `Ledgerly (debug)`.
   Press `r` for hot reload, `R` for hot restart. Debug builds keep the screen on (wakelock);
   release builds don't.
6. Attach to an app already running on the phone (debug build): `flutter attach -d <device-id>`
   (or VS Code config `Ledgerly (attach)`).
7. Logs:
   ```powershell
   flutter logs -d <device-id>
   adb logcat -s flutter                     # Dart print/debugPrint only
   adb logcat --pid=$(adb shell pidof -s com.abhranil.ledgerly)   # whole app (Git Bash/WSL syntax)
   ```
   Raw SMS text is never logged; logs show amounts/senders/outcomes only.
8. Wireless (optional, Android 11+): Developer options → *Wireless debugging* →
   `adb pair <ip>:<pair-port>` then `adb connect <ip>:<port>`.

### Installing an APK directly

```powershell
flutter build apk --release --split-per-abi --target-platform android-arm64
adb install -r -g build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

`-r` keeps data on reinstall, `-g` grants runtime permissions (SMS, notifications) at install.
Uninstalling (`adb uninstall com.abhranil.ledgerly`) or `adb shell pm clear` shows onboarding
again but **deletes all data**. The arm64 split APK has versionCode = build + 2000 (1.0.1+2 → 2002).

**Sideload restrictions:** APKs opened from Chrome/WhatsApp/Files can be blocked by Play Protect
(enhanced fraud protection, India pilot) and SMS toggles greyed out by *Restricted settings*
(Android 13+). Install with `adb install` and, if needed, App info → ⋮ → *Allow restricted
settings*. Details: [`docs/SIDELOAD_ANDROID.md`](docs/SIDELOAD_ANDROID.md).

## Release signing

`android/app/build.gradle.kts` reads `android/key.properties` (gitignored, never commit it):

```properties
storePassword=...
keyPassword=...
keyAlias=ledgerly
storeFile=C:/path/to/ledgerly-release.jks
```

If `key.properties` is missing, release builds fall back to the **debug** key (fine for local
testing, not for distribution). Keep the keystore backed up: losing it means users must
uninstall to update.

## Project layout

```
lib/
  main.dart            app entry, background SMS handler, MaterialApp
  routes/              named routes, onboarding gate, animation variants/showcase
  screens/             tabs (home, history=Activity, review, settings) + side-menu pages
  screens/onboarding/  6-page first-run flow
  widgets/             shared tiles, cards, drawer, add-transaction sheet
  providers/           all Riverpod providers (providers.dart)
  domain/sms/          parser, classifier, template keys (pure Dart, unit-tested)
  domain/summary/      totals and insights maths
  data/db/             Drift tables + database (run build_runner after schema edits)
  data/repositories/   TransactionRepository
  services/            SMS, permissions, notifications, theme, prefs, debug unlock, event log
test/                  unit, data and widget-flow tests
```

Regenerate Drift code after changing tables: `dart run build_runner build --delete-conflicting-outputs`.
