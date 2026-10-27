# Ledgerly branding

Faithful to `source_concept.jpg` (L + long rising stroke + tip dot; not a freehand vector redraw).

- `icon_full.png` — indigo/violet bg + centered glyph + soft violet tip glow (legacy launcher)
- `icon_fg.png` — glyph + soft violet halo on transparency (adaptive FG, ~58% of canvas / ~55–60% safe zone)
- `icon_bg.png` — indigo `#1E1B7A` → violet `#5B2BC4` diagonal gradient
- `icon_mono.png` — solid silhouette (L + rising stroke + tip)
- `splash_glyph.png` — same glyph+glow, larger for Android 12 splash

Centering is by the visual bounding box of L+stroke+dot (glow excluded).
Glow is a soft multi-gaussian violet (`#8B5CF6`) halo (~2× tip radius, ~35–45% opacity), not a hard white blob.

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
