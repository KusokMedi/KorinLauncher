# AGENTS.md — KorinLauncher

Форк [Prism Launcher](https://github.com/PrismLauncher/PrismLauncher) с offline-аккаунтами
(без авторизации Microsoft). Базовый апстрим для импорта правок и фич —
[Diegiwg/PrismLauncher-Cracked](https://github.com/Diegiwg/PrismLauncher-Cracked)
(remote `upstream`). Репозиторий: `github.com/KusokMedi/KorinLauncher` (`origin`).

## Что это за проект

Нативное приложение на C++20/Qt6 Widgets (CMake + Ninja). Java-часть — только
`libraries/launcher` (`NewLaunch.jar`, целевая версия Java 7/8) и скачиваемые
рантаймы Minecraft. Никакого Electron/веба в UI.

```
launcher/        основной код: Application, UI, minecraft/, java/, modplatform/
libraries/       libnbtplusplus (submodule), Java-launcher, LocalPeer, rainbow, qdcss
program_info/    брендинг: имя, AppID, иконки, .desktop, metainfo, man-страница
buildconfig/     сгенерированный BuildConfig (LAUNCHER_DISPLAYNAME и пр.)
assets/logo/     исходники логотипа + генератор всех растровых иконок
scripts/         deps-arch.sh (зависимости), build.sh (сборка и упаковка)
tests/           gtest-тесты (BUILD_TESTING=OFF в обычной сборке)
```

## Платформа разработки

Основная среда — **Arch Linux** (Omarchy на Hyprland). Зависимости для сборки
ставятся `scripts/deps-arch.sh` (pacman; список пакетов — в самом скрипте).
На других дистрибутивах скрипт не работает, но пакеты нужны те же: Qt 6.4+
(base/tools/svg/networkauth/5compat), extra-cmake-modules, cmake, ninja,
libarchive, zlib, tomlplusplus, cmark, qrencode, gamemode, scdoc, JDK 8.

Кросс-компиляции нет: Linux, macOS и Windows (MSYS2/MSVC) собираются нативно
тем же `scripts/build.sh` — так же, как это делает CI-матрица апстрима
(`.github/workflows/build.yml`). Собрать из Linux сборку под Windows нельзя.

## Версия

Единственный источник версии — файл `VERSION` в корне: от 1 до 4 числовых
частей (`0.1`, `2.445.65`, `2.445.65.1`), без `v` и суффиксов вроде `-beta`.
CMake читает его при конфигурации: в UI и `--version` попадает строка ровно как
записана, а для числовых полей Windows/macOS недостающие части считаются нулями.
Переопределить без правки файла можно переменной `KORINLAUNCHER_VERSION`
(для CI/упаковки). После изменения `VERSION` нужна переконфигурация сборки.

## Сборка

```bash
./scripts/deps-arch.sh         # один раз: зависимости через pacman
./scripts/build.sh             # Release в ./build, параллельно по числу ядер
./scripts/build.sh --debug     # Debug
./scripts/build.sh --clean     # снести ./build и собрать заново
./scripts/build.sh -j 4        # ограничить параллелизм
./scripts/build.sh --lto       # включить LTO (долго; в CI включён)
./scripts/build.sh --tests     # собрать тесты
./scripts/build.sh --install   # установить в ./install
./scripts/build.sh --package   # дерево установки + архив в ./dist
```

Скрипт сам находит JDK 8 (`/usr/lib/jvm/java-8-openjdk` и родственные пути) и
подставляет `JAVA_HOME`: JDK ≥ 20 отказывается компилировать `NewLaunch.jar` с
`-source 7`. `--install`/`--package` только раскладывают файлы локально и ничего
не публикуют; в архиве из `--package` нет Qt-библиотек — это не AppImage.

Ручная сборка, если скрипт не подходит:

```bash
JAVA_HOME=/usr/lib/jvm/java-8-openjdk cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DENABLE_LTO=OFF -DBUILD_TESTING=OFF \
  -DLauncher_BUILD_PLATFORM=Linux-x86_64
JAVA_HOME=/usr/lib/jvm/java-8-openjdk ninja -C build -j4
```

После правок `CMakeLists.txt` или `program_info/CMakeLists.txt` переменные
`Launcher_*` закешированы — перезапускать конфигурацию с `-U 'Launcher_*'`,
иначе новые значения не подхватятся.

Первая полная сборка на этом ноуте (i5-5300U, 4 потока) ≈ 20–25 минут;
инкрементальная — секунды/минуты. Долгие сборки запускать в фоне.

Проверка без GUI:

```bash
./build/korinlauncher --version          # "KorinLauncher <ver>-<branch>"
QT_QPA_PLATFORM=offscreen ./build/korinlauncher --version
```

GUI-проверка — через временный data-dir, чтобы не трогать реальный конфиг:

```bash
./build/korinlauncher -d /tmp/opencode/korin-data
hyprctl clients -j | python3 -c '...'   # class = com.kusokmedi.korinlauncher
```

## Брендинг

Единственный источник правды — `program_info/CMakeLists.txt`:
`Launcher_CommonName` (KorinLauncher, он же StartupWMClass),
`Launcher_DisplayName` (Korin Launcher), `Launcher_AppID`
(com.kusokmedi.korinlauncher), `Launcher_EnvName`, copyright, имена файлов
иконок. Имена файлов брендинга привязаны к AppID и `Launcher_APP_BINARY_NAME`
(`korinlauncher`) — при переименовании обновлять и файлы, и `launcher/main.cpp`
(`Q_INIT_RESOURCE(korinlauncher)`, имя должно совпадать с `korinlauncher.qrc`).

Палитра бренда: чёрный, серый, белый (без цветных акцентов).

### Иконки

Исходники и генератор — `assets/logo/`:

- `icon.svg` — основная иконка (тёмная плашка), `icon-light.svg` — для светлых тем;
- `./gen-icons.sh` — рендерит PNG 16…1024, `icon.ico`, `icon.icns`
  (нужны `rsvg-convert` и ImageMagick; ICNS собирает `build-icns.py`, macOS-тулчейн не нужен);
- `./gen-icons.sh --install` — копирует результат в `program_info/` под именами,
  которые ждёт CMake. После этого пересобрать (`ninja -C build`) — SVG попадает
  в бинарник через qrc.

Не редактировать `program_info/*.svg|*.ico|*.icns|*_256.png` вручную: они
генерируются из `assets/logo/`.

## Ветки и апстрим

- `main` — наш код: baseline-коммит апстрима + наши правки. С апстримом не
  связана трекингом (без случайных `git pull`).
- `upstream` — remote `Diegiwg/PrismLauncher-Cracked` (ветка `main`, теги 9.4…11.1.1).
  Оттуда берём фиксы: `git fetch upstream && git cherry-pick <sha>`.
- Импорт обновлений целиком — только осознанно, через squash-merge или
  `git diff upstream/main..HEAD` для контроля своих изменений.
- `master` — исходный пустой коммит репозитория, не трогать.

## Соглашения

- Коммиты: Conventional Commits, по-английски, императив; один коммит — одна
  логическая правка.
- Стиль C++ — `.clang-format` в корне, `clang-tidy` по конфигу; сборка идёт с
  `-Werror`, предупреждения не игнорировать.
- Тексты для пользователя — через `tr()`, не хардкодить английский в UI.
- Внутренние имена `org.prismlauncher.*` (Java-пакет, `prismupdater`) — это код,
  а не брендинг; переименовывать только отдельной осознанной задачей.
- Форк GPL-3.0: копирайты Prism/PolyMC/MultiMC сохранять.
