#!/usr/bin/env bash
#
# Build Korin Launcher natively on the machine you run this on.
#
# Supports Linux, macOS and Windows (MSYS2/MinGW). There is no cross-compiling:
# every system builds with its own toolchain, the same way the Prism Launcher
# CI matrix does it (linux / macos / windows_mingw / windows_msvc).
#
# Usage:
#   ./scripts/build.sh                    # Release build into ./build
#   ./scripts/build.sh --debug            # Debug build
#   ./scripts/build.sh -j 4               # limit parallelism
#   ./scripts/build.sh --clean            # wipe ./build first
#   ./scripts/build.sh --lto              # enable link time optimization
#   ./scripts/build.sh --tests            # build unit tests
#   ./scripts/build.sh --install [PREFIX] # cmake --install (default ./install)
#   ./scripts/build.sh --package          # portable archive in ./dist
#   ./scripts/build.sh --preset linux     # use a CMakePresets.json preset
#
# The version comes from ./VERSION (1 to 4 numeric parts).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIG="Release"
JOBS="$(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc 2>/dev/null || echo 2)"
CLEAN=0
LTO="OFF"
TESTS="OFF"
INSTALL=0
PREFIX="$ROOT/install"
PACKAGE=0
PRESET=""
BUILD_DIR="$ROOT/build"

usage() {
    awk 'NR>2 && /^#/ { sub(/^# ?/, ""); print; next } NR>2 { exit }' "$0"
    exit 0
}

while [ $# -gt 0 ]; do
    case "$1" in
        --debug)   CONFIG="Debug"; shift ;;
        --release) CONFIG="Release"; shift ;;
        --relwithdebinfo) CONFIG="RelWithDebInfo"; shift ;;
        -j|--jobs) JOBS="${2:?--jobs needs a number}"; shift 2 ;;
        -j*)       JOBS="${1#-j}"; shift ;;
        --clean)   CLEAN=1; shift ;;
        --lto)     LTO="ON"; shift ;;
        --tests)   TESTS="ON"; shift ;;
        --install)
            INSTALL=1; shift
            if [ $# -gt 0 ] && [ "${1#-}" = "$1" ]; then PREFIX="$1"; shift; fi
            ;;
        --package) PACKAGE=1; shift ;;
        --preset)  PRESET="${2:?--preset needs a name}"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "error: unknown argument '$1'" >&2; usage ;;
    esac
done

# ---------------------------------------------------------------------------
# version / platform
# ---------------------------------------------------------------------------
if [ ! -f VERSION ]; then
    echo "error: VERSION file not found in $ROOT" >&2
    exit 1
fi
VERSION="$(head -n1 VERSION | tr -d '[:space:]')"
case "$VERSION" in
    ''|*[!0-9.]*) echo "error: VERSION must be like 0.1 or 2.445.65.1 (got '$VERSION')" >&2; exit 1 ;;
esac

ARCH="$(uname -m)"
case "$(uname -s)" in
    Linux)          PLATFORM="Linux";  PRESET_DEFAULT="linux" ;;
    Darwin)         PLATFORM="macOS";  PRESET_DEFAULT="macos" ;;
    MINGW*|MSYS*|CYGWIN*) PLATFORM="Windows"; PRESET_DEFAULT="windows_mingw" ;;
    *) echo "error: unsupported system '$(uname -s)'" >&2; exit 1 ;;
esac

export BUILD_PLATFORM="${PLATFORM}-${ARCH}"
export ARTIFACT_NAME="KorinLauncher-${VERSION}-${BUILD_PLATFORM}"
echo "==> Korin Launcher $VERSION ($BUILD_PLATFORM, $CONFIG, -j$JOBS)"

# ---------------------------------------------------------------------------
# JDK 8: NewLaunch.jar is compiled with -source 7 / -target 7,
# which JDK >= 20 refuses. Everything else is happy with a modern JDK.
# ---------------------------------------------------------------------------
java_major() {
    local v
    v="$("$1" -XshowSettings:properties -version 2>&1 | awk -F'= ' '/java.version =/ {print $2; exit}')"
    case "$v" in
        1.8*) echo 8 ;;
        *) echo "${v%%.*}" ;;
    esac
}

