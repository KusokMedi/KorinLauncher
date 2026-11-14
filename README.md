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

```bash
JAVA_HOME=/usr/lib/jvm/java-8-openjdk cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_LTO=OFF \
  -DLauncher_BUILD_PLATFORM=Linux
JAVA_HOME=/usr/lib/jvm/java-8-openjdk ninja -C build
```

The launcher jar is compiled against Java 7/8, so configure with a JDK 8
(`JAVA_HOME=/usr/lib/jvm/java-8-openjdk`) if your default JDK is newer.

## Credits

Based on Prism Launcher (© Prism Launcher Contributors), PolyMC
(© PolyMC Contributors) and MultiMC (© MultiMC Contributors). Licensed under
GPL-3.0; see [COPYING.md](COPYING.md).
