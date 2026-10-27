# Ledgerly branding

- `source_concept.jpg` — original concept raster (1024²)
- `glyph_fg.svg` / `icon_fg.png` — white L→trend→glowing dot (transparent), adaptive foreground
- `glyph_mono.svg` / `icon_mono.png` — solid black monochrome layer (Android 13 themed icons)
- `bg_gradient.svg` / `icon_bg.png` — indigo `#1E1B7A` → violet `#5B2BC4` adaptive background
- `icon_full.svg` / `icon_full.png` — legacy full icon
- `splash_glyph.png` — splash-centered white glyph

Regenerate Android assets:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
