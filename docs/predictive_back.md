# Predictive back (Android 14+)

| Where | Swipe preview | Full pull |
|---|---|---|
| Pushed pages, Slide Left / Bouncy style | page follows finger off to the left | pops |
| Pushed pages, Slide Right / Liquid / Elastic | page follows finger off to the right | pops |
| Pushed pages, all other styles | Material shrink + rounded corners | pops |
| Activity / Review / Settings tab | tab shrinks, Home shows behind | lands on Home (no stack) |
| Home | page shrinks (in-app peek) | "Leaving already?" Stay / Quit |

* Opening animations are unchanged; only the back gesture uses the style-matched motion.
* Home uses an in-app peek instead of the system back-to-home preview: the system
  preview only runs when the app lets Android finish it, which would skip the
  exit confirmation.
* Animations off (Settings) or system "remove animations": no preview; Back
  works instantly with the same results.
* Code: `lib/routes/predictive_back.dart`, `LedgerlyPageRoute` in
  `lib/routes/animation_variants.dart`, `_MainShellState` in `lib/screens/main_shell.dart`.
