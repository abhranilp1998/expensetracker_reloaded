# Ledgerly — Developer Handoff (15-minute quickstart)

1. **Clone & deps**: `git clone https://github.com/abhranilp1998/expensetracker_reloaded && cd expensetracker_reloaded && flutter pub get`
2. **Check**: `flutter analyze` (0 errors) and `flutter test` (all green).
3. **Run on a phone over USB**: enable Developer options + USB debugging → `adb devices` → `flutter run -d <id>`. VS Code: *Run and Debug* → `Ledgerly (debug)`. Full steps in the README.
4. **Read next**: `docs/FUNCTIONAL_SPEC.md` (flows, SMS pipeline, data model, providers), `docs/SIDELOAD_ANDROID.md` (permission issues).
5. **Where things live**: SMS logic `lib/domain/sms/`, ingest `lib/services/sms_ingest.dart`, DB `lib/data/db/`, all providers `lib/providers/providers.dart`, routes `lib/routes/app_routes.dart`.
6. **Schema change**: edit `tables.dart`, bump `schemaVersion` + `onUpgrade` in `app_database.dart`, run `dart run build_runner build --delete-conflicting-outputs`, add a migration test in `test/data/`.
7. **Reset first-run**: `adb shell pm clear com.abhranil.ledgerly`.
8. **Logs**: `flutter logs` or `adb logcat -s flutter`. Never log SMS bodies.
9. **Release**: create `android/key.properties` + keystore (never commit), `flutter build apk --release --split-per-abi`, install with `adb install -r -g`.
10. **Git rules**: always branch (`feat/...`) before changing files; never commit to `master`; PRs are stacked — base each PR on the previous step's branch.
