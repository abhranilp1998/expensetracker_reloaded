# Ledgerly — Functional Specification

**Version:** 1.0.1 (build 2) · **Branch:** `feat/p15-trustworthy-records` · **Platform:** Android only
**Package:** `com.abhranil.ledgerly` · Single user · Offline, everything stays on the phone

This document describes what the app does today, verified against the code. Anything not
listed here is not implemented.

---

## 1. Product overview

Ledgerly turns bank, card and UPI SMS on the phone into a personal ledger. The user sees
**how much they spent today**, their income and their net, without typing anything.

- New bank SMS are read as they arrive and become transactions automatically.
- Past SMS can be imported once the user agrees (they choose how far back).
- Messages the app is unsure about are **not guessed**: they wait in the **Review** tab and stay
  out of every total until the user decides.
- Each Review decision becomes a **learned rule** for that message format, so similar SMS are
  handled automatically next time.
- Manual entries (expense or income) can be added, edited and deleted.
- No account, no cloud, no analytics, no network calls.

---

## 2. Screens

### 2.1 Launch
`/` shows a spinner and checks the `onboardingCompletedV1` flag. If it is set, the app goes to
Home. If not, it goes to Onboarding.

### 2.2 Onboarding (first run, 6 pages)
There is a progress bar with "n/6" at the top and a Back arrow from page 2 onwards. Pages
can't be swiped; you move with the buttons.

| # | Page | Content / controls |
|---|---|---|
| 1 | Welcome | Time-of-day greeting ("Good morning" before 12:00, "Good afternoon" before 17:00, otherwise "Good evening"), "Welcome to Ledgerly". **Continue**, or **Skip setup** (finishes straight away with the defaults). |
| 2 | What Ledgerly does | Four points: reads bank & UPI SMS, tracks spend & income, learns from your reviews, stays on your phone. |
| 3 | About you | **Your name** (required; an empty name shows "Enter a name" and blocks Continue). **Currency** chips: INR, USD, EUR, GBP, AED. Note: "Changes the symbol only; amounts are not converted." |
| 4 | Your setup | Theme (Light / Dark / System), accent colour, **Import past SMS** switch (default on), **Notifications** switch (default on). |
| 5 | Permissions | **Grant SMS & notifications**, **Open app settings**, a status line, and Restricted-settings help when Android blocks SMS. **Continue** or **Continue without SMS**. |
| 6 | All set | "You're all set, *name*", a summary of the choices, then **Go to Home**. |

When onboarding finishes, it saves the name, currency, import choice, notifications,
theme and accent, and sets `onboardingCompletedV1=true`. If *Import past SMS* is on, SMS
permission is granted and no import has finished before, the app opens **Scan SMS inbox**.
Otherwise it opens Home. Onboarding doesn't appear again unless the app data is cleared.

### 2.3 Home tab
- Greeting with the user's name and the side-menu button.
- **Hero card:** today's spend, then "Income … · Net …". Tap it to open **Today's insights**
  (shared Hero animation).
- **This week** and **This month** mini-cards (the week starts on Monday).
- **Balance snapshot:** Today spent / Today income / Net today.
- **Recent:** the newest 5 confirmed transactions from any date. Older ones carry a date prefix.
  **See all** switches to the Activity tab. With no data it shows "No transactions yet".
- **Add** button: opens the Add transaction sheet (§2.10).

### 2.4 Today's insights
- Today's spend (Hero target).
- **vs yesterday:** % change against yesterday's spend.
- **vs avg of previous 7 days:** % change against the daily average of the 7 *complete* days
  before today (today is excluded).
- **By category:** today's debits grouped by a label. The label is the merchant, then the
  sender, then the note (cut to 24 chars), then "Manual"/"Other".
- **By hour:** today's spend across 24 hours.
- **Top debits:** today's 5 largest expenses.

### 2.5 Activity tab
- Filter chips **Day / Week / Month / All** (default **All**).
- Search box: "Search merchant, note, amount…". It matches merchant, note, sender or amount,
  case-insensitively.
- Rows are grouped by day ("Today", "Yesterday", or "MMMM d, yyyy"), each with "Spent …" for
  that day.
- **Tap** a row to edit it. **Long-press** for an Edit / Delete sheet. Delete asks first
  ("Totals will be recalculated.") and then soft-deletes the row.

### 2.6 Review tab
- A badge on the tab shows the number of pending items (99+ is capped).
- Each card shows the amount, sender · time (shortened with "…" on narrow screens), the SMS
  text (up to 4 lines), "Confidence n%", and three buttons: **Expense / Income / Ignore**.
- One decision resolves this card **and every other queued card with the same message
  template**, and it saves a learned rule. A snackbar confirms ("… rule saved").
  - **Expense/Income:** the row becomes confirmed with that type.
  - **Ignore:** the row is soft-deleted.
