# Ledgerly branding

Faithful to `source_concept.jpg` (not a freehand vector redraw).

- `icon_full.png` — original concept (legacy launcher)
- `icon_fg.png` — extracted glyph + glow on transparency (adaptive FG, ~60% safe zone)
- `icon_bg.png` — indigo `#1E1B7A` → violet `#5B2BC4` diagonal gradient
- `icon_mono.png` — solid silhouette (L + rising stroke + dot)
- `splash_glyph.png` — same glyph+glow, larger for Android 12 splash

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
