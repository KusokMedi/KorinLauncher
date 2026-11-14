#!/usr/bin/env bash
# Regenerate all Korin Launcher icon bitmaps from the SVG sources.
#
# Requirements: rsvg-convert (librsvg), ImageMagick 7 (magick).
# Usage: ./gen-icons.sh [--install]
#   --install  also copy the results into program_info/

set -euo pipefail

cd "$(dirname "$0")"

SIZES=(16 24 32 48 64 128 256 512 1024)
ICNS_SIZES=(16 32 64 128 256 512 1024)
ICO_SIZES=(16 24 32 48 64 128 256)

render() {
    local svg="$1" prefix="$2"
    for s in "${SIZES[@]}"; do
        rsvg-convert -w "$s" -h "$s" "$svg" -o "${prefix}-${s}.png"
    done
}

echo "==> rendering icon.svg"
render icon.svg icon

echo "==> rendering icon-light.svg"
render icon-light.svg icon-light

echo "==> building icon.ico"
ico_args=()
for s in "${ICO_SIZES[@]}"; do ico_args+=("icon-${s}.png"); done
magick "${ico_args[@]}" icon.ico

echo "==> rendering wordmark"
rsvg-convert -w 1400 -h 360 logo.svg -o logo.png
rsvg-convert -w 1400 -h 360 logo-light.svg -o logo-light.png

echo "==> building icon.icns"
icns_args=()
for s in "${ICNS_SIZES[@]}"; do icns_args+=("icon-${s}.png"); done
python3 ./build-icns.py icon.icns "${icns_args[@]}"

if [[ "${1:-}" == "--install" ]]; then
    echo "==> installing into program_info/"
    dest=../../program_info
    cp icon.svg                 "$dest/com.kusokmedi.korinlauncher.svg"
    cp icon.svg                 "$dest/com.kusokmedi.korinlauncher.logo-darkmode.svg"
    cp icon.svg                 "$dest/com.kusokmedi.korinlauncher.bigsur.svg"
    cp icon-light.svg           "$dest/com.kusokmedi.korinlauncher.logo.svg"
    cp icon-light.svg           "$dest/com.kusokmedi.korinlauncher.Source.svg"
    cp icon-256.png             "$dest/com.kusokmedi.korinlauncher_256.png"
    cp icon.ico                 "$dest/korinlauncher.ico"
    cp icon.icns                "$dest/korinlauncher.icns"
fi

echo "done"