- When nothing is pending it shows "All caught up".

### 2.7 Settings tab
Jump chips at the top lead to these sections:

- **Appearance:**
  - Theme Mode (Light/Dark/System) and Accent Color (9 colours).
  - Route Animations (style picker) and **Enable Animations**.
  - Links to *Needs review*, *Learned rules* and *Animation Showcase*.
- **SMS & Permissions:**
  - Device access: SMS / Notifications status with **Grant**, **Open app settings**, and
    restricted-settings help.
  - **Scan SMS inbox.**
  - *Name & currency* (points to Profile).
  - **Debug PIN** (set / change / remove).
- **Learned rules:** *Manage learned rules* lists each rule (sender, action, masked sample).
  Delete removes the rule, and future matching SMS go back to Review.
- **Feature Settings:** Notifications, Haptic Feedback, Activity log.
- **About:**
  - App Version, Platform, Storage Info.
  - **Clear All Preferences** resets the feature toggles only.
  - **Reset to Defaults** resets theme, accent, animation and the feature toggles; the page
    then shows the defaults straight away.

### 2.8 Side menu (drawer)
Shows the user's name and these items: **Till Now**, **Profile**, **Animation Showcase**,
**Debug** (PIN-protected) and **Settings**.

- **Till Now:**
  - Financial overview: total spent all time, this month, this week.
  - Transaction analysis: total transactions, average, highest and lowest expense.
  - Complete expense history and recent transactions.
- **Profile:** display name (required, "Enter a name"), currency (INR/USD/EUR/GBP/AED,
  symbol-only note), **Save**. Appearance lives in Settings.
- **Animation Showcase:** 10 expandable cards, one per page-transition style, each with a
  preview. Choosing a style **saves it** (the same setting as Settings → Route Animations).
- **Debug** (after PIN or biometric):
  - **Demo:** insert 5 sample transactions, or reset all data (soft-delete). This is a
    destructive action.
  - **Event Logs:** local activity log with filters and statistics, and Clear All Logs.
    Export shows "coming soon".
  - **Lock:** ends the unlocked session.

### 2.9 Scan SMS inbox
1. **Consent:** explains what is read and that nothing is uploaded. The user picks a range
   (**30 days / 90 days / 180 days / 1 year**, default 180) and taps **Scan last …** or
   **Not now**. Nothing is read before Start.
2. **Scanning:** a progress count and **Cancel**. Back also asks the scan to stop, and the
   scan stops between messages.
3. **Summary:** the title is "Scan complete", or "Scan stopped" if cancelled (partial results are kept), followed by "Checked n messages" and these rows:
   - Transactions found, Added, Already added (skipped), Needs review, Not transactions.
   - *Could not read*, shown only when some messages failed.
   - **Review n messages** opens Review; **Done** closes the scan.
4. **Failed:** "The scan could not finish", with **Try again** and **Not now**.

A finished scan sets `smsInboxImportV1=true` (import done). A cancelled or failed
scan doesn't. Running a scan again is safe because duplicates are skipped.

### 2.10 Add / edit transaction sheet
- **Expense / Income** toggle, **Amount (symbol)**, **Note (optional)**, **Save**.
- Editing uses the same sheet, pre-filled, with the title "Edit transaction".

---

## 3. Business rules

### 3.1 Amounts and totals
- Every amount is stored as an **integer in minor units** (paise), so there's no
  floating-point drift in totals.
- Manual amount input:
  - Allowed: digits with an optional "." and up to 2 decimals. Commas are ignored.
  - The keyboard blocks `e`, `-`, `+` and spaces.
  - Errors: "Enter an amount", "Use digits only, with up to 2 decimals (e.g. 120.50)",
    "Enter an amount greater than 0", "Amount is too large".
  - The maximum is 1,000,000,000.00. Length is checked before parsing, so a 40-digit paste
    shows an error instead of crashing. Leading zeros don't count.
- Totals (Home, Activity, Till Now, Insights) include **confirmed, non-deleted** rows only.
  Review rows are excluded until the user decides.
- Credit counts as income; everything else counts as spend. Net = income − spent.
- Day, week and month use the local calendar. The week starts Monday. Ranges are
  `[start, end)`. The day rolls over at local midnight without restarting the app.

### 3.2 7-day average
- The daily average is the spend over the **7 complete days before today**, divided by 7.
- Today is excluded, so a half-finished day never lowers it.
- The label reads "vs avg of previous 7 days".

### 3.3 Currency
- Choices: INR, USD, EUR, GBP, AED. The choice changes the **symbol only**; stored amounts are
  never converted.
- Every money label rebuilds when the currency changes.

