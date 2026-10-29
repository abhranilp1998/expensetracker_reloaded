# Changelog

All notable changes to Ledgerly. Versions follow `pubspec.yaml` (`name+build`).

## [1.0.1] (build 2) — 2026-10-29

Fixes from the Codex code review. Each one has a regression test that failed before the fix.

### Fixed
- **Duplicate detection:** "UPI payment" was read as a bank reference, which could merge
  two different payments into one. A reference must now contain a digit.
- **SMS import:** one malformed message (for example an absurdly large amount) no longer
  stops the scan. It is counted under "Could not read" and the scan continues.
- **Manual amount:** a very long number now shows "Amount is too large" instead of
  crashing.
- **Debug PIN:** PINs saved by older versions (with letters, or more than 6 digits) can be
  entered again. After unlocking with one, you are asked to change it to a 4–6 digit PIN.
  New PINs are still 4–6 digits.
- **Today's insights:** the average now uses the 7 complete days before today. The label
  reads "vs avg of previous 7 days".
- **Review tab:** cards no longer overflow on narrow (360dp) phones.
- **Settings → Reset to Defaults:** theme, accent and animation now show the defaults
  straight away.
- **Animation Showcase:** the chosen animation is saved and survives a restart.
- **Notifications:** tapping "Needs review … tap to review" opens the Review tab, including
  when the app was closed.
- **Onboarding:** an empty name is rejected ("Enter a name") instead of being saved as
  "User".
- **Onboarding → Skip setup:** asks for your name first (same rule as Profile) instead of
  silently saving "User". Cancel stays on onboarding.
- **About → App Version:** read from the installed package (`package_info_plus`) and shown
  as "versionName (build versionCode)", e.g. "1.0.1 (build 2002)". It was hard-coded "1.0.0".

### Changed
- Version bumped to 1.0.1+2. The arm64 split APK reports versionCode 2002.

## [1.0.0] (build 1)

First handoff build (PRs #1–#16): SMS parsing and classification, Drift database, Review
queue with learned rules, Riverpod state, 6-page onboarding, user-started inbox scan with
summary, Debug PIN with lockout, Today's insights, Home "Recent", Activity search and
filters, theme/accent/animation settings, Ledgerly icon and splash.

Earlier run-4 fixes, included before 1.0.1:
- Home "Recent" shows the newest 5 from any date.
- "1 try left" wording.
- Currency "symbol only" note.
- The hero card counts today's transactions.
