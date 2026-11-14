<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="/program_info/com.kusokmedi.korinlauncher.logo-darkmode.svg">
  <source media="(prefers-color-scheme: light)" srcset="/program_info/com.kusokmedi.korinlauncher.svg">
  <img alt="Korin Launcher" src="/program_info/com.kusokmedi.korinlauncher.svg" width="40%">
</picture>
</p>

Korin Launcher — a custom Minecraft launcher based on
[Prism Launcher](https://github.com/PrismLauncher/PrismLauncher), with offline
accounts (no Microsoft authentication).

## Build

```bash
cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_LTO=OFF \
  -DLauncher_BUILD_PLATFORM=Linux
ninja -C build
```

The launcher jar is compiled against Java 7/8, so configure with a JDK 8
(`JAVA_HOME=/usr/lib/jvm/java-8-openjdk`) if your default JDK is newer.

## Credits

Based on Prism Launcher (© Prism Launcher Contributors), PolyMC
(© PolyMC Contributors) and MultiMC (© MultiMC Contributors). Licensed under
GPL-3.0; see [COPYING.md](COPYING.md).
