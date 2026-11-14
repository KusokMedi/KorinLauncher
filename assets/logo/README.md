# Korin Launcher logo

Monochrome mark: bold letter **K** on a rounded plate. Brand palette is
black / gray / white only.

| File | Purpose |
| --- | --- |
| `icon.svg` | Master icon, dark plate (used for the binary, dark themes, ICO/ICNS) |
| `icon-light.svg` | Light-theme variant (white plate, near-black K) |
| `logo.svg` | Horizontal lockup: mark + "Korin Launcher" wordmark, dark variant |
| `logo-light.svg` | Same lockup on light plates |
| `logo.png`, `logo-light.png` | 1400×360 renders used by the README |
| `icon.ico` | Windows icon, 16–256 px |
| `icon.icns` | macOS icon, 16–1024 px (built by `build-icns.py`, no macOS needed) |
| `icon-<size>.png` | Dark-variant rasters, 16…1024 px |
| `icon-light-<size>.png` | Light-variant rasters, 16…1024 px |

## Regenerate

```bash
./gen-icons.sh            # rasters + ico + icns + wordmark PNG
./gen-icons.sh --install  # ...and copy the icon files into ../../program_info/
```

Requires `rsvg-convert` (librsvg) and ImageMagick 7 (`magick`). `python3` is
used for the ICNS container.

After `--install`, rebuild the launcher so the new SVG lands in the binary:

```bash
JAVA_HOME=/usr/lib/jvm/java-8-openjdk ninja -C ../../build
```

## Editing the mark

Both SVGs are hand-written paths on a 512×512 canvas:

- plate: rounded rect 16…496 with `rx=108`, 6 px border in the theme's gray;
- stem: vertical round-capped stroke, width 56, from y=130 to y=382 at x=172;
- arms: round-capped 52 px strokes meeting at the stem's middle (x≈196, y=256),
  shaded with a white→gray (or black→gray) gradient.

Keep the mark inside the safe area (≥96 px from the plate edges) so small
sizes and maskable icons stay readable.
