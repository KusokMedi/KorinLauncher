#!/usr/bin/env bash
#
# Install everything needed to build Korin Launcher on Arch Linux.
#
# Usage: ./scripts/deps-arch.sh [--yes]
#
# Requires working non-interactive sudo (sudo -n) — otherwise it prints the
# exact pacman command for you to run manually.

set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v pacman >/dev/null 2>&1; then
    echo "error: pacman not found — this script targets Arch Linux (or an Arch-based distro)" >&2
    exit 1
fi

# Runtime/toolchain
packages=(
    base-devel
    git
    cmake
    ninja
    extra-cmake-modules

    # Qt 6 modules used by the launcher
    qt6-base
    qt6-tools
    qt6-svg
    qt6-networkauth
    qt6-5compat
    qt6-translations

    # Libraries
    libarchive
    zlib
    tomlplusplus
    cmark
    qrencode
    gamemode
    scdoc

    # Java: JDK 8 compiles NewLaunch.jar (target 7), modern JDK runs the launcher itself
    jdk8-openjdk
    jdk-openjdk

    # Icon/asset tooling (assets/logo/gen-icons.sh)
    librsvg
    imagemagick
)

echo "==> packages:"
printf '    %s\n' "${packages[@]}"

missing=()
for pkg in "${packages[@]}"; do
    pacman -Qq "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
done

if [ ${#missing[@]} -eq 0 ]; then
    echo "==> everything is already installed"
else
    echo "==> missing: ${missing[*]}"
    if ! sudo -n true 2>/dev/null; then
        echo
        echo "No passwordless sudo. Run this manually:"
        echo "    sudo pacman -S --needed ${missing[*]}"
        exit 1
    fi
    sudo pacman -S --needed --noconfirm "${missing[@]}"
fi

echo
echo "==> tool versions"
cmake --version | head -1
ninja --version
qmake6 -query QT_VERSION 2>/dev/null | sed 's/^/Qt /' || true
if [ -x /usr/lib/jvm/java-8-openjdk/bin/java ]; then
    /usr/lib/jvm/java-8-openjdk/bin/java -version 2>&1 | head -1
else
    echo "warning: /usr/lib/jvm/java-8-openjdk not found — build.sh will not find a JDK 8" >&2
fi

echo
echo "done. Next: ./scripts/build.sh"
