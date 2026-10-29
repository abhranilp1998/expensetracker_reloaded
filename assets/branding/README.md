# Ledgerly branding

Pixel-faithful to `source_concept.jpg` (no redraw).

- `icon_full.png` — concept image (Lanczos), glyph bbox centered (~translate), edge fill = corner gradient
- `icon_fg.png` — same full-bleed image (adaptive FG 108dp layer)
- `icon_bg.png` — matching indigo→violet corner gradient
- `icon_mono.png` — solid silhouette (unchanged)
- `splash_glyph.png` — center crop of glyph+glow from concept

Glyph+glow fits within central ~66% safe zone.

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