### 3.4 SMS reading, classification and dedupe
1. **Amount:**
   - Found after ₹ / Rs / INR, or as "debited/credited by|with|for N" when there's no symbol.
   - Amounts with more than 12 rupee digits are rejected as not a transaction.
2. **Hard drops** (never stored): no amount, zero amount, or OTP text ("OTP", "verification
   code", "do not share").
3. **Learned rule:** if the message template (sender + masked body) has a rule, the rule
   decides: Expense, Income, or Ignore (drop).
4. **Failed / declined / reversed / insufficient** messages, and **reminders** ("is due",
   "EMI", "will be debited", collect requests), are dropped.
5. **Score** (0–1):
   - Base 0.15.
   - +0.4 for a past-tense money verb, +0.25 for a masked account/card, +0.2 for a
     reference/UPI/UTR.
   - −0.25 per offer word (up to 3), −0.2 for a link.
6. **Decision:**
   - The strict parser succeeds and the score is ≥ 0.7: **confirmed**.
   - The score is < 0.2 and the message looks promotional (offer words or a link): **dropped**.
   - Anything else goes to **Review**.
7. **Dedupe:** a row isn't stored again when either check matches. Deleted and ignored rows
   count too, so they never come back on a re-scan.
   - **Same dedupe hash:**
     - With a bank reference: sender + amount + type + reference.
     - Without one: sender + amount + type + body + the minute received.
     - A reference must contain a digit, so words like "UPI payment" are never treated as a
       reference and two different payments aren't merged.
   - **Same SMS:** same sender + exact timestamp + exact body.
8. **Import robustness:** each message is processed on its own. A message that throws is
   counted under *Could not read*, and the scan carries on.
9. All senders are accepted; there is no allow-list.

### 3.5 Debug PIN
- **New / changed PIN:** 4–6 digits, entered twice. It is stored only as
  `sha256(salt::pin)` with a random salt per set.
- **Unlock:** use the PIN or a biometric/device credential. The unlock lasts for the app
  session (until **Lock** or a restart).
- **Lockout:** 5 wrong tries lock PIN entry for **30 s**, then **2 min**, then **5 min**
  (capped). The lock is persisted, so killing the app doesn't reset it. A correct PIN or a
  biometric clears it, and biometric unlock is allowed during a lockout. The dialog shows
  "Wrong PIN. n tries left." and a countdown.
- **Legacy PINs:**
  - PINs saved by older builds may contain letters or more than 6 digits. Existing-PIN fields
    accept any characters (up to 32).
  - After a successful legacy unlock, the app asks "Update your Debug PIN" (**Change PIN** /
    **Later**). Later keeps the old PIN working.
  - An old PIN that already fits the 4–6 digit rule is upgraded silently.
- Tapping outside the PIN dialog doesn't close it; use Cancel.
- If no PIN is set, opening Debug asks you to set one first.

### 3.6 Notifications
- Sent for live SMS only, and only when Settings → Notifications is on:
  - Confirmed: "Transaction detected" with "₹… spent · merchant" or "₹… received".
  - Uncertain: "Needs review" with "₹… — tap to review".
- **Tapping "Needs review"** opens the app on the **Review tab** and closes any page open on top.
  This works when the app is running, in the background, or fully closed (cold start).
- Other notifications just open the app.

### 3.7 Back navigation
- On Activity, Review or Settings, Back goes to Home. On Home, Back leaves the app.
- During an inbox scan, Back asks the scan to stop instead of leaving silently.

### 3.8 Display name
- It can't be empty, in Profile or during onboarding.
- It is shared by the Home greeting, the drawer and Profile.

---

## 4. User flows

**First run**
1. Install and open the app. Onboarding page 1 appears.
2. Continue through pages 2–3. Enter your name (required) and choose a currency.
3. Page 4: choose theme and accent, and keep *Import past SMS* on.
4. Page 5: tap *Grant SMS & notifications* and accept. If Android says SMS is restricted,
   follow the on-screen steps: App info → ⋮ → Allow restricted settings.
5. Page 6: tap *Go to Home*. Scan SMS inbox opens; choose a range and tap Scan.
6. The summary appears. Tap *Review n messages* or *Done* to reach Home.

**Daily use**
1. A bank SMS arrives. The transaction appears on Home within moments, and a notification
   is shown if enabled.
2. Uncertain SMS raise the Review badge. Open Review and tap Expense / Income / Ignore.
   Similar queued items are resolved too, and a rule is saved.
3. Tap the hero card to see today's insights.

**Add an expense by hand**
1. Home → Add.
2. Choose Expense, enter the amount and an optional note, then Save.
3. Totals update immediately.

**Fix a wrong entry**
1. Activity → tap the row → edit → Save.
2. Or long-press → Delete → confirm.

**Undo a learned rule**
1. Settings → Manage learned rules.
2. Delete the rule. Future matching SMS go to Review again.

**Re-scan the inbox**
1. Settings → Scan SMS inbox.
2. Choose a range and Scan. Already-added messages are counted as skipped.

**Open Debug**
1. Drawer → Debug. Set a PIN on the first visit, otherwise enter it or use your fingerprint.
2. The Debug hub opens: Demo, Event Logs, Lock.

---

## 5. Settings reference

| Setting | What it does | Default | Stored in (SharedPreferences key) |
|---|---|---|---|
| Theme mode | Light / Dark / System | System | `app_theme_mode` |
| Accent colour | Seed colour for the whole theme (green, blue, purple, teal, indigo, orange, red, pink, cyan) | green (onboarding pre-selects the current value) | `app_accent_color` |
| Route animation style | Page transition style (Settings or Showcase) | fadeSlide | `animationType` |
| Enable animations | Off means pages switch instantly | on | `pref_animations_enabled` |
| Notifications | Notify on detected SMS transactions | on | `pref_notifications` |
| Haptic feedback | Vibrate on tabs, Add, Save, Delete | on | `pref_haptic_feedback` |
| Activity log | Keep the local event log (last 500 events) | on | `pref_event_logging` |
| Name | Greeting, drawer, Profile | "User" until set | `userName` |
| Currency | Symbol for every amount | INR | `userCurrency` |
| Import past SMS | Offer the inbox scan after onboarding | on | `pref_import_past_sms` |
| Debug PIN | Protects Debug | not set | `debugPinHashV1`, `debugPinSaltV1`, `debugPinFormatV2`, lockout keys |
| Onboarding done | Skip onboarding on launch | false | `onboardingCompletedV1` |

---

## 6. Permissions

| Permission | Why | Required? |
|---|---|---|
| `READ_SMS` | Read the inbox for the user-started scan | Yes, for auto-tracking |
| `RECEIVE_SMS` | Process new bank SMS as they arrive (also in the background) | Yes, for auto-tracking |
| `POST_NOTIFICATIONS` | "Transaction detected" / "Needs review" alerts | Optional |
| `USE_BIOMETRIC` | Fingerprint/face unlock for Debug | Optional |

Location, phone-state and SEND_SMS, which the telephony plugin would otherwise add, are
explicitly removed in the manifest. Without SMS permission the app still works for manual
entries. On sideloaded installs, Android 13+ can grey out SMS ("Restricted settings");
the app explains how to allow it. See `docs/SIDELOAD_ANDROID.md`.

---

## 7. Data stored on the device and privacy

- **SQLite (Drift) database:**
  - `Transactions`: amount in paise, type, source (sms / import / manual / migrated), time
    (UTC ms), sender, merchant, note, **raw SMS body**, dedupe hash, status
    (confirmed / review), template key, confidence, a soft-delete flag and sync fields.
  - `LearnedRules`: template key, sender, action and a **masked** sample.
- **SharedPreferences:** the settings in §5, the Debug PIN hash and salt (never the PIN
  itself), and the local event log (last 500 events).
- **Nothing leaves the phone.** There are no network calls and no analytics. Raw SMS text
  is never written to logs or the event log; logs show amounts, senders and outcomes only.
- Deleting is a soft delete, so deleted rows stay hidden but still block re-imports.
  Uninstalling or clearing the app's data removes everything.

---

## 8. Known limitations

- **Skip setup** on onboarding page 1 finishes with the defaults, so the name is saved as
  "User". It can be changed in Profile.
- About → *App Version* is hard-coded to "1.0.0"; it does not read 1.0.1 from the build.
- Categories in Insights are labels based on merchant or sender. There are no user
  categories or budgets.
- Currency is symbol-only. There is no conversion and no per-transaction currency.
- Event Logs → Export is not implemented ("coming soon").
- *Storage Info* in About is static text.
- The Demo "Reset All Data" soft-deletes every transaction and can't be undone in the UI.
- Android only. There is no backup, export or cloud sync yet; the data model is ready for
  sync.

### Not yet verified on a real device (v1.0.1)
These have automated tests but haven't been tried on the phone:
- **Codex fixes 1–10:**
  - UPI "payment" dedupe, malformed SMS during import, long amounts, legacy PIN entry and
    the upgrade prompt.
  - 7-day average, the Review card at 360dp, Settings after Reset, the saved Showcase
    choice.
  - **Notification tap to Review**, especially the cold start.
  - Empty name in onboarding.
- From earlier runs:
  - Cancelling an inbox scan.
  - Setting, changing and removing the Debug PIN.
  - Lockout surviving an app restart.
