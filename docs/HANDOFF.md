# Ledgerly — Developer Handoff

**Version:** 1.0.1+2 · **Branch:** `feat/p15-trustworthy-records` (PR #17) · Flutter / Dart, Android only
Read `docs/FUNCTIONAL_SPEC.md` first for *what* the app does. This file covers *how* it is built.

---

## 1. Quickstart (15 minutes)

```powershell
git clone https://github.com/abhranilp1998/expensetracker_reloaded
cd expensetracker_reloaded
git checkout feat/p15-trustworthy-records
flutter pub get
flutter analyze      # expect 0 errors (about 44 info-level lints)
flutter test         # expect 167 passing
flutter run -d <device-id>
```

Git rules:
- Always work on a branch (`feat/...`). Never commit to `master`.
- PRs are stacked: base each PR on the previous step's branch.

---

## 2. Architecture

```
UI (screens/, widgets/)
   │  ref.watch / ref.read
   ▼
Riverpod providers (providers/providers.dart)
   │
   ▼
TransactionRepository (data/repositories/)  ──►  Drift AppDatabase (SQLite, schema v2)
   ▲
   │  ingestSms / importMessages
services/sms_*  ──►  domain/sms (SmsParser, SmsClassifier: pure Dart)
   ▲
Telephony plugin: live SMS listener (foreground + background isolate), inbox reads
```

- **State:** Riverpod 2-style `Provider` / `StreamProvider` / `Notifier`. Lists and totals
  come from **Drift watch streams**, so every screen updates by itself after an insert, edit
  or delete. Nothing needs a manual refresh.
- **Storage:**
  - Drift (SQLite) holds transactions and learned rules.
  - SharedPreferences holds settings, flags, the PIN hash and the event log.
- **Background SMS:** a top-level `smsBackgroundHandler` (`@pragma('vm:entry-point')`) runs
  in its own isolate. It opens its own DB instance and re-reads prefs from disk
  (`AppSettings.notificationsEnabled()` reloads them).
- **Navigation:**
  - Named routes in `routes/app_routes.dart`. `/` is a bootstrap gate that goes to
    onboarding or home.
  - Bottom tabs live in `MainShell` (an `IndexedStack` driven by `shellTabProvider`).
- **Page transitions:** `AnimationVariants.createRoute` uses the user's chosen style, or
  switches instantly when animations are off.

### 2.1 Providers (`lib/providers/providers.dart`)

| Provider | Kind | Purpose |
|---|---|---|
| `clockProvider` | Provider | Injectable "now" (tests) |
| `databaseProvider`, `transactionRepositoryProvider` | Provider | DB + repository |
| `currentDayProvider` | StreamProvider | Emits now, then again at each local midnight |
| `todayRangeProvider`, `weekRangeProvider`, `monthRangeProvider` | Provider | `DateRange`s (local calendar, week starts Monday) |
| `rangeTransactionsProvider` | StreamProvider.family | Confirmed, non-deleted rows in a range |
| `todayTransactionsProvider`, `allTransactionsProvider`, `recentTransactionsProvider` | Provider / StreamProvider | Lists (Recent = newest 5) |
| `todaySummaryProvider`, `weekSummaryProvider`, `monthSummaryProvider`, `allTimeSummaryProvider` | Provider | `Summary` (spent / income / net / count, in paise) |
| `themeControllerProvider` | NotifierProvider | Theme mode + accent → `MaterialApp` |
| `currencyProvider` | NotifierProvider | Currency code (symbol only) |
| `shellTabProvider` | NotifierProvider | Selected bottom tab (0 Home, 1 Activity, 2 Review, 3 Settings) |
| `userNameProvider` | AsyncNotifierProvider | Display name |
| `reviewQueueProvider`, `learnedRulesProvider` | StreamProvider | Review queue, rules |

### 2.2 Database (`lib/data/db/`)
- `tables.dart` defines `Transactions` (`TxnRow`) and `LearnedRules` (`RuleRow`).
- `app_database.dart`: `schemaVersion = 2`. The v1 → v2 migration adds the review columns
  and the rules table.
- `app_database.g.dart` is generated. After editing tables, run
  `dart run build_runner build --delete-conflicting-outputs`, bump `schemaVersion`, add an
  `onUpgrade` step, and add a test in `test/data/`.
- `TransactionRepository`:
  - `insert` runs both dedupe checks.
  - Also: `watchRange`, `watchAll`, `softDelete`, `softDeleteAll`, `resolveReview`
    (applies to the whole template and upserts a rule), and the rules CRUD.
- `data/migration/prefs_migration.dart` is a one-time move of legacy SharedPreferences
  transactions into the DB.

### 2.3 Services (`lib/services/`, mostly static classes)

| Service | Responsibility |
|---|---|
| `sms_service.dart` | Permission check, live listener, `readInbox(window)`, `scanInbox` (sets `smsInboxImportV1` when it finishes) |
| `sms_ingest.dart` | Classify one SMS and store it: added / review / duplicate / dropped |
| `sms_import.dart` | Batch import with progress, cancel, and per-message try/catch → `ImportSummary` |
| `notification_service.dart` | Shows notifications. The `review` payload goes to `pendingPayload` and `MainShell` opens Review. Cold start uses `checkLaunchDetails()` |
| `permission_service.dart` | SMS + notification requests, restricted-settings outcome |
| `debug_unlock_service.dart` | PIN hash/salt, lockout, legacy-format flag, biometric |
| `theme_service.dart`, `app_settings.dart`, `user_prefs_service.dart` | Prefs-backed settings |
| `event_logger_service.dart` | Local event log in prefs (last 500) |

### 2.4 Domain (`lib/domain/`)
- `sms/sms_parser.dart`: amount, direction, merchant, reference, OTP/promo/failed/reminder
  flags, `toMinor`, `dedupeHash`.
- `sms/sms_classifier.dart`: score, thresholds (accept ≥ 0.7, drop < 0.2 when promotional),
  learned-rule override.
- `sms/sms_template.dart`: template key (sender + masked body).
- `summary/summary.dart`: `Summary`, `summarize`, `DateRange`.
- `summary/insights.dart`: `buildDayInsights`, `previous7DaysRange`, `categoryLabel`.

---

## 3. Folder map

```
lib/
  main.dart              init (notifications + launch details, prefs migration, theme,
                         settings, currency, SMS listener), MaterialApp
  providers/             all Riverpod providers
  routes/                app_routes (named routes + bootstrap gate), animation
                         variants / preferences / showcase
  screens/               home_dashboard, history_page (Activity), review_queue_page,
                         comprehensive_settings_page, today_insights_page, till_now_page,
                         profile_page, inbox_scan_page, learned_rules_page,
                         debug_hub_page, demo_page, event_logs_page, main_shell
  screens/onboarding/    onboarding_flow (6 pages)
  widgets/               app_drawer, transaction_tile, transaction_actions,
                         add_transaction_sheet, permissions_section, debug_pin_dialog,
                         debug_pin_section, summary_row, drawer_tile
  domain/sms, domain/summary   pure logic (unit-tested)
  data/db, data/repositories, data/migration, data/txn_view.dart
  services/              see §2.3
  utils/                 money.dart (Money formatting, parseMoneyInput, plural),
                         constants, animations
test/                    unit, data and widget tests (see §5)
docs/                    FUNCTIONAL_SPEC, HANDOFF, SIDELOAD_ANDROID
android/                 Gradle (Kotlin DSL), manifest, signing
```

---

## 4. Build, run and debug on Windows over USB

1. On the phone: enable Developer options (tap *Build number* 7×), then **USB debugging**.
   On Xiaomi/Redmi also enable *Install via USB* and *USB debugging (Security settings)*.
2. Plug in the cable, choose *File transfer*, and accept the RSA prompt.
   `adb devices` should list the serial as `device`.
3. Run:
   - `flutter run -d <device-id>`
   - Or in VS Code: *Run and Debug* → **Ledgerly (debug)**. Other configs: profile, release,
     attach, tests.
4. Hot reload / restart: press **r** or **R** in the `flutter run` terminal, or use the VS Code
   buttons. Use hot restart (R) after changing providers or `main()`.
5. **Screen stays on in debug:** `main.dart` calls `WakelockPlus.enable()` only when
   `kDebugMode`. Release and profile builds are not affected.
6. Logs: `flutter logs -d <id>` or `adb logcat -s flutter`. Never log SMS bodies.
7. Reinstall keeping data: `adb install -r -g app.apk`. `-g` grants the runtime permissions.
   To see onboarding again you need `adb shell pm clear com.abhranil.ledgerly`, which
   **wipes all data**.
8. Emulator SMS is unreliable. Check real SMS receipt on a phone.

Toolchain (current): Gradle 8.14, AGP 8.11.1, Kotlin 2.2.20, JDK 17, compileSdk 36.

---

## 5. Tests

`flutter test` runs **167 tests**. All pass on 1.0.1+2. Run one file with
`flutter test test/<file>.dart`.

| File | Covers |
|---|---|
| `sms_parser_test.dart` | Amount and direction extraction, references, merchants |
| `sms_classifier_test.dart` | Scores, accept/review/drop, OTP/promo/failed/reminder, learned rules |
| `sms_ingest_test.dart` | Storing results, statuses, duplicates |
| `sms_import_test.dart` | Promo dropped, debit kept, summary counts, re-scan adds nothing, cancel, scan page reads nothing before Start |
| `money_test.dart` | `parseMoneyInput` rules, formatting |
| `manual_entry_test.dart` | Add sheet validation, `softDeleteAll` |
| `summary_providers_test.dart` | Day/week/month ranges |
| `settings_truth_test.dart` | Toggles persist and apply immediately |
| `debug_pin_test.dart` | 4–6 digit rule, salted hash, remove, lockout 30s → 2m → 5m, setup dialog, outside tap, Showcase labels |
| `run4_fixes_test.dart` | Plurals, Recent list, time labels, "1 try left", currency note |
| `codex_review_test.dart` | Codex A1–A8: long amount, "UPI payment" reference, malformed SMS import, Review card at 360dp, legacy PIN, 7-day average, Showcase persistence, Settings after Reset |
| `notification_tap_test.dart` | Tap while running → Review, cold-start payload, no payload does nothing |
| `onboarding_name_test.dart` | Shared name rule; empty name blocks onboarding |
| `data/transaction_repository_test.dart` | Insert/dedupe, bulk insert, uuid/sync fields, soft delete, ranges |
| `data/schema_migration_test.dart` | v1 → v2 keeps rows |
| `data/prefs_migration_test.dart` | Legacy prefs migration is idempotent |
| `flow/*` | Debug unlock, insights maths, MainShell tabs, onboarding prefs, back nav and "See all", search and theme, settings sections |
| `services/permission_outcome_test.dart` | Permission outcomes |
| `widget_test.dart` | Toolchain smoke test |

Fixtures: `test/fixtures/sms_samples.dart`.

---

## 6. Release build and signing

```powershell
flutter build apk --release --split-per-abi --target-platform android-arm64
# -> build\app\outputs\flutter-apk\app-arm64-v8a-release.apk  (about 30 MB, about 18 MB zipped)
```

- **Signing:**
  - `android/app/build.gradle.kts` reads `android/key.properties` (gitignored) with
    `storeFile`, `storePassword`, `keyAlias` and `keyPassword`.
  - **If `key.properties` is missing, release builds silently fall back to the debug key.**
    That is fine for local testing but must not be distributed, because an APK signed with
    a different key can't update an installed one.
  - The v8–v11 APKs were signed with the same release key (cert SHA-256 `cff87aad…a051e0`).
    Back up the keystore; losing it forces users to uninstall.
- **Version codes:**
  - `pubspec.yaml` is `1.0.1+2`. With `--split-per-abi`, Flutter adds an ABI offset, so the
    arm64 APK reports **versionCode 2002** (+2000; armeabi-v7a would be +1000 and x86_64
    +4000).
  - It still upgrades over earlier builds. Keep using split builds consistently, or a
    universal build (versionCode 2) can't replace a split one.
- Verify a build: `apksigner verify --print-certs app.apk` and
  `aapt2 dump badging app.apk | head -1`.

---

## 7. Open items

- **Unmerged PR stack:**
  - PRs #1–#17 are stacked (`p0-tooling` → … → `p15-trustworthy-records`) and none are
    merged.
  - `master` is **46 commits behind** this branch. Merge in order (#1 first) or squash the
    stack.
- **No CI:** a workflow was drafted but never committed (the token lacked `workflow`
  scope). Add `flutter analyze` + `flutter test` on PRs.
- **Kotlin:** the project uses 2.2.20. A planned upgrade to 2.3.20 means changing
  `org.jetbrains.kotlin.android` in `android/settings.gradle.kts` and re-testing the
  release build.
- **Big settings page:** `comprehensive_settings_page.dart` is about 1.3k lines; split it
  per section.
- **Static services:** `UserPrefsService`, `DebugUnlockService`, `PermissionService`,
  `ThemeService`, `AppSettings` and `NotificationService` are static, which makes them
  harder to fake. Move them behind providers.
- About → App Version is hard-coded "1.0.0". Read it from `package_info_plus` or similar.
- Onboarding's *Skip setup* saves the default name "User".
- The event log lives in SharedPreferences; consider a Drift table.
- About 44 analyzer info-level lints remain, mostly the `Radio` `groupValue` deprecation and
  `use_build_context_synchronously`.
- Device check still pending for the 1.0.1 fixes; see FUNCTIONAL_SPEC §8.
