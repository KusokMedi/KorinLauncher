<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="/assets/logo/logo.png">
  <source media="(prefers-color-scheme: light)" srcset="/assets/logo/logo-light.png">
  <img alt="Korin Launcher" src="/assets/logo/logo-light.png" width="560">
</picture>
</p>

Korin Launcher — a custom Minecraft launcher based on
[Prism Launcher](https://github.com/PrismLauncher/PrismLauncher), with offline
accounts (no Microsoft authentication).

## Build

Development targets **Arch Linux**; the same script also works on macOS and
Windows (MSYS2) natively.

```bash
./scripts/deps-arch.sh    # one-time: build dependencies (pacman)
./scripts/build.sh        # Release build into ./build
./scripts/build.sh --debug
./scripts/build.sh --package   # install tree + archive in ./dist
./scripts/build.sh --help
```

`build.sh` finds a JDK 8 automatically: the bundled launcher jar is compiled
with `-source 7`, which JDK ≥ 20 rejects.

The version lives in [`VERSION`](VERSION) and may have up to four numeric parts
(`0.1`, `2.445.65.1`). No cross-compiling — Windows/macOS builds run on their own
system (see the CI workflows).

## Credits

Based on Prism Launcher (© Prism Launcher Contributors), PolyMC
(© PolyMC Contributors) and MultiMC (© MultiMC Contributors). Licensed under
GPL-3.0; see [COPYING.md](COPYING.md).
