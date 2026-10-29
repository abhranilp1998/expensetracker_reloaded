# Sideloading Ledgerly on Android (permissions)

## What we declare

`READ_SMS`, `RECEIVE_SMS`, `POST_NOTIFICATIONS`. Location / phone / SEND_SMS from
`another_telephony` are stripped from the merged manifest (`tools:node="remove"`).

## Why toggles are greyed out

Two separate Google mechanisms often stack (especially in **India**):

### 1. Play Protect — enhanced fraud protection (install-time)

Pilot in India (also SG/TH/BR): installs from **internet-sideloading sources**
(browser, messaging apps, file managers) are **blocked** when the APK declares
`RECEIVE_SMS`, `READ_SMS`, notification-listener, or Accessibility.

Sources:
- https://blog.google/intl/en-in/products/launching-enhanced-fraud-protection-pilot-in-india/
- https://developers.google.com/android/play-protect/warning-dev-guidance

Workaround: install via **`adb install`**, Play Store / internal testing, or a
trusted store — not by tapping an APK downloaded in Chrome/WhatsApp/Files.

### 2. Restricted settings (grant-time, Android 13 → expanded in 15)

Official help: https://support.google.com/android/answer/12623953

Android 15 CDD expands Restricted settings to **runtime SMS** (and dialer/SMS
roles, overlay, usage access, etc.) for packages installed as
`PACKAGE_SOURCE_DOWNLOADED_FILE` / `PACKAGE_SOURCE_LOCAL_FILE`.

Sources:
- https://www.androidauthority.com/android-15-restricted-settings-sideloading-3481098/
- https://www.androidauthority.com/android-15-enhanced-confirmation-mode-3436697/

Symptom: SMS (and sometimes related) toggles are **greyed** with
“for your security this setting is currently unavailable.” The in-app dialog may
never appear; `permission_handler` often reports `permanentlyDenied`.

**Unlock (UI):**
1. Attempt Grant once in the app (so the ⋮ option appears).
2. Settings → Apps → Ledgerly → **⋮ → Allow restricted settings** (PIN/biometrics).
3. Permissions → SMS → Allow.
4. Return to the app.

**Unlock (ADB):**
```bash
adb install -r -g path/to/ledgerly-arm64.apk
# or, if already installed from a browser:
adb shell cmd appops set com.abhranil.ledgerly ACCESS_RESTRICTED_SETTINGS allow
adb shell pm grant com.abhranil.ledgerly android.permission.READ_SMS
adb shell pm grant com.abhranil.ledgerly android.permission.RECEIVE_SMS
adb shell pm grant com.abhranil.ledgerly android.permission.POST_NOTIFICATIONS
```

ADB / Play installs are generally **not** treated as local-file sideloads, so
Restricted settings often do not apply.

### POST_NOTIFICATIONS

Not part of the SMS restricted-settings group. If notifications are also blocked,
check OEM overlays (Xiaomi/Samsung) or that the merged APK actually declares
`POST_NOTIFICATIONS` (`aapt2 dump permissions`). Ledgerly does declare it.

## Play Protect “had to turn Protect off”

Debug-signed + `com.example.*` package + SMS permissions make Protect much more
aggressive. P10 uses `com.abhranil.ledgerly` and a local release keystore. That
reduces heuristics but **does not** bypass India’s fraud-protection pilot when
installing a SMS-capable APK from a browser — use adb or Play for install.
