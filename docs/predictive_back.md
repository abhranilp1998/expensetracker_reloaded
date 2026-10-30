# Predictive back (Android 14+)

The back swipe plays the animation style selected in Settings > Animation
Settings **in reverse, under the finger** (route animation = 1 - swipe progress).
Let go early: the style animates back to rest. Pull far enough: the style's exit
finishes. The same transition code is used for opening and for back, so all 10
styles (Fade + Slide, Slide Left, Slide Right, Scale + Rotate, Morphing, Bouncy,
Liquid, Staggered, Kaleidoscope, Elastic Bounce) match automatically.

| Where | Swipe preview | Full pull |
|---|---|---|
| Pushed pages | selected style in reverse | pops |
| Activity / Review / Settings tab | selected style in reverse, Home behind | lands on Home (no stack) |
| Home | selected style, half way (peek) | "Leaving already?" Stay / Quit |

* Home uses an in-app peek instead of the system back-to-home preview: the system
  preview only runs when Android finishes back itself, which would skip the exit
  confirmation.
* Animations off (Settings) or system "remove animations": no preview; Back
  works instantly with the same results.
* Code: `RouteBackGestureListener` (`lib/routes/predictive_back.dart`),
  `LedgerlyPageRoute` + `AnimationVariants.transitionFor`
  (`lib/routes/animation_variants.dart`), `_MainShellState` (`lib/screens/main_shell.dart`).


## beta.5: unique motion styles

All 16 styles live in one table, `motionStyles` in `lib/routes/ledgerly_motion.dart`,
and one painter, `buildMotion`, used by pushed routes AND the bottom-tab shell, so
the back gesture always plays the style you picked, in reverse.

Rules:
- While the finger drives (predictive back) progress is linear: cancel returns to
  rest, commit finishes the exit.
- Overshoot (Bouncy Pop, Elastic Drop) is only used when opening/settling; reversing
  uses a plain ease. Opacity never bounces.
- Reduce motion / Enable Animations off = no transition.
- Saved prefs are stored by enum name, so the old names keep working (the old
  10 values were kept; 6 new ones appended). Kaleidoscope users stay on Kaleidoscope.

Settings > Route Animations is a collapsible picker (`AnimationStylePicker`),
collapsed by default (current name + a small live preview), grouped into Slides,
Zooms, Reveals and Springs.

Evidence frames: `RENDER_EVIDENCE=<dir> flutter test test/tool/render_motion_evidence_test.dart`.