find_jdk8() {
    if command -v java >/dev/null 2>&1 && [ "$(java_major java)" = "8" ]; then
        return 0
    fi
    local candidates=(
        /usr/lib/jvm/java-8-openjdk
        /usr/lib/jvm/java-1.8.0-openjdk
        /usr/lib/jvm/jdk8
        /usr/lib/jvm/zulu8*
        /opt/java/jdk8
    )
    local c
    for c in "${candidates[@]}"; do
        if [ -x "$c/bin/javac" ]; then
            export JAVA_HOME="$c"
            export PATH="$c/bin:$PATH"
            echo "==> using JDK 8: $c"
            return 0
        fi
    done
    if command -v /usr/libexec/java_home >/dev/null 2>&1; then
        c="$(/usr/libexec/java_home -v 1.8 2>/dev/null || true)"
        if [ -n "$c" ] && [ -x "$c/bin/javac" ]; then
            export JAVA_HOME="$c"
            export PATH="$c/bin:$PATH"
            echo "==> using JDK 8: $c"
            return 0
        fi
    fi
    echo "warning: no JDK 8 found; NewLaunch.jar may fail to compile (see scripts/deps-arch.sh)" >&2
}

find_jdk8

# ---------------------------------------------------------------------------
# configure
# ---------------------------------------------------------------------------
if [ "$CLEAN" = "1" ]; then
    echo "==> removing $BUILD_DIR"
    rm -rf "$BUILD_DIR"
fi

if [ -n "$PRESET" ]; then
    echo "==> cmake --preset $PRESET"
    cmake --preset "$PRESET"
else
    GENERATOR="Ninja"
    command -v ninja >/dev/null 2>&1 || GENERATOR="Unix Makefiles"

    # Reusing a build directory configured with another generator/type fails loudly;
    # tell the user instead of silently doing something else.
    if [ -f "$BUILD_DIR/CMakeCache.txt" ]; then
        CACHED_GEN="$(sed -n 's/^CMAKE_GENERATOR:INTERNAL=//p' "$BUILD_DIR/CMakeCache.txt")"
        if [ -n "$CACHED_GEN" ] && [ "$CACHED_GEN" != "$GENERATOR" ]; then
            echo "error: $BUILD_DIR was configured with '$CACHED_GEN', not '$GENERATOR'." >&2
            echo "       run with --clean, or delete $BUILD_DIR yourself." >&2
            exit 1
        fi
    fi

    echo "==> cmake configure ($GENERATOR)"
    cmake -S "$ROOT" -B "$BUILD_DIR" -G "$GENERATOR" \
        -DCMAKE_BUILD_TYPE="$CONFIG" \
        -DENABLE_LTO="$LTO" \
        -DBUILD_TESTING="$TESTS" \
        -DLauncher_BUILD_PLATFORM="$BUILD_PLATFORM" \
        -DLauncher_BUILD_ARTIFACT="$ARTIFACT_NAME"
fi

if [ -n "$PRESET" ]; then
    BUILD_ARGS=(--build "$BUILD_DIR" --config "$CONFIG" --parallel "$JOBS")
else
    BUILD_ARGS=(--build "$BUILD_DIR" --parallel "$JOBS")
fi

echo "==> building"
cmake "${BUILD_ARGS[@]}"

# ---------------------------------------------------------------------------
# install / package
# ---------------------------------------------------------------------------
if [ "$INSTALL" = "1" ] && [ "$PACKAGE" = "0" ]; then
    echo "==> installing to $PREFIX"
    cmake --install "$BUILD_DIR" --prefix "$PREFIX" ${PRESET:+--config "$CONFIG"}
fi

if [ "$PACKAGE" = "1" ]; then
    DIST="$ROOT/dist/$ARTIFACT_NAME"
    rm -rf "$DIST"
    mkdir -p "$DIST"
    echo "==> staging into $DIST"
    cmake --install "$BUILD_DIR" --prefix "$DIST" ${PRESET:+--config "$CONFIG"}

    mkdir -p "$ROOT/dist"
    if [ "$PLATFORM" = "Windows" ]; then
        ARCHIVE="$ROOT/dist/$ARTIFACT_NAME.zip"
        rm -f "$ARCHIVE"
        (cd "$ROOT/dist" && cmake -E tar cf "$ARCHIVE" --format=zip "$ARTIFACT_NAME")
    else
        ARCHIVE="$ROOT/dist/$ARTIFACT_NAME.tar.gz"
        rm -f "$ARCHIVE"
        (cd "$ROOT/dist" && tar czf "$(basename "$ARCHIVE")" "$ARTIFACT_NAME")
    fi
    echo "==> archive: $ARCHIVE"
    echo "    note: it contains the launcher only; Qt/KDSoap runtime libs are not bundled."
    echo "          Use the CI release workflow for AppImage/Windows/macOS bundles."
fi

echo "==> done"
if [ "$PACKAGE" = "0" ]; then
    BIN="$BUILD_DIR/korinlauncher"
    [ -x "$BUILD_DIR/launcher/korinlauncher" ] && BIN="$BUILD_DIR/launcher/korinlauncher"
    echo "    binary: $BIN"
    echo "    run:    $BIN --version"
fi
